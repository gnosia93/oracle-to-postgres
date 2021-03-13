PostgreSQL 은 ARM 아키텍처를 오래전 부터 지원하고 있다. 아마존 EC2 Graviton2 인스턴스를 생성해서 ARM 용 PostgreSQL 을 설치할 수 있다.
이와는 달리 RDS 의 경우는 현재 ARM 은 지원이 되지 않는 것으로 보인다. 

### Supported Version of Linux Distributions ###

* Unbutu 의 경우 - PostgreSQL 12 까지 지원

  https://www.postgresql.org/download/linux/ubuntu/

* CentOS 의 경우 - PostgreSQL 13 까지 지원

  https://www.postgresql.org/download/linux/redhat/
  
* Amazon Linux 2 의 경우 - PostgreSQL 11 까지 지원
   
  Amazon Linux2 버전에서 지원되는 PostgreSQL 의 최신버전은 PostgreSQL 11.5 이다.

### EC2 생성하기 ###

다음과 같이 AWS CLI 를 이용하여 아키텍처 다이그램에 나와 있는 인스턴스들을 생성합니다.

* https://aws.amazon.com/ko/ec2/instance-types/r6/   
Amazon EC2 R6g instances are powered by Arm-based AWS Graviton2 processors. They deliver up to 40% better price performance over current generation R5 instances1 and are ideal for running memory-intensive workloads such as open-source databases, in-memory caches, and real time big data analytics. Developers can also use these instances to build Arm-based applications natively in the cloud, eliminating the need for cross-compilation and emulation, and improving time to market.
R6g instances are also available with local NVMe-based SSD block-level storage option (R6gd) for applications that need high-speed, low latency local storage.

  - c6g.8xlarge: 32 vCPU / 256 GB / 12 Gigabit (Graviton2)
  - r5.8xlarge: 32 vCPU / 256 GB / 12 Gigabit (X86-64) 
  
```
$ SG_ID=`aws ec2 describe-security-groups --group-names tf_sg_pub --query "SecurityGroups[0].{GroupId:GroupId}" --output text`; echo $SG_ID

$ ARM_AMI_ID=`aws ec2 describe-images \
                  --owners amazon \
                  --filters "Name=name, Values=amzn2-ami-hvm-2.0.20210303.0-arm64-gp2" \
                  --query "Images[0].{ImageId:ImageId}" --output text`; \
                  echo $ARM_AMI_ID

$ X64_AMI_ID=`aws ec2 describe-images \
                  --owners amazon \
                  --filters "Name=name, Values=amzn2-ami-hvm-2.0.20210303.0-x86_64-gp2" \
                  --query "Images[0].{ImageId:ImageId}" --output text`; \
                  echo $X64_AMI_ID

$ USER_DATA=`cat <<EOF | base64
#! /bin/bash
sudo amazon-linux-extras install postgresql11 epel -y
sudo yum install postgresql-server postgresql-contrib postgresql-devel -y
sudo -u ec2-user postgres --version >> /home/ec2-user/postgres.out
sudo postgresql-setup --initdb

sudo -u postgres sed -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" -i /var/lib/pgsql/data/postgresql.conf
sudo -u postgres sed -i -e "/is for Unix domain socket connections only/a\local   all             shop                        md5" /var/lib/pgsql/data/pg_hba.conf
sudo -u postgres echo "host    all             all             0.0.0.0/0               md5" >> /var/lib/pgsql/data/pg_hba.conf

sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo -u ec2-user ps aux | grep postgres >> /home/ec2-user/postgres.out
EOF`

$ aws ec2 run-instances \
  --image-id $ARM_AMI_ID \
  --count 1 \
  --instance-type c6g.8xlarge \
  --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=300, VolumeType=io2, Iops=50000}'   \
  --key-name tf_key \
  --security-group-ids $SG_ID \
  --monitoring Enabled=true \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cl_postgres_arm64}]' \
  --user-data $USER_DATA
  
$ aws ec2 run-instances \
  --image-id $X64_AMI_ID \
  --count 1 \
  --instance-type r5.8xlarge \
  --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=300, VolumeType=io2, Iops=50000}'   \
  --key-name tf_key \
  --security-group-ids $SG_ID \
  --monitoring Enabled=true \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cl_postgres_x86-64}]' \
  --user-data $USER_DATA
  
```




컴퓨팅 최적화 – 현재 세대

- X86: c5.4xlarge (16vCPU, 32G Memory, EBS, 시간당 0.68 USD) 
- ARM: c6g.4xlarge (16vCPU, 32G Memory, EBS, 시간당 0.544 USD)
* https://aws.amazon.com/ko/ec2/pricing/on-demand/

- EBS: io2 50,000 IOPS, 100GB 
* https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/UserGuide/ebs-volume-types.html


-- 이거 테스트해야 함. 
https://aws.amazon.com/ec2/instance-types/r6/



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

pgbenchtest=# \q
```


### PostgreSQL ARM vs X86-64 성능 테스트 (pgbench) ###

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

```
$ pgbench -U postgres -c 64 -t 5000 -M extended -j 64 -P 10 pgbenchtest
```

* 메뉴얼 - https://www.postgresql.org/docs/10/pgbench.html



### PostgreSQL ARM vs X86-64 성능 테스트 결과 (pgbench) ###

#### ARM64 측정 ####
```
-bash-4.2$ which pgbench
/usr/bin/pgbench

-bash-4.2$ pgbench -U postgres -c 64 -t 5000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 15344.0 tps, lat 4.166 ms stddev 2.496
progress: 20.0 s, 15826.2 tps, lat 4.043 ms stddev 2.430
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 5000
number of transactions actually processed: 320000/320000
latency average = 4.093 ms
latency stddev = 2.453 ms
tps = 15502.717309 (including connections establishing)
tps = 15509.394300 (excluding connections establishing)

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

-bash-4.2$ pgbench -U postgres -c 64 -t 30000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 15924.1 tps, lat 4.014 ms stddev 2.127
progress: 20.0 s, 15247.3 tps, lat 4.198 ms stddev 2.618
progress: 30.0 s, 15013.3 tps, lat 4.263 ms stddev 2.474
progress: 40.0 s, 14855.5 tps, lat 4.308 ms stddev 2.826
progress: 50.0 s, 15732.2 tps, lat 4.068 ms stddev 2.359
progress: 60.0 s, 15266.7 tps, lat 4.192 ms stddev 2.542
progress: 70.0 s, 15272.1 tps, lat 4.191 ms stddev 2.632
progress: 80.0 s, 15000.5 tps, lat 4.266 ms stddev 2.426
progress: 90.0 s, 12970.9 tps, lat 4.934 ms stddev 3.198
progress: 100.0 s, 12442.5 tps, lat 5.143 ms stddev 2.879
progress: 110.0 s, 11592.0 tps, lat 5.522 ms stddev 3.118
progress: 120.0 s, 10792.0 tps, lat 5.931 ms stddev 3.095
progress: 130.0 s, 10220.9 tps, lat 6.261 ms stddev 3.006
progress: 140.0 s, 9595.0 tps, lat 6.658 ms stddev 2.884
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 30000
number of transactions actually processed: 1920000/1920000
latency average = 4.734 ms
latency stddev = 2.842 ms
tps = 13467.872840 (including connections establishing)
tps = 13468.617551 (excluding connections establishing)

-bash-4.2$ pgbench -U postgres -c 64 -t 50000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 15853.2 tps, lat 4.032 ms stddev 2.032
progress: 20.0 s, 14850.3 tps, lat 4.310 ms stddev 2.829
progress: 30.0 s, 15474.0 tps, lat 4.135 ms stddev 2.498
progress: 40.0 s, 15131.8 tps, lat 4.229 ms stddev 2.686
progress: 50.0 s, 15192.2 tps, lat 4.214 ms stddev 2.711
progress: 60.0 s, 15122.9 tps, lat 4.232 ms stddev 2.477
progress: 70.0 s, 13880.9 tps, lat 4.610 ms stddev 3.051
progress: 80.0 s, 14777.8 tps, lat 4.331 ms stddev 2.527
progress: 90.0 s, 15199.6 tps, lat 4.211 ms stddev 2.488
progress: 100.0 s, 14645.3 tps, lat 4.370 ms stddev 2.864
progress: 110.0 s, 15431.5 tps, lat 4.147 ms stddev 2.466
progress: 120.0 s, 14557.9 tps, lat 4.396 ms stddev 2.664
progress: 130.0 s, 13318.7 tps, lat 4.806 ms stddev 2.993
progress: 140.0 s, 12826.4 tps, lat 4.989 ms stddev 2.681
progress: 150.0 s, 11649.7 tps, lat 5.494 ms stddev 3.264
progress: 160.0 s, 11225.0 tps, lat 5.701 ms stddev 2.751
progress: 170.0 s, 10069.1 tps, lat 6.342 ms stddev 3.231
progress: 180.0 s, 9621.3 tps, lat 6.665 ms stddev 3.011
progress: 190.0 s, 9028.6 tps, lat 7.090 ms stddev 2.962
progress: 200.0 s, 8456.9 tps, lat 7.568 ms stddev 3.153
progress: 210.0 s, 7899.3 tps, lat 8.098 ms stddev 3.439
progress: 220.0 s, 7553.7 tps, lat 8.476 ms stddev 3.514
progress: 230.0 s, 7297.8 tps, lat 8.770 ms stddev 3.389
progress: 240.0 s, 13642.5 tps, lat 4.692 ms stddev 2.930
progress: 250.0 s, 14191.3 tps, lat 4.510 ms stddev 2.510
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 50000
number of transactions actually processed: 3200000/3200000
latency average = 5.048 ms
latency stddev = 3.084 ms
tps = 12648.108408 (including connections establishing)
tps = 12648.476329 (excluding connections establishing)

-bash-4.2$ pgbench -U postgres -c 64 -t 70000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 15215.9 tps, lat 4.200 ms stddev 2.471
progress: 20.0 s, 15099.7 tps, lat 4.239 ms stddev 2.495
progress: 30.0 s, 14715.7 tps, lat 4.348 ms stddev 2.757
progress: 40.0 s, 15056.6 tps, lat 4.250 ms stddev 2.673
progress: 50.0 s, 15291.6 tps, lat 4.187 ms stddev 2.444
progress: 60.0 s, 14909.9 tps, lat 4.292 ms stddev 2.685
progress: 70.0 s, 13888.4 tps, lat 4.608 ms stddev 2.892
progress: 80.0 s, 13741.3 tps, lat 4.657 ms stddev 2.527
progress: 90.0 s, 12678.0 tps, lat 5.047 ms stddev 2.625
progress: 100.0 s, 11735.8 tps, lat 5.455 ms stddev 2.763
progress: 110.0 s, 10728.4 tps, lat 5.965 ms stddev 3.171
progress: 120.0 s, 10410.1 tps, lat 6.148 ms stddev 2.910
progress: 130.0 s, 9794.3 tps, lat 6.535 ms stddev 2.978
progress: 140.0 s, 9273.7 tps, lat 6.899 ms stddev 2.999
progress: 150.0 s, 8706.1 tps, lat 7.353 ms stddev 3.234
progress: 160.0 s, 8369.2 tps, lat 7.647 ms stddev 3.204
progress: 170.0 s, 7979.8 tps, lat 8.019 ms stddev 3.216
progress: 180.0 s, 8987.5 tps, lat 7.123 ms stddev 3.676
progress: 190.0 s, 14290.2 tps, lat 4.479 ms stddev 2.882
progress: 200.0 s, 13588.3 tps, lat 4.710 ms stddev 2.936
progress: 210.0 s, 13654.3 tps, lat 4.688 ms stddev 2.498
progress: 220.0 s, 12474.1 tps, lat 5.130 ms stddev 2.542
progress: 230.0 s, 11464.0 tps, lat 5.583 ms stddev 2.681
progress: 240.0 s, 10438.3 tps, lat 6.130 ms stddev 2.872
progress: 250.0 s, 9754.6 tps, lat 6.562 ms stddev 2.883
progress: 260.0 s, 9159.1 tps, lat 6.987 ms stddev 3.027
progress: 270.0 s, 11015.7 tps, lat 5.810 ms stddev 3.075
progress: 280.0 s, 13990.8 tps, lat 4.575 ms stddev 2.578
progress: 290.0 s, 14346.6 tps, lat 4.460 ms stddev 2.892
progress: 300.0 s, 14880.3 tps, lat 4.302 ms stddev 2.692
progress: 310.0 s, 14322.8 tps, lat 4.468 ms stddev 2.561
progress: 320.0 s, 13492.9 tps, lat 4.743 ms stddev 2.496
progress: 330.0 s, 12290.0 tps, lat 5.207 ms stddev 2.592
progress: 340.0 s, 11399.7 tps, lat 5.614 ms stddev 2.679
progress: 350.0 s, 10650.1 tps, lat 6.008 ms stddev 2.752
progress: 360.0 s, 10092.1 tps, lat 6.343 ms stddev 2.800
progress: 370.0 s, 9496.6 tps, lat 6.702 ms stddev 2.981
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 70000
number of transactions actually processed: 4480000/4480000
latency average = 5.290 ms
latency stddev = 2.978 ms
tps = 12071.751449 (including connections establishing)
tps = 12072.078778 (excluding connections establishing)

-bash-4.2$ pgbench -U postgres -c 64 -t 90000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 15484.4 tps, lat 4.127 ms stddev 2.515
progress: 20.0 s, 15689.8 tps, lat 4.079 ms stddev 2.487
progress: 30.0 s, 15687.1 tps, lat 4.080 ms stddev 2.495
progress: 40.0 s, 14532.0 tps, lat 4.404 ms stddev 3.046
progress: 50.0 s, 16061.4 tps, lat 3.985 ms stddev 2.437
progress: 60.0 s, 15589.0 tps, lat 4.105 ms stddev 2.481
progress: 70.0 s, 15074.6 tps, lat 4.245 ms stddev 2.829
progress: 80.0 s, 15283.0 tps, lat 4.188 ms stddev 2.714
progress: 90.0 s, 15651.0 tps, lat 4.089 ms stddev 2.439
progress: 100.0 s, 15021.3 tps, lat 4.260 ms stddev 2.471
progress: 110.0 s, 13793.8 tps, lat 4.640 ms stddev 2.923
progress: 120.0 s, 13725.9 tps, lat 4.663 ms stddev 2.787
progress: 130.0 s, 11618.9 tps, lat 5.508 ms stddev 3.965
progress: 140.0 s, 10927.1 tps, lat 5.857 ms stddev 4.453
progress: 150.0 s, 11327.8 tps, lat 5.649 ms stddev 3.483
progress: 160.0 s, 11745.2 tps, lat 5.448 ms stddev 2.598
progress: 170.0 s, 10993.7 tps, lat 5.823 ms stddev 2.711
progress: 180.0 s, 10337.6 tps, lat 6.191 ms stddev 2.797
progress: 190.0 s, 10659.5 tps, lat 6.005 ms stddev 3.033
progress: 200.0 s, 15489.1 tps, lat 4.132 ms stddev 2.521
progress: 210.0 s, 15499.3 tps, lat 4.129 ms stddev 2.583
progress: 220.0 s, 14768.1 tps, lat 4.334 ms stddev 2.855
progress: 230.0 s, 15056.4 tps, lat 4.250 ms stddev 2.398
progress: 240.0 s, 13979.8 tps, lat 4.577 ms stddev 2.488
progress: 250.0 s, 14784.6 tps, lat 4.329 ms stddev 2.628
progress: 260.0 s, 14170.1 tps, lat 4.517 ms stddev 2.842
progress: 270.0 s, 14272.0 tps, lat 4.485 ms stddev 2.467
progress: 280.0 s, 13203.0 tps, lat 4.847 ms stddev 2.539
progress: 290.0 s, 12277.7 tps, lat 5.212 ms stddev 2.569
progress: 300.0 s, 11397.3 tps, lat 5.615 ms stddev 2.580
progress: 310.0 s, 10605.4 tps, lat 6.035 ms stddev 2.743
progress: 320.0 s, 9922.3 tps, lat 6.450 ms stddev 2.895
progress: 330.0 s, 9259.9 tps, lat 6.911 ms stddev 3.061
progress: 340.0 s, 8755.3 tps, lat 7.310 ms stddev 3.236
progress: 350.0 s, 8370.5 tps, lat 7.645 ms stddev 3.338
progress: 360.0 s, 7914.1 tps, lat 8.087 ms stddev 3.462
progress: 370.0 s, 7677.1 tps, lat 8.337 ms stddev 3.361
progress: 380.0 s, 7328.8 tps, lat 8.732 ms stddev 3.544
progress: 390.0 s, 13175.4 tps, lat 4.858 ms stddev 3.199
progress: 400.0 s, 14831.3 tps, lat 4.316 ms stddev 2.754
progress: 410.0 s, 15484.4 tps, lat 4.133 ms stddev 2.460
progress: 420.0 s, 15308.1 tps, lat 4.181 ms stddev 2.432
progress: 430.0 s, 14760.9 tps, lat 4.335 ms stddev 2.786
progress: 440.0 s, 14834.0 tps, lat 4.315 ms stddev 2.626
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 90000
number of transactions actually processed: 5760000/5760000
latency average = 4.913 ms
latency stddev = 3.019 ms
tps = 13004.251277 (including connections establishing)
tps = 13004.536353 (excluding connections establishing)
```

#### X86-64 측정 ####
```
$ which pgbench
/usr/bin/pgbench

$ sudo su - postgres

-bash-4.2$ pgbench -U postgres -c 64 -t 5000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 13319.0 tps, lat 4.797 ms stddev 3.310
progress: 20.0 s, 13509.3 tps, lat 4.737 ms stddev 3.691
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 5000
number of transactions actually processed: 320000/320000
latency average = 4.742 ms
latency stddev = 3.482 ms
tps = 13409.689441 (including connections establishing)
tps = 13416.891660 (excluding connections establishing)

-bash-4.2$ pgbench -U postgres -c 64 -t 10000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 14927.0 tps, lat 4.281 ms stddev 2.902
progress: 20.0 s, 14861.7 tps, lat 4.306 ms stddev 3.125
progress: 30.0 s, 15337.4 tps, lat 4.173 ms stddev 3.075
progress: 40.0 s, 13749.9 tps, lat 4.645 ms stddev 3.367
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 10000
number of transactions actually processed: 640000/640000
latency average = 4.326 ms
latency stddev = 3.139 ms
tps = 14715.739832 (including connections establishing)
tps = 14719.759213 (excluding connections establishing)

-bash-4.2$ pgbench -U postgres -c 64 -t 30000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 15408.9 tps, lat 4.147 ms stddev 2.693
progress: 20.0 s, 14985.2 tps, lat 4.271 ms stddev 3.303
progress: 30.0 s, 14444.6 tps, lat 4.430 ms stddev 3.014
progress: 40.0 s, 12382.1 tps, lat 5.169 ms stddev 3.999
progress: 50.0 s, 11710.2 tps, lat 5.465 ms stddev 3.784
progress: 60.0 s, 11442.1 tps, lat 5.593 ms stddev 3.531
progress: 70.0 s, 10528.4 tps, lat 6.079 ms stddev 3.876
progress: 80.0 s, 10236.1 tps, lat 6.253 ms stddev 3.277
progress: 90.0 s, 9319.2 tps, lat 6.868 ms stddev 3.879
progress: 100.0 s, 8764.3 tps, lat 7.300 ms stddev 3.763
progress: 110.0 s, 8077.9 tps, lat 7.925 ms stddev 3.588
progress: 120.0 s, 7679.5 tps, lat 8.333 ms stddev 3.687
progress: 130.0 s, 7267.3 tps, lat 8.806 ms stddev 3.941
progress: 140.0 s, 6879.3 tps, lat 9.302 ms stddev 4.093
progress: 150.0 s, 11697.1 tps, lat 5.473 ms stddev 3.965
progress: 160.0 s, 12814.0 tps, lat 4.994 ms stddev 3.251
progress: 170.0 s, 11994.3 tps, lat 5.336 ms stddev 2.950
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 30000
number of transactions actually processed: 1920000/1920000
latency average = 5.858 ms
latency stddev = 3.807 ms
tps = 10890.839490 (including connections establishing)
tps = 10891.557328 (excluding connections establishing)

-bash-4.2$ pgbench -U postgres -c 64 -t 50000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 15574.2 tps, lat 4.102 ms stddev 2.710
progress: 20.0 s, 15438.0 tps, lat 4.146 ms stddev 3.030
progress: 30.0 s, 15183.9 tps, lat 4.215 ms stddev 3.281
progress: 40.0 s, 15820.0 tps, lat 4.045 ms stddev 2.789
progress: 50.0 s, 15378.1 tps, lat 4.162 ms stddev 3.022
progress: 60.0 s, 14533.9 tps, lat 4.403 ms stddev 3.237
progress: 70.0 s, 13977.5 tps, lat 4.579 ms stddev 2.884
progress: 80.0 s, 12959.3 tps, lat 4.938 ms stddev 2.924
progress: 90.0 s, 11615.8 tps, lat 5.510 ms stddev 3.480
progress: 100.0 s, 10738.8 tps, lat 5.959 ms stddev 3.541
progress: 110.0 s, 10131.0 tps, lat 6.317 ms stddev 3.250
progress: 120.0 s, 9476.8 tps, lat 6.753 ms stddev 3.424
progress: 130.0 s, 8825.4 tps, lat 7.251 ms stddev 3.526
progress: 140.0 s, 8349.7 tps, lat 7.666 ms stddev 3.629
progress: 150.0 s, 7786.6 tps, lat 8.218 ms stddev 3.799
progress: 160.0 s, 7485.9 tps, lat 8.549 ms stddev 3.857
progress: 170.0 s, 7095.6 tps, lat 9.019 ms stddev 3.979
progress: 180.0 s, 12928.6 tps, lat 4.952 ms stddev 3.389
progress: 190.0 s, 13918.6 tps, lat 4.598 ms stddev 2.732
progress: 200.0 s, 12476.0 tps, lat 5.129 ms stddev 3.243
progress: 210.0 s, 11719.9 tps, lat 5.460 ms stddev 3.186
progress: 220.0 s, 10819.7 tps, lat 5.916 ms stddev 3.146
progress: 230.0 s, 10010.9 tps, lat 6.393 ms stddev 3.170
progress: 240.0 s, 9407.4 tps, lat 6.803 ms stddev 3.190
progress: 250.0 s, 9762.1 tps, lat 6.555 ms stddev 3.653
progress: 260.0 s, 14533.0 tps, lat 4.404 ms stddev 3.235
progress: 270.0 s, 13950.8 tps, lat 4.466 ms stddev 2.826
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 50000
number of transactions actually processed: 3200000/3200000
latency average = 5.395 ms
latency stddev = 3.482 ms
tps = 11842.801854 (including connections establishing)
tps = 11843.356407 (excluding connections establishing)

-bash-4.2$ pgbench -U postgres -c 64 -t 70000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 16350.1 tps, lat 3.907 ms stddev 2.293
progress: 20.0 s, 15241.9 tps, lat 4.200 ms stddev 3.317
progress: 30.0 s, 15810.6 tps, lat 4.048 ms stddev 2.716
progress: 40.0 s, 15499.3 tps, lat 4.121 ms stddev 3.024
progress: 50.0 s, 15465.9 tps, lat 4.147 ms stddev 3.246
progress: 60.0 s, 15857.3 tps, lat 4.036 ms stddev 2.719
progress: 70.0 s, 15466.7 tps, lat 4.137 ms stddev 3.054
progress: 80.0 s, 15053.0 tps, lat 4.253 ms stddev 3.171
progress: 90.0 s, 14874.6 tps, lat 4.302 ms stddev 2.709
progress: 100.0 s, 15584.1 tps, lat 4.106 ms stddev 2.790
progress: 110.0 s, 14998.3 tps, lat 4.268 ms stddev 3.403
progress: 120.0 s, 15230.8 tps, lat 4.202 ms stddev 2.824
progress: 130.0 s, 14280.8 tps, lat 4.481 ms stddev 2.673
progress: 140.0 s, 13007.2 tps, lat 4.919 ms stddev 2.762
progress: 150.0 s, 11724.4 tps, lat 5.450 ms stddev 2.930
progress: 160.0 s, 10690.9 tps, lat 5.996 ms stddev 3.124
progress: 170.0 s, 10012.7 tps, lat 6.392 ms stddev 3.077
progress: 180.0 s, 9372.6 tps, lat 6.829 ms stddev 3.204
progress: 190.0 s, 8771.3 tps, lat 7.295 ms stddev 3.473
progress: 200.0 s, 14149.7 tps, lat 4.518 ms stddev 3.495
progress: 210.0 s, 15503.3 tps, lat 4.134 ms stddev 3.113
progress: 220.0 s, 15674.5 tps, lat 4.083 ms stddev 2.775
progress: 230.0 s, 15362.7 tps, lat 4.166 ms stddev 3.209
progress: 240.0 s, 15491.1 tps, lat 4.131 ms stddev 3.136
progress: 250.0 s, 15858.6 tps, lat 4.036 ms stddev 2.716
progress: 260.0 s, 15186.6 tps, lat 4.214 ms stddev 2.996
progress: 270.0 s, 14095.3 tps, lat 4.540 ms stddev 3.227
progress: 280.0 s, 13952.3 tps, lat 4.588 ms stddev 2.815
progress: 290.0 s, 14082.8 tps, lat 4.544 ms stddev 2.805
progress: 300.0 s, 12900.2 tps, lat 4.960 ms stddev 2.850
progress: 310.0 s, 11974.1 tps, lat 5.345 ms stddev 2.868
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 70000
number of transactions actually processed: 4480000/4480000
latency average = 4.559 ms
latency stddev = 3.079 ms
tps = 14011.292694 (including connections establishing)
tps = 14011.836340 (excluding connections establishing)
-bash-4.2$ 

-bash-4.2$ pgbench -U postgres -c 64 -t 90000 -M extended -j 64 -P 10 pgbenchtest
starting vacuum...end.
progress: 10.0 s, 15884.3 tps, lat 4.015 ms stddev 2.705
progress: 20.0 s, 15942.0 tps, lat 4.022 ms stddev 2.784
progress: 30.0 s, 15759.0 tps, lat 4.061 ms stddev 2.906
progress: 40.0 s, 15266.0 tps, lat 4.193 ms stddev 3.309
progress: 50.0 s, 15998.4 tps, lat 4.000 ms stddev 2.752
progress: 60.0 s, 15725.4 tps, lat 4.070 ms stddev 2.914
progress: 70.0 s, 14976.0 tps, lat 4.273 ms stddev 3.243
progress: 80.0 s, 15556.8 tps, lat 4.114 ms stddev 2.848
progress: 90.0 s, 14606.7 tps, lat 4.382 ms stddev 2.717
progress: 100.0 s, 13276.9 tps, lat 4.820 ms stddev 2.920
progress: 110.0 s, 12325.8 tps, lat 5.193 ms stddev 3.105
progress: 120.0 s, 15198.6 tps, lat 4.211 ms stddev 3.119
progress: 130.0 s, 15989.6 tps, lat 4.003 ms stddev 2.669
progress: 140.0 s, 15616.1 tps, lat 4.098 ms stddev 2.996
progress: 150.0 s, 15335.1 tps, lat 4.174 ms stddev 3.139
progress: 160.0 s, 15751.9 tps, lat 4.063 ms stddev 2.750
progress: 170.0 s, 15553.0 tps, lat 4.115 ms stddev 3.004
progress: 180.0 s, 15400.9 tps, lat 4.156 ms stddev 3.177
progress: 190.0 s, 15969.8 tps, lat 4.007 ms stddev 2.755
progress: 200.0 s, 15261.9 tps, lat 4.193 ms stddev 2.865
progress: 210.0 s, 14996.8 tps, lat 4.268 ms stddev 3.238
progress: 220.0 s, 15004.5 tps, lat 4.265 ms stddev 2.748
progress: 230.0 s, 13916.1 tps, lat 4.599 ms stddev 2.740
progress: 240.0 s, 12893.5 tps, lat 4.963 ms stddev 2.778
progress: 250.0 s, 11686.1 tps, lat 5.469 ms stddev 3.098
progress: 260.0 s, 10708.3 tps, lat 5.985 ms stddev 3.210
progress: 270.0 s, 10063.1 tps, lat 6.353 ms stddev 3.195
progress: 280.0 s, 9219.3 tps, lat 6.950 ms stddev 3.388
progress: 290.0 s, 8651.1 tps, lat 7.398 ms stddev 3.429
progress: 300.0 s, 8144.6 tps, lat 7.857 ms stddev 3.601
progress: 310.0 s, 7775.0 tps, lat 8.231 ms stddev 3.745
progress: 320.0 s, 7269.0 tps, lat 8.805 ms stddev 3.981
progress: 330.0 s, 12769.0 tps, lat 5.014 ms stddev 3.609
progress: 340.0 s, 14583.8 tps, lat 4.388 ms stddev 2.870
progress: 350.0 s, 13859.2 tps, lat 4.618 ms stddev 3.091
progress: 360.0 s, 15044.7 tps, lat 4.254 ms stddev 2.883
progress: 370.0 s, 13826.7 tps, lat 4.629 ms stddev 2.761
progress: 380.0 s, 12598.0 tps, lat 5.080 ms stddev 2.756
progress: 390.0 s, 11301.6 tps, lat 5.663 ms stddev 2.904
progress: 400.0 s, 10431.3 tps, lat 6.135 ms stddev 3.092
progress: 410.0 s, 9710.1 tps, lat 6.591 ms stddev 3.213
progress: 420.0 s, 9046.2 tps, lat 7.074 ms stddev 3.401
progress: 430.0 s, 8564.5 tps, lat 7.473 ms stddev 3.559
progress: 440.0 s, 8020.5 tps, lat 7.855 ms stddev 3.580
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 100
query mode: extended
number of clients: 64
number of threads: 64
number of transactions per client: 90000
number of transactions actually processed: 5760000/5760000
latency average = 4.890 ms
latency stddev = 3.267 ms
tps = 13057.520122 (including connections establishing)
tps = 13057.908124 (excluding connections establishing)
```




PostgreSQL X86 vs Oracle 

* http://creedonlake.com/black-sails-bbx/e7c65b-postgresql-vs-oracle-performance-benchmark

