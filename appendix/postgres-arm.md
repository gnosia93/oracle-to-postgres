PostgreSQL 은 ARM 아키텍처를 오래전 부터 지원하고 있다. 아마존 EC2 Graviton2 인스턴스를 생성해서 ARM 용 PostgreSQL 을 설치할 수 있다.
이와는 달리 RDS 의 경우는 현재 ARM 은 지원이 되지 않는 것으로 보인다. 

### Supported Version of Linux Distributions ###

* Unbutu 의 경우 - PostgreSQL 12 까지 지원

  https://www.postgresql.org/download/linux/ubuntu/

* CentOS 의 경우 - PostgreSQL 13 까지 지원

  https://www.postgresql.org/download/linux/redhat/
  
* Amazon Linux 2 의 경우 - PostgreSQL 11 까지 지원
   
  Amazon Linux2 버전에서 지원되는 PostgreSQL 의 최신버전은 PostgreSQL 11.5 이다.


### ARM EC2 생성하기 ###

화면덤프..
CLI 

### PostgreSQL 설치하기(aarch64) ###

* https://docs.aws.amazon.com/ko_kr/corretto/latest/corretto-11-ug/what-is-corretto-11.html
Amazon Corretto는 무료로 사용할 수 있는 Open Java Development Kit(OpenJDK)의 프로덕션용 멀티플랫폼 배포판입니다. Corretto에는 성능 향상과 보안 수정 사항을 비롯한 장기 지원이 함께 제공됩니다. Corretto는 Java SE 표준과 호환되는 것으로 인증되었으며, 여러 프로덕션 서비스용으로 Amazon에서 내부적으로 실행됩니다. Corretto를 사용하면 Amazon Linux 2, Windows, macOS 같은 운영 체제에서 Java 애플리케이션을 개발하고 실행할 수 있습니다.

```
[ec2-user@ip-172-31-43-151 ~]$ uname -a
Linux ip-172-31-43-151.ap-northeast-2.compute.internal 4.14.219-164.354.amzn2.aarch64 #1 SMP Mon Feb 22 21:18:49 UTC 2021 aarch64 aarch64 aarch64 GNU/Linux

[ec2-user@ip-172-31-43-151 ~]$ sudo yum install java-11-amazon-corretto

[ec2-user@ip-172-31-43-151 ~]$ sudo amazon-linux-extras list | grep post
  4  postgresql9.6            available    [ =9.6.8  =stable ]
  5  postgresql10             available    [ =10  =stable ]
 34  postgresql11             available    [ =11  =stable ]

[ec2-user@ip-172-31-43-151 ~]$ sudo amazon-linux-extras install postgresql11 epel -y

[ec2-user@ip-172-31-43-151 ~]$ sudo yum install postgresql-server postgresql-contrib postgresql-devel -y

[ec2-user@ip-172-31-43-151 ~]$ postgres --version
postgres (PostgreSQL) 11.5

[ec2-user@ip-172-31-43-151 ~]$ sudo postgresql-setup --initdb
 * Initializing database in '/var/lib/pgsql/data'
 * Initialized, logs are in /var/lib/pgsql/initdb_postgresql.log

[ec2-user@ip-172-31-43-151 ~]$ sudo postgresql-setup --initdb
 * Initializing database in '/var/lib/pgsql/data'
 * Initialized, logs are in /var/lib/pgsql/initdb_postgresql.log

[ec2-user@ip-172-31-43-151 ~]$ sudo systemctl enable postgresql
Created symlink from /etc/systemd/system/multi-user.target.wants/postgresql.service to /usr/lib/systemd/system/postgresql.service.

[ec2-user@ip-172-31-43-151 ~]$ sudo systemctl start postgresql

[ec2-user@ip-172-31-43-151 ~]$ ps aux | grep postgres
postgres  1611  0.1  0.0 307684 22600 ?        Ss   11:18   0:00 /usr/bin/postmaster -D /var/lib/pgsql/data
postgres  1612  0.0  0.0 162600  4064 ?        Ss   11:18   0:00 postgres: logger   
postgres  1614  0.0  0.0 307684  3892 ?        Ss   11:18   0:00 postgres: checkpointer   
postgres  1615  0.0  0.0 307684  3892 ?        Ss   11:18   0:00 postgres: background writer   
postgres  1616  0.0  0.0 307684  3892 ?        Ss   11:18   0:00 postgres: walwriter   
postgres  1617  0.0  0.0 308084  6632 ?        Ss   11:18   0:00 postgres: autovacuum launcher   
postgres  1618  0.0  0.0 162600  4080 ?        Ss   11:18   0:00 postgres: stats collector   
postgres  1619  0.0  0.0 307980  6508 ?        Ss   11:18   0:00 postgres: logical replication launcher   
ec2-user  1622  0.0  0.0 113164  1872 pts/0    S+   11:18   0:00 grep --color=auto postgres

[ec2-user@ip-172-31-43-151 ~]$ sudo su - postgres
마지막 로그인: 금  3월 12 11:14:38 UTC 2021 일시 pts/0

-bash-4.2$ psql
psql (11.5)
Type "help" for help.

postgres=# select version();
                                                  version                                                  
-----------------------------------------------------------------------------------------------------------
 PostgreSQL 11.5 on aarch64-koji-linux-gnu, compiled by gcc (GCC) 7.3.1 20180712 (Red Hat 7.3.1-6), 64-bit
(1 row)

postgres=# CREATE DATABASE pgbenchtest OWNER postgres;
CREATE DATABASE

postgres=# \c pgbenchtest postgres
You are now connected to database "pgbenchtest" as user "postgres".

pgbenchtest=# \dt
Did not find any relations.

pgbenchtest=# \q

-bash-4.2$  pgbench -U postgres -i -s 100 pgbenchtest
dropping old tables...
creating tables...
generating data...
100000 of 10000000 tuples (1%) done (elapsed 0.08 s, remaining 8.11 s)
200000 of 10000000 tuples (2%) done (elapsed 0.16 s, remaining 7.74 s)
300000 of 10000000 tuples (3%) done (elapsed 0.25 s, remaining 8.05 s)
400000 of 10000000 tuples (4%) done (elapsed 0.35 s, remaining 8.41 s)
500000 of 10000000 tuples (5%) done (elapsed 0.43 s, remaining 8.14 s)
600000 of 10000000 tuples (6%) done (elapsed 0.53 s, remaining 8.29 s)
700000 of 10000000 tuples (7%) done (elapsed 0.62 s, remaining 8.28 s)
800000 of 10000000 tuples (8%) done (elapsed 0.71 s, remaining 8.15 s)
...


-bash-4.2$ psql -U postgres pgbenchtest
psql (11.5)
Type "help" for help.

pgbenchtest=# \dt+
                          List of relations
 Schema |       Name       | Type  |  Owner   |  Size   | Description 
--------+------------------+-------+----------+---------+-------------
 public | pgbench_accounts | table | postgres | 1281 MB | 
 public | pgbench_branches | table | postgres | 40 kB   | 
 public | pgbench_history  | table | postgres | 0 bytes | 
 public | pgbench_tellers  | table | postgres | 80 kB   | 
(4 rows)

pgbenchtest=# SELECT schemaname,relname,n_live_tup FROM pg_stat_user_tables;
 schemaname |     relname      | n_live_tup 
------------+------------------+------------
 public     | pgbench_tellers  |       1000
 public     | pgbench_branches |        100
 public     | pgbench_history  |          0
 public     | pgbench_accounts |   10000035
(4 rows)

pgbenchtest=# \l+
                                                                     List of databases
    Name     |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   |  Size   | Tablespace |                Description                 
-------------+----------+----------+-------------+-------------+-----------------------+---------+------------+--------------------------------------------
 pgbenchtest | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |                       | 1503 MB | pg_default | 
 postgres    | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |                       | 7989 kB | pg_default | default administrative connection database
 template0   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +| 7849 kB | pg_default | unmodifiable empty database
             |          |          |             |             | postgres=CTc/postgres |         |            | 
 template1   | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +| 7849 kB | pg_default | default template for new databases
             |          |          |             |             | postgres=CTc/postgres |         |            | 
(4 rows)
```


### 성능테스트(pgbench) ###

* https://www.enterprisedb.com/blog/pgbench-performance-benchmark-postgresql-12-and-edb-advanced-server-12

* https://browndwarf.tistory.com/52

아래는 하나의 pgbench 트랜잭션이 실행하는 SQL 정보로, BEGIN ~ END 사이에 있는 SQL 을 하나의 트랜잭션으로 실행한다. (TPC-B like)

![tx sql](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/images/pgbench_tx_sql.png)


pgbench 의 각 파라미터 값은 다음과 같다. 

* -c : 클라이언트 수
* -t : 클라이언트 당 트랜잭션 수
* -j : pgbench 프로세스의 쓰레드 수
* -d : 디버깅
* -P : report 간격
* pgbenchtest : 데이터베이스명 


* 메뉴얼 - https://www.postgresql.org/docs/10/pgbench.html

```
$ which pgbench
/usr/bin/pgbench

$ sudo su - postgres

-bash-4.2$ pgbench -U postgres -c 64 -t 10000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 15169.8 tps, lat 4.213 ms stddev 2.453
progress: 20.0 s, 15080.2 tps, lat 4.244 ms stddev 2.752
progress: 30.0 s, 15761.9 tps, lat 4.060 ms stddev 2.371
progress: 40.0 s, 14164.8 tps, lat 4.517 ms stddev 2.870
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 10000
number of transactions actually processed: 640000/640000
latency average = 4.263 ms
latency stddev = 2.620 ms
tps = 14921.995811 (including connections establishing)
tps = 14924.836465 (excluding connections establishing)
```


PostgreSQL ARM vs X86

PostgreSQL X86 vs Oracle 

* http://creedonlake.com/black-sails-bbx/e7c65b-postgresql-vs-oracle-performance-benchmark

