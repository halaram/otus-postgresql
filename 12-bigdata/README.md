### Работа с большим объемом реальных данных

Цель:
знать различные механизмы загрузки данных  
уметь пользоваться различными механизмами загрузки данных  
Необходимо провести сравнение скорости работы запросов на различных СУБД

<b>Имя проекта - postgres2021-2147483647</b>

Создана ВМ otus12 с SSD диском 50GB.

>Выбрать одну из СУБД  

Для сравнения была установлена БД Oracle Database 21c Express Edition.  
Созданы пользователь taxi с необходимыми правами и таблица TAXI_TRIPS для загрузки данных.  

>Загрузить в неё данные (10 Гб)  

- С помощью gcsfuse примонтирован bucket с данными сета chicago_taxi_trips и загружены данные инструментом sqlldr:  
```console
[oracle@otus12 taxi_2021_11_18]$ for i in {00..39}; do sqlldr taxi/12345678@//127.0.0.1:1521/xepdb1 data=/mnt/taxi_2021_11_18/taxi_0000000000$i.csv control=/home/oracle/sqlldr_taxi.ctl log=/home/oracle/sqlldr_taxi_0000000000$i.log bad=/home/oracle/taxi_0000000000$i_bad.csv; done
```

```sql
SQL> show parameter sga;

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
allow_group_access_to_sga	     boolean	 FALSE
lock_sga			     boolean	 FALSE
pre_page_sga			     boolean	 TRUE
sga_max_size			     big integer 1136M
sga_min_size			     big integer 0
sga_target			     big integer 1136M
SQL> show parameter pga;

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
pga_aggregate_limit		     big integer 2G
pga_aggregate_target		     big integer 378M
```
- Размер таблицы taxi_trips > 10GB, количество строк около 26 миллионов:

```sql
SQL> set timing on;

SQL> select BYTES/1024/1024/1024 from user_segments where SEGMENT_NAME = 'TAXI_TRIPS';

BYTES/1024/1024/1024
--------------------
         10.0625

Elapsed: 00:00:00.11

SQL> select count(*) from taxi_trips;

  COUNT(*)
----------
  26023348

Elapsed: 00:06:25.27
```
- Выполним sql-запросы с операциями группировки и сортировки для оценки времени:
```sql
SQL> select payment_type, round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, count(*) as c from taxi_trips group by payment_type order by 3;

PAYMENT_TYPE	     TIPS_PERCENT	   C
-------------------- ------------ ----------
Prepaid 			0	  76
Way2ride		       15	  78
Pcard				3	5302
Dispute 			0      14685
Mobile			       15      32883
Prcard				1      41463
Unknown 			2      68591
No Charge			3     131855
Credit Card		       17   10714146
Cash				0   15014269

10 rows selected.

Elapsed: 00:06:27.42

SQL> select company, count(*) as c, sum(trip_seconds) as s_sec, sum(trip_miles) as s_mil from taxi_trips group by company order by 2;

COMPANY 						    C	   S_SEC      S_MIL
-------------------------------------------------- ---------- ---------- ----------
2809 - 95474 C&D Cab Co Inc.				    1	     540	1.5
3669 - Jordan Taxi Inc					    3	       0	  0
0118 - Godfray S.Awir					    5	    2760       10.8
American United Cab Association 			    5	       0	  0
4523 - 79481 Hazel Transit Inc				    6	    8100       31.2
Metro Jet Taxi Ass					    9	   14964      105.4
3201 - C & D Cab Co Inc 				   22	   12780       53.5
4732 - Maude Lamy					   29	    8040       61.7
3385 -	Eman Cab					   51	   38340      202.7
2241 - 44667 - Felman Corp, Manuel Alonso		   54	   86400      643.8
1408 - Donald Barnes					   67	   81840	395
2823 - Seung Lee					   69	   96360      493.7
5062 - Sam Mestas					   80	   47340      179.8
3201 - CID Cab Co Inc					   92	   63900      317.1
3094 - G.L.B. Cab Co					  141	   96780      385.3
2092 - Sbeih company					  142	  110400      549.7
3253 - Gaither Cab Co.					  150	  122160      573.4
585 - Valley Cab Co					  182	  140760      663.3
3152 - Crystal Abernathy				  193	  118200      851.2
3721 - Santamaria Express, Alvaro Santamaria		  197	  169860      956.9
3319 - C&D Cab Company					  198	  134580      626.3
3385 - Eman Cab 					  200	  188100     1040.8
0694 - Chinesco Trans Inc				  201	  178620      901.4
2241 - Manuel Alonso					  212	  344580     1697.4
3591- Chuk's Cab					  224	  166620      608.9
4197 - Royal Star					  226	  210660     1135.7
4623 - Jay Kim						  235	  219420     1166.2
5006 - Salifu Bawa					  236	  173280      603.1
3385 - 23210 Eman Cab					  239	  197280     1239.1
2767 - Sayed M Badri					  246	  108540       67.4
1247 - Daniel Ayertey					  252	  226440     1092.8
3669 - 85800 Jordan Taxi Inc				  259	  418380     1523.3
5997 - AW Services Inc. 				  260	  207000     1080.8
3011 - JBL Cab Inc.					  265	  153900      688.9
5864 - Thomas Owusu					  275	  208920       1046
Patriot Trans Inc					  312	  245340     1273.8
Chicago Star Taxicab					  313	  324360     1750.7
3623-Arrington Enterprises				  316	  227100       1416
3385 - 23210  Eman Cab					  331	  352800     2144.4
5437 - Great American Cab Co				  344	  270720     1144.6
3591 - 63480 Chuk's Cab 				  396	  253320      825.2
5074 - Ahzmi Inc					  417	  341760     1509.4
6488 - Zuha Taxi					  424	  337920       1621
5724 - 72965 KYVI Cab Inc				  426	  310560     1292.1
1408 - 89599 Donald Barnes				  426	  527100     3258.7
0118 - Godfrey S.Awir					  428	  339120     1665.4
5864 - 73614 Thomas Owusu				  472	  369360     1636.8
5724 - KYVI Cab Inc					  493	  339240     1402.8
4053 - Adwar H. Nikola					  496	  456120     2216.5
3620 - David K. Cab Corp.				  500	  540060     3058.3
2823 - 73307 Lee Express Inc				  511	  782700       4254
4615 - Tyrone Henderson 				  543	  382260     1701.3
3591- 63480 Chuk's Cab					  556	  382620     1365.8
5129 - Mengisti Taxi					  561	  447300     1759.1
5874 - Sergey Cab Corp. 				  570	  459660     3383.3
3897 - 57856 Ilie Malec 				  647	  624480     3334.8
5776 - Mekonen Cab Company				  663	  507900     2503.2
3897 - Ilie Malec					  707	  699120     4253.5
2733 - Benny Jona					  717	  653580     2354.4
4787 - Reny Cab Co					  727	  452460       1471
2192 - Zeymane Corp					  819	  555000     1547.5
4787 - 56058 Reny Cab Co				  923	  618780     2394.3
Petani Cab Corp 					  965	 1393500     9534.8
2241 - 44667 Manuel Alonso				  991	 1828380    11095.3
1085 - N and W Cab Co					 1067	  644820     2516.5
5129 - 98755 Mengisti Taxi				 1082	  926280     4319.2
Checker Taxi						 1103	  690258     3328.2
3319 - CD Cab Co					 1152	  918840     4578.8
5062 - 34841 Sam Mestas 				 1236	  729300     3136.8
3556 - 36214 RC Andrews Cab				 1248	 1220520     6394.7
2823 - 73307 Seung Lee					 1255	 1735320    10419.6
3201 - CD Cab Co Inc					 1363	 1024080     3988.2
3141 - Zip Cab						 1460	 1020660     5381.3
6743 - Luhak Corp					 1530	 1198740     5133.1
6057 - 24657 Richard Addo				 1687	 1524300     6578.7
3620 - 52292 David K. Cab Corp. 			 1700	 1967880    10466.2
3591 - 63480 Chuks Cab					 1701	 1105560     3480.8
5997 - 65283 AW Services Inc.				 1738	 1739280     9952.9
4053 - 40193 Adwar H. Nikola				 1755	 2113080    14214.3
C & D Cab Co Inc					 1849	 1358280     6893.6
6488 - 83287 Zuha Taxi					 2011	 1437780     6560.6
American United Taxi Affiliation			 2094	 2151903   10972.96
2809 - 95474 C & D Cab Co Inc.				 2148	 1656900     9147.2
312 Medallion Management Corp				 2196	 2321820    13727.7
3253 - 91138 Gaither Cab Co.				 2269	 1558740     7250.2
4615 - 83503 Tyrone Henderson				 2384	 1760520     7678.1
6747 - Mueen Abdalla					 2509	 2149800     9674.4
Park Ridge Taxi and Livery				 2581	  566940	  0
2192 - 73487 Zeymane Corp				 2631	 1961160     9592.7
5874 - 73628 Sergey Cab Corp.				 2755	 2411820      16915
585 - 88805 Valley Cab Co				 2770	 2030520    10300.6
6742 - 83735 Tasha ride inc				 2810	 2583600    11512.8
3623 - 72222 Arrington Enterprises			 2839	 2406660    15653.9
5074 - 54002 Ahzmi Inc					 2875	 2858700    15130.3
Peace Taxi Assoc					 2917	 2229540     9840.5
1247 - 72807 Daniel Ayertey				 2932	 2604120    12740.7
4623 - 27290 Jay Kim					 2945	 2873580    16988.9
5 Star Taxi						 2962	 4224124   23766.02
U Taxicab						 3189	 3147840    18869.7
2733 - 74600 Benny Jona 				 3190	 3199980    16507.3
0694 - 59280 Chinesco Trans Inc 			 3191	 2634720    10150.5
5724 - 75306 KYVI Cab Inc				 3201	 2357580     9717.6
Norshore Cab						 3358	 2244134    11155.1
5006 - 39261 Salifu Bawa				 3422	 2564460     9278.2
4197 - 41842 Royal Star 				 3460	 2983020    15671.1
3141 - 87803 Zip Cab					 3480	 2184780     9600.4
3094 - 24059 G.L.B. Cab Co				 3513	 2378640     7903.3
3152 - 97284 Crystal Abernathy				 3585	 2483040    13336.8
5129 - 87128						 3746	 2819700    13679.4
6574 - Babylon Express Inc.				 3747	 3010080    12836.9
2092 - 61288 Sbeih company				 4233	 3772260    19756.4
0118 - 42111 Godfrey S.Awir				 4249	 3684780    18691.8
1085 - 72312 N and W Cab Co				 4568	 2698680      10171
3011 - 66308 JBL Cab Inc.				 5111	 3530640    16496.6
3201 - C&D Cab Co Inc					 5328	 3820080      16807
6743 - 78771 Luhak Corp 				 5695	 4672380    19627.4
Leonard Cab Co						 5719	 4554753    18877.7
American United 					 5719	 4482535    21227.6
Yellow Cab						 7300	 5404272      25748
Metro Group						10353	 5288097    30081.6
Metro Jet Taxi A					11307	10376321    49558.6
Setare Inc						12881	10743697    45216.8
Service Taxi Association				13823	12352560    57941.1
Gold Coast Taxi 					20061	18692535   83192.49
Blue Diamond						21389	18771862    85956.8
Suburban Dispatch LLC					31159	 1540380	  0
Checker Taxi Affiliation				43654	36871603   161809.2
Chicago Elite Cab Corp. 				51537	36557400	  0
Chicago Taxicab 					54538	49287282   226768.8
Taxicab Insurance Agency, LLC				60024	48030360   216647.4
Chicago Medallion Management				69866	48652500   215141.7
Chicago Independents					69894	66152130  309970.39
24 Seven Taxi						71197	64097827  290896.01
Nova Taxi Affiliation Llc				94787	80246864  338345.19
Star North Management LLC				98501	80250240   368732.2
Patriot Taxi Dba Peace Taxi Associat		       103102	97906849  380582.83
T.A.S. - Payment Only				       115648	13736760	  0
Chicago Medallion Leasing INC			       122236	90159540   402273.9
303 Taxi					       132195  108395564   839550.7
Globe Taxi					       163496  138176147  618141.52
Taxi Affiliation Service Yellow 		       240081  204527388  933593.54
Top Cab Affiliation				       293112  235315140  1201913.5
Medallion Leasin				       304196  269973865 1228628.12
Flash Cab					       309036  320516588 1530518.73
KOAM Taxi Association				       402152  324517920  1625989.5
Sun Taxi					       402595  372494509 1722755.67
City Service					       412574  351289597 1686948.48
Chicago Carriage Cab Corp			       636705  598056976 4004443.67
Chicago Elite Cab Corp. (Chicago Carriag	       675031	94436760	  0
Northwest Management LLC			       732268  542881500  2160686.4
Choice Taxi Association 			      1379440 1125522960  4952431.1
Blue Ribbon Taxi Association Inc.		      1772906 1326451140   265605.1
Dispatch Taxi Affiliation			      2260433 1693494540  7334346.2
						      6772883 5551877584 33967146.4
Taxi Affiliation Services			      7878710 6031986480 17136242.4

155 rows selected.

Elapsed: 00:06:25.12
```
>Сравнить скорость выполнения запросов на PosgreSQL и выбранной СУБД
```sql
postgres=# create user taxi password '12345678';
CREATE ROLE
taxi=# grant pg_read_server_files to taxi;
GRANT ROLE
postgres=# create database taxi owner taxi;
CREATE DATABASE
```

```sql
create table taxi_trips (
unique_key varchar(255),
taxi_id varchar(255),
trip_start_timestamp TIMESTAMP,
trip_end_timestamp TIMESTAMP,
trip_seconds integer,
trip_miles numeric,
pickup_census_tract bigint,
dropoff_census_tract bigint,
pickup_community_area integer,
dropoff_community_area integer,
fare numeric, 
tips numeric,
tolls numeric,
extras numeric,
trip_total numeric,
payment_type varchar(255),
company varchar(255), 
pickup_latitude numeric,
pickup_longitude numeric,
pickup_location varchar(255), 
dropoff_latitude numeric, 
dropoff_longitude numeric, 
dropoff_location varchar(255)
);
```

```console
-bash-4.2$ for i in {00..39}; do psql -U taxi taxi -c "COPY taxi_trips(unique_key, taxi_id, trip_start_timestamp, trip_end_timestamp, trip_seconds, trip_miles, pickup_census_tract, dropoff_census_tract, pickup_community_area, dropoff_community_area, fare, tips, tolls, extras, trip_total, payment_type, company, pickup_latitude, pickup_longitude, pickup_location, dropoff_latitude, dropoff_longitude, dropoff_location) FROM '/mnt/taxi_2021_11_18/taxi_0000000000$i.csv' DELIMITER ',' CSV HEADER;"; done
COPY 653524
COPY 653941
COPY 667159
...
COPY 650051
COPY 670246
COPY 668752
```

```sql
postgres=# \c taxi 
You are now connected to database "taxi" as user "postgres".
taxi=# \dt+ taxi_trips
                                    List of relations
 Schema |    Name    | Type  | Owner | Persistence | Access method | Size  | Description 
--------+------------+-------+-------+-------------+---------------+-------+-------------
 public | taxi_trips | table | taxi  | permanent   | heap          | 10 GB | 

taxi=# \timing on
Timing is on.
taxi=# select count(*) from taxi_trips;
  count   
----------
 26023348
(1 row)

Time: 455565.028 ms (07:35.565)

taxi=# select payment_type, round(sum(tips)/sum(trip_total)*100, 0) + 0 as tips_percent, count(*) as c from taxi_trips group by payment_type order by 3;
 payment_type | tips_percent |    c     
--------------+--------------+----------
 Prepaid      |            0 |       76
 Way2ride     |           15 |       78
 Pcard        |            3 |     5302
 Dispute      |            0 |    14685
 Mobile       |           15 |    32883
 Prcard       |            1 |    41463
 Unknown      |            2 |    68591
 No Charge    |            3 |   131855
 Credit Card  |           17 | 10714146
 Cash         |            0 | 15014269
(10 rows)

Time: 337405.848 ms (05:37.406)

taxi=# select company, count(*) as c, sum(trip_seconds) as s_sec, sum(trip_miles) as s_mil from taxi_trips group by company order by 2;
                   company                    |    c    |   s_sec    |    s_mil    
----------------------------------------------+---------+------------+-------------
 2809 - 95474 C&D Cab Co Inc.                 |       1 |        540 |         1.5
 3669 - Jordan Taxi Inc                       |       3 |          0 |           0
 0118 - Godfray S.Awir                        |       5 |       2760 |        10.8
 American United Cab Association              |       5 |          0 |           0
 4523 - 79481 Hazel Transit Inc               |       6 |       8100 |        31.2
 Metro Jet Taxi Ass                           |       9 |      14964 |       105.4
 3201 - C & D Cab Co Inc                      |      22 |      12780 |        53.5
 4732 - Maude Lamy                            |      29 |       8040 |        61.7
 3385 -  Eman Cab                             |      51 |      38340 |       202.7
 2241 - 44667 - Felman Corp, Manuel Alonso    |      54 |      86400 |       643.8
 1408 - Donald Barnes                         |      67 |      81840 |       395.0
 2823 - Seung Lee                             |      69 |      96360 |       493.7
 5062 - Sam Mestas                            |      80 |      47340 |       179.8
 3201 - CID Cab Co Inc                        |      92 |      63900 |       317.1
 3094 - G.L.B. Cab Co                         |     141 |      96780 |       385.3
 2092 - Sbeih company                         |     142 |     110400 |       549.7
 3253 - Gaither Cab Co.                       |     150 |     122160 |       573.4
 585 - Valley Cab Co                          |     182 |     140760 |       663.3
 3152 - Crystal Abernathy                     |     193 |     118200 |       851.2
 3721 - Santamaria Express, Alvaro Santamaria |     197 |     169860 |       956.9
 3319 - C&D Cab Company                       |     198 |     134580 |       626.3
 3385 - Eman Cab                              |     200 |     188100 |      1040.8
 0694 - Chinesco Trans Inc                    |     201 |     178620 |       901.4
 2241 - Manuel Alonso                         |     212 |     344580 |      1697.4
 3591- Chuk's Cab                             |     224 |     166620 |       608.9
 4197 - Royal Star                            |     226 |     210660 |      1135.7
 4623 - Jay Kim                               |     235 |     219420 |      1166.2
 5006 - Salifu Bawa                           |     236 |     173280 |       603.1
 3385 - 23210 Eman Cab                        |     239 |     197280 |      1239.1
 2767 - Sayed M Badri                         |     246 |     108540 |        67.4
 1247 - Daniel Ayertey                        |     252 |     226440 |      1092.8
 3669 - 85800 Jordan Taxi Inc                 |     259 |     418380 |      1523.3
 5997 - AW Services Inc.                      |     260 |     207000 |      1080.8
 3011 - JBL Cab Inc.                          |     265 |     153900 |       688.9
 5864 - Thomas Owusu                          |     275 |     208920 |      1046.0
 Patriot Trans Inc                            |     312 |     245340 |      1273.8
 Chicago Star Taxicab                         |     313 |     324360 |      1750.7
 3623-Arrington Enterprises                   |     316 |     227100 |      1416.0
 3385 - 23210  Eman Cab                       |     331 |     352800 |      2144.4
 5437 - Great American Cab Co                 |     344 |     270720 |      1144.6
 3591 - 63480 Chuk's Cab                      |     396 |     253320 |       825.2
 5074 - Ahzmi Inc                             |     417 |     341760 |      1509.4
 6488 - Zuha Taxi                             |     424 |     337920 |      1621.0
 1408 - 89599 Donald Barnes                   |     426 |     527100 |      3258.7
 5724 - 72965 KYVI Cab Inc                    |     426 |     310560 |      1292.1
 0118 - Godfrey S.Awir                        |     428 |     339120 |      1665.4
 5864 - 73614 Thomas Owusu                    |     472 |     369360 |      1636.8
 5724 - KYVI Cab Inc                          |     493 |     339240 |      1402.8
 4053 - Adwar H. Nikola                       |     496 |     456120 |      2216.5
 3620 - David K. Cab Corp.                    |     500 |     540060 |      3058.3
 2823 - 73307 Lee Express Inc                 |     511 |     782700 |      4254.0
 4615 - Tyrone Henderson                      |     543 |     382260 |      1701.3
 3591- 63480 Chuk's Cab                       |     556 |     382620 |      1365.8
 5129 - Mengisti Taxi                         |     561 |     447300 |      1759.1
 5874 - Sergey Cab Corp.                      |     570 |     459660 |      3383.3
 3897 - 57856 Ilie Malec                      |     647 |     624480 |      3334.8
 5776 - Mekonen Cab Company                   |     663 |     507900 |      2503.2
 3897 - Ilie Malec                            |     707 |     699120 |      4253.5
 2733 - Benny Jona                            |     717 |     653580 |      2354.4
 4787 - Reny Cab Co                           |     727 |     452460 |      1471.0
 2192 - Zeymane Corp                          |     819 |     555000 |      1547.5
 4787 - 56058 Reny Cab Co                     |     923 |     618780 |      2394.3
 Petani Cab Corp                              |     965 |    1393500 |      9534.8
 2241 - 44667 Manuel Alonso                   |     991 |    1828380 |     11095.3
 1085 - N and W Cab Co                        |    1067 |     644820 |      2516.5
 5129 - 98755 Mengisti Taxi                   |    1082 |     926280 |      4319.2
 Checker Taxi                                 |    1103 |     690258 |      3328.2
 3319 - CD Cab Co                             |    1152 |     918840 |      4578.8
 5062 - 34841 Sam Mestas                      |    1236 |     729300 |      3136.8
 3556 - 36214 RC Andrews Cab                  |    1248 |    1220520 |      6394.7
 2823 - 73307 Seung Lee                       |    1255 |    1735320 |     10419.6
 3201 - CD Cab Co Inc                         |    1363 |    1024080 |      3988.2
 3141 - Zip Cab                               |    1460 |    1020660 |      5381.3
 6743 - Luhak Corp                            |    1530 |    1198740 |      5133.1
 6057 - 24657 Richard Addo                    |    1687 |    1524300 |      6578.7
 3620 - 52292 David K. Cab Corp.              |    1700 |    1967880 |     10466.2
 3591 - 63480 Chuks Cab                       |    1701 |    1105560 |      3480.8
 5997 - 65283 AW Services Inc.                |    1738 |    1739280 |      9952.9
 4053 - 40193 Adwar H. Nikola                 |    1755 |    2113080 |     14214.3
 C & D Cab Co Inc                             |    1849 |    1358280 |      6893.6
 6488 - 83287 Zuha Taxi                       |    2011 |    1437780 |      6560.6
 American United Taxi Affiliation             |    2094 |    2151903 |    10972.96
 2809 - 95474 C & D Cab Co Inc.               |    2148 |    1656900 |      9147.2
 312 Medallion Management Corp                |    2196 |    2321820 |     13727.7
 3253 - 91138 Gaither Cab Co.                 |    2269 |    1558740 |      7250.2
 4615 - 83503 Tyrone Henderson                |    2384 |    1760520 |      7678.1
 6747 - Mueen Abdalla                         |    2509 |    2149800 |      9674.4
 Park Ridge Taxi and Livery                   |    2581 |     566940 |           0
 2192 - 73487 Zeymane Corp                    |    2631 |    1961160 |      9592.7
 5874 - 73628 Sergey Cab Corp.                |    2755 |    2411820 |     16915.0
 585 - 88805 Valley Cab Co                    |    2770 |    2030520 |     10300.6
 6742 - 83735 Tasha ride inc                  |    2810 |    2583600 |     11512.8
 3623 - 72222 Arrington Enterprises           |    2839 |    2406660 |     15653.9
 5074 - 54002 Ahzmi Inc                       |    2875 |    2858700 |     15130.3
 Peace Taxi Assoc                             |    2917 |    2229540 |      9840.5
 1247 - 72807 Daniel Ayertey                  |    2932 |    2604120 |     12740.7
 4623 - 27290 Jay Kim                         |    2945 |    2873580 |     16988.9
 5 Star Taxi                                  |    2962 |    4224124 |    23766.02
 U Taxicab                                    |    3189 |    3147840 |     18869.7
 2733 - 74600 Benny Jona                      |    3190 |    3199980 |     16507.3
 0694 - 59280 Chinesco Trans Inc              |    3191 |    2634720 |     10150.5
 5724 - 75306 KYVI Cab Inc                    |    3201 |    2357580 |      9717.6
 Norshore Cab                                 |    3358 |    2244134 |     11155.1
 5006 - 39261 Salifu Bawa                     |    3422 |    2564460 |      9278.2
 4197 - 41842 Royal Star                      |    3460 |    2983020 |     15671.1
 3141 - 87803 Zip Cab                         |    3480 |    2184780 |      9600.4
 3094 - 24059 G.L.B. Cab Co                   |    3513 |    2378640 |      7903.3
 3152 - 97284 Crystal Abernathy               |    3585 |    2483040 |     13336.8
 5129 - 87128                                 |    3746 |    2819700 |     13679.4
 6574 - Babylon Express Inc.                  |    3747 |    3010080 |     12836.9
 2092 - 61288 Sbeih company                   |    4233 |    3772260 |     19756.4
 0118 - 42111 Godfrey S.Awir                  |    4249 |    3684780 |     18691.8
 1085 - 72312 N and W Cab Co                  |    4568 |    2698680 |     10171.0
 3011 - 66308 JBL Cab Inc.                    |    5111 |    3530640 |     16496.6
 3201 - C&D Cab Co Inc                        |    5328 |    3820080 |     16807.0
 6743 - 78771 Luhak Corp                      |    5695 |    4672380 |     19627.4
 American United                              |    5719 |    4482535 |     21227.6
 Leonard Cab Co                               |    5719 |    4554753 |     18877.7
 Yellow Cab                                   |    7300 |    5404272 |     25748.0
 Metro Group                                  |   10353 |    5288097 |     30081.6
 Metro Jet Taxi A                             |   11307 |   10376321 |     49558.6
 Setare Inc                                   |   12881 |   10743697 |     45216.8
 Service Taxi Association                     |   13823 |   12352560 |     57941.1
 Gold Coast Taxi                              |   20061 |   18692535 |    83192.49
 Blue Diamond                                 |   21389 |   18771862 |    85956.80
 Suburban Dispatch LLC                        |   31159 |    1540380 |           0
 Checker Taxi Affiliation                     |   43654 |   36871603 |   161809.20
 Chicago Elite Cab Corp.                      |   51537 |   36557400 |           0
 Chicago Taxicab                              |   54538 |   49287282 |   226768.80
 Taxicab Insurance Agency, LLC                |   60024 |   48030360 |    216647.4
 Chicago Medallion Management                 |   69866 |   48652500 |    215141.7
 Chicago Independents                         |   69894 |   66152130 |   309970.39
 24 Seven Taxi                                |   71197 |   64097827 |   290896.01
 Nova Taxi Affiliation Llc                    |   94787 |   80246864 |   338345.19
 Star North Management LLC                    |   98501 |   80250240 |    368732.2
 Patriot Taxi Dba Peace Taxi Associat         |  103102 |   97906849 |   380582.83
 T.A.S. - Payment Only                        |  115648 |   13736760 |           0
 Chicago Medallion Leasing INC                |  122236 |   90159540 |    402273.9
 303 Taxi                                     |  132195 |  108395564 |    839550.7
 Globe Taxi                                   |  163496 |  138176147 |   618141.52
 Taxi Affiliation Service Yellow              |  240081 |  204527388 |   933593.54
 Top Cab Affiliation                          |  293112 |  235315140 |   1201913.5
 Medallion Leasin                             |  304196 |  269973865 |  1228628.12
 Flash Cab                                    |  309036 |  320516588 |  1530518.73
 KOAM Taxi Association                        |  402152 |  324517920 |   1625989.5
 Sun Taxi                                     |  402595 |  372494509 |  1722755.67
 City Service                                 |  412574 |  351289597 |  1686948.48
 Chicago Carriage Cab Corp                    |  636705 |  598056976 |  4004443.67
 Chicago Elite Cab Corp. (Chicago Carriag     |  675031 |   94436760 |           0
 Northwest Management LLC                     |  732268 |  542881500 |   2160686.4
 Choice Taxi Association                      | 1379440 | 1125522960 |   4952431.1
 Blue Ribbon Taxi Association Inc.            | 1772906 | 1326451140 |    265605.1
 Dispatch Taxi Affiliation                    | 2260433 | 1693494540 |   7334346.2
                                              | 6772883 | 5551877584 | 33967146.42
 Taxi Affiliation Services                    | 7878710 | 6031986480 |  17136242.4
(155 rows)

Time: 337082.958 ms (05:37.083)
```
>Описать что и как делали и с какими проблемами столкнулись
