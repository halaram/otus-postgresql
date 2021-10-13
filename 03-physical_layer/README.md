Домашнее задание
Установка и настройка PostgreSQL

Цель:
создавать дополнительный диск для уже существующей виртуальной машины, размечать его и делать на нем файловую систему
переносить содержимое базы данных PostgreSQL на дополнительный диск
переносить содержимое БД PostgreSQL между виртуальными машинами

создайте виртуальную машину
поставьте на нее PostgreSQL
```console
[root@otus02 ~]# yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@otus02 ~]# yum install -y postgresql14-server
[root@otus02 ~]# /usr/pgsql-14/bin/postgresql-14-setup initdb
[root@otus02 ~]# systemctl enable --now postgresql-14
```
проверьте что кластер запущен
```console
systemctl status postgresql-14
● postgresql-14.service - PostgreSQL 14 database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql-14.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-10-13 16:10:47 UTC; 10min ago
```
зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым postgres=# create table test(c1 text); postgres=# insert into test values('1'); \q
```console
postgres=# create database task03;
CREATE DATABASE
postgres=# \c task03 
You are now connected to database "task03" as user "postgres".
task03=# create table test(c1 text);
CREATE TABLE
task03=# insert into test values('1');
INSERT 0 1
```
остановите postgres
```console
[root@otus02 ~]# systemctl stop postgresql-14
```
создайте новый standard persistent диск GKE через Compute Engine -> Disks в том же регионе и зоне что GCE инстанс размером например 10GB
```console
gcloud beta compute disks create disk-1 --project=dynamic-cove-328316 --type=pd-ssd --size=10GB --zone=us-central1-a
```
добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk
```console
[root@otus02 ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   20G  0 disk 
├─sda1   8:1    0  200M  0 part /boot/efi
└─sda2   8:2    0 19.8G  0 part /
sdb      8:16   0   10G  0 disk
```
проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux
```console
[root@otus02 ~]# parted /dev/sdb mklabel gpt
[root@otus02 ~]# parted -a opt /dev/sdb mkpart primary ext4 0% 100%
[root@otus02 ~]# mkfs.ext4 -L pgdata1 /dev/sdb1
[root@otus02 ~]# mkdir /mnt/data
[root@otus02 ~]# echo "LABEL=pgdata1 /mnt/data ext4 defaults 0 2" >> /etc/fstab
[root@otus02 ~]# mount -av
...
/mnt/data                : successfully mounted
```
сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/
```console
[root@otus02 ~]# chown -R postgres:postgres /mnt/data/
```
перенесите содержимое /var/lib/postgres/13 в /mnt/data - mv /var/lib/postgresql/13 /mnt/data
```console
-bash-4.2$ mv /var/lib/pgsql/14 /mnt/data
```
попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 13 main start
```console
[root@otus02 pgsql]# systemctl start postgresql-14
Job for postgresql-14.service failed because the control process exited with error code. See "systemctl status postgresql-14.service" and "journalctl -xe" for details.
```
напишите получилось или нет и почему   
<b>В логах видно, что путь, куда указывает переменная в systemd юните postgresql-14 PGDATA=/var/lib/pgsql/14/data/ не существует</b>   
<pre><code>
Oct 13 16:57:51 otus02 postgresql-14-check-db-dir: "/var/lib/pgsql/14/data/" is missing or empty.   
Oct 13 16:57:51 otus02 postgresql-14-check-db-dir: Use "/usr/pgsql-14/bin/postgresql-14-setup initdb" to initialize the database cluster.   
</code></pre>

задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/10/main который надо поменять и поменяйте его
напишите что и почему поменяли   
<b>В rhel-centos рекомендованным методом изменения PGDATA=/mnt/data/14/data/ является override systemd юнита:</b>
```console
[root@otus02 pgsql]# systemctl edit postgresql-14
[root@otus02 pgsql]# cat /etc/systemd/system/postgresql-14.service.d/override.conf 
[Service]
Environment=PGDATA=/mnt/data/14/data/
```
попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 13 main start
```console
[root@otus02 pgsql]# systemctl start postgresql-14
[root@otus02 pgsql]# systemctl status postgresql-14
● postgresql-14.service - PostgreSQL 14 database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql-14.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/postgresql-14.service.d
           └─override.conf
   Active: active (running) since Wed 2021-10-13 17:10:34 UTC; 4s ago
```
напишите получилось или нет и почему   
<b>Postgres нормально запустился с переменной PGDATA=/mnt/data/14/data/</b>   

зайдите через через psql и проверьте содержимое ранее созданной таблицы
```console
postgres=# \c task03
You are now connected to database "task03" as user "postgres".
task03=# select * from test;
 c1 
----
 1
(1 row)
```
задание со звездочкой *: не удаляя существующий GCE инстанс сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, 
перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске,
 расскажите как вы это сделали и что в итоге получилось.

Останавливаем otus02 и создаём новую ВМ otus03
```console
gcloud compute instances stop otus02
gcloud compute instances create otus03 --zone=us-central1-a ...
```
Устанавливаем на otus03 postgresql:
```console
[root@otus03 ~]# yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
[root@otus03 ~]# yum install -y postgresql14-server
```
Существующий диск disk-1 удаляем с otus02 и передаём otus03.
```console
[root@otus03 ~]# lsblk --fs
NAME   FSTYPE LABEL   UUID                                 MOUNTPOINT
sda                                                        
├─sda1 vfat           1658-40B2                            /boot/efi
└─sda2 xfs    root    9bb1ae44-a177-4e75-bf1d-18cbefbdb216 /
sdb                                                        
└─sdb1 ext4   pgdata1 3b7c0f2f-6625-467c-a06d-174ff874560e
```
Монтируем диск sdb1 по пути /var/lib/pgsql
```console
[root@otus03 ~]# echo "LABEL=pgdata1 /var/lib/pgsql ext4 defaults 0 2" >> /etc/fstab
[root@otus03 ~]# mount -av
...
/var/lib/pgsql           : successfully mounted
```
Создаём минимальный .bash_profile пользователя postgres:
```console
-bash-4.2$ echo "export PGDATA=/var/lib/pgsql/14/data" >> /var/lib/pgsql/.bash_profile
-bash-4.2$ chmod +x .bash_profile 
-bash-4.2$ source .bash_profile 
```
Включаем и запускаем postgres:
```console
[root@otus03 lib]# systemctl enable --now postgresql-14
[root@otus03 lib]# systemctl status postgresql-14
● postgresql-14.service - PostgreSQL 14 database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql-14.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-10-13 18:01:13 UTC; 3min 8s ago
```
Проверяем данные в таблице test:
```console
postgres=# \c task03 
You are now connected to database "task03" as user "postgres".
task03=# select * from test;
 c1 
----
 1
(1 row)

```
