# Oracle to Postgres Migration Workshop #

이 튜토리얼은 Mac OS 기준으로 작성되었다. 클라이언트가 윈도우인 경우, 구글 검색을 통해 관련된 명령어를 찾아야 한다.   
실습용 인프라는 테라폼을 이용하여 빌드하는데, 테라폼 관련 정보는 다음 URL 을 통해 확인할 수 있다. (https://www.terraform.io/)  
이번 튜토리얼에서는 테라폼에 대한 내용은 다루지 않는다. 

## 실습 아키텍처 ##

### 1. 소프트웨어설치 ###
  * 테라폼
  * Git
  * Pgadmin4
  * SQLDeveloper


### 2. 테라폼 프로젝트를 로컬 PC로 다운받기 ###

로컬 PC 로 terraform 코드를 clone 한다. 

```
$ cd                      # home 디렉토리로 이동
$ git clone https://github.com/gnosia93/postgres-terraform.git
$ cd postgres-terraform/
```

### 3. AWS 로그인키 설정 ####
```
$ aws configure           # region 과 aws key 설정
```

### 4. 인프라 빌드 ###

인프라 구성요소는 소스 데이터베이스인 오라클과 타켓 데이터베이스인 postgresql, 데이터 복제시 사용할 DMS 인스턴스 및 초기 데이터 로딩에 사용되는 EC2 인스턴스로 구성되어 있다.  
오라클 설치, OS 파리미터 설정, 네트워크 설정 등과 같은 기본적인 설정은 모두 자동화 되어 있기 때문에, DMS 와 postgresql 에 대한 이해도를 높일 수...

```
var.tf 수정 (내아이피 확인후)
$ terraform apply -auto-approve
```

### 5. 소스 오라클 데이터베이스 설정 ###

DMS을 이용하여 CDC 방식으로 데이터를 복제하기 위해서는 아래의 두가지 요건을 충족해야 한다.

* 아카이브 로그 모드 전환
* supplemental 로깅 활성화

데이터 로딩은 자동으로 빌드된 ec2 인스턴스 중, tf_loggen 이라는 이름을 가지 인스턴스로 로그인 한 후, 아래의 명령어를 이용하여 진행하면 된다.
스키마 생성 및 초기 데이터 로딩의 대상이 되는 오라클 데이터베이스의 IP 는, 자동으로 설정되기 때문에 아래의 명령어를 수행하기만 하면 된다. 

#### 5-1. 아카이브 로그 모드 전환 ####

아카이브 로그 모드로 전환하기 위해서는 데이테베이스를 shutdown 한 후, 아래와 같이 mount 모드에서 아카이브 로그를 활성화 해준다.
운영 시스템의 경우 이미 아카이브 로그가 활성화 되어 있는 경우가 대부분이기 때문에 이 과정을 불필요할 수 있다
데이터베이스가 아카이브 로그로 운영중인지 체크하기 위해서는 아래의 SQL 을 실행하면 된다. 
```
SQL> select name, log_mode from v$database;

NAME	  LOG_MODE
--------- ------------
XE	  NOARCHIVELOG
```

[아카이브 로그 전환 방법]
```
oracle@ip-172-31-32-20:~$ sqlplus "/ as sysdba"

SQL*Plus: Release 11.2.0.2.0 Production on Mon Jan 25 07:37:09 2021

Copyright (c) 1982, 2011, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production

SQL> shutdown immediate;
Database closed.
Database dismounted.
ORACLE instance shut down.
SQL> startup mount          
ORACLE instance started.

Total System Global Area 1068937216 bytes
Fixed Size		    2233344 bytes
Variable Size		  822086656 bytes
Database Buffers	  239075328 bytes
Redo Buffers		    5541888 bytes
Database mounted.
SQL> alter database archivelog;

Database altered.

SQL> alter database open;

Database altered.

SQL> archive log list
Database log mode	       Archive Mode
Automatic archival	       Enabled
Archive destination	       USE_DB_RECOVERY_FILE_DEST
Oldest online log sequence     497
Next log sequence to archive   498
Current log sequence	       498
```

#### 5-2. supplemental 로깅 활성화 ####

[오라클 설정 조회]
```
SQL> col log_min format a10
SQL> col log_pk format a10
SQL> col log_ui format a10
SQL> col log_all format a10

SQL> select name, log_mode, 
       supplemental_log_data_min as log_min, 
       supplemental_log_data_pk as log_pk, 
       supplemental_log_data_ui as log_ui, 
       supplemental_log_data_all as log_all from v$database;
       
NAME	  LOG_MODE     LOG_MIN	  LOG_PK     LOG_UI	LOG_ALL
--------- ------------ ---------- ---------- ---------- ----------
XE	  ARCHIVELOG NO	  NO	     NO 	NO
```

[supplemental logging 활성화]
```
SQL> alter database add supplemental log data;
SQL> alter database add supplemental log data (primary key) columns;
SQL> alter database add supplemental log data (unique) columns;

SQL> select name, log_mode, 
       supplemental_log_data_min as log_min, 
       supplemental_log_data_pk as log_pk, 
       supplemental_log_data_ui as log_ui, 
       supplemental_log_data_all as log_all from v$database;

NAME	  LOG_MODE     LOG_MIN	  LOG_PK     LOG_UI	LOG_ALL
--------- ------------ ---------- ---------- ---------- ----------
XE	  NOARCHIVELOG YES	  YES	     YES	NO
```
로그 마이너를 위한 최소한의 로깅과 update 시 레코드를 식별하기 위해 필요한 PK 또는 유니크 인덱스에 대한 supplemental logging 기능을 활성화 한다.
만약 복제 대상이 되는 테이블에 PK 또는 Non-NULL 유니크 인덱스 또는 제약조건이 없다면 전체 칼럼에 로깅된다. 
supplemental logging 에 대한 자세한 내용은 오라클 문서를 참조하도록 한다. 

* [Supplemental Logging](https://docs.oracle.com/database/121/SUTIL/GUID-D857AF96-AC24-4CA1-B620-8EA3DF30D72E.htm#SUTIL1582)
* [Database-Level Supplemental Logging](https://docs.oracle.com/database/121/SUTIL/GUID-D2DDD67C-E1CC-45A6-A2A7-198E4C142FA3.htm#SUTIL1583)

### 6. postgres 설정 ###

postgresql 은 default 로 로컬 접속만을 허용한다. 외부에서 접속하고자 하는 경우 아래와 같이 설정 파일 2개를 수정해야 한다.   
또한 DMS 를 이용하여 오라클 데이터베이스의 변경 데이터를 복제하기 위해서는 postgresql 역시 데이터베이스, 테이블스페이스 및 접속 유저에 대한 설정이 필요하다.   
postgresql는 여러개의 작은 데이터베이스들로 구성이 되어져 있으며, 각각의 데이터베이스는 동일한 인스턴스에 의해 관리되지만, 실제로는 완전히 분리된 데이터베이스로
생각해야 하며, 서로 다른 데이터베이스 테이블간의 조인은 불가능하다.
오라클 12c 부터는 경우 PDB, CDB 구조로 되어 있어 postgresql 와 비슷한 데이터베이스 구조로 설계되어 있지만, 오라클 11g 의 겨우
하나의 데이터베이스로 설계되어져 있어서, postgresql 전환시 하나의 데이터베이스 매핑 되도록 해야 한다. 

이 단계에서는 타켓 데이터베이스인 postgres 에서 사용할 유저와 데이터베이스, 테이블스페이스 및 유저를 생성하고, 외부 접속을 위한 설정파일을 수정할 예정이다. 
또한 외부 접속을 위한 설정이 완료된 후, pgadmin 을 이용하여 외부에서 접속 테스트를 수행할 예정이다. 

#### 6-1. 유저 생성 ####

postgres 의 어드민 계정인 postgres 로 로그인 하여, 일반 유저인 shop 유저를 만든 후, 

오라클의 DBA_USER 뷰에 해당하는 pg_shadow 뷰로 부터 shop 유저가 제대로 만들어 졌는지 확인한다.

```
(base) f8ffc2077dc2:~ soonbeom$ ssh -i ~/.ssh/tf_key ec2-user@13.124.101.223

[ec2-user@ip-172-31-42-82 ~]$ sudo su - postgres
-bash-4.2$ psql
psql (11.5)
Type "help" for help.

postgres=# select 1;
 ?column? 
----------
        1
(1 row)

postgres=# create user shop password 'shop';
CREATE ROLE
postgres=# select * from pg_shadow;
 usename  | usesysid | usecreatedb | usesuper | userepl | usebypassrls |               passwd                | valuntil | useconfig 
----------+----------+-------------+----------+---------+--------------+-------------------------------------+----------+-----------
 postgres |       10 | t           | t        | t       | t            |                                     |          | 
 shop     |    16384 | f           | f        | f       | f            | md5f0c1de5eb2934ac9f886a646a0a46ba4 |          | 
(2 rows)
```

#### 6-2. 테이블스페이스 생성 ####

/var/lib/pgsql/data 디렉토리 하위에 tbs_shop 이라는 디렉토리를 만든 다음, 테이블 스페이스를 생성한다. 

```
-bash-4.2$ pwd
/var/lib/pgsql

-bash-4.2$ mkdir tablespace
-bash-4.2$ cd tablespace/
-bash-4.2$ mkdir tbs_shop
-bash-4.2$ ls -la
total 0
drwxr-xr-x 3 postgres postgres  22 Jan 18 08:42 .
drwx------ 5 postgres postgres 122 Jan 18 08:42 ..
drwxr-xr-x 2 postgres postgres   6 Jan 18 08:42 tbs_shop

-bash-4.2$ psql
psql (11.5)
Type "help" for help.

postgres=# \db+
                                  List of tablespaces
    Name    |  Owner   | Location | Access privileges | Options |  Size  | Description 
------------+----------+----------+-------------------+---------+--------+-------------
 pg_default | postgres |          |                   |         | 23 MB  | 
 pg_global  | postgres |          |                   |         | 574 kB | 
(2 rows)

postgres=# create tablespace tbs_shop location '/var/lib/pgsql/tablespace/tbs_shop';
CREATE TABLESPACE
postgres=# 
postgres=# \db+
                                               List of tablespaces
    Name    |  Owner   |              Location              | Access privileges | Options |  Size   | Description 
------------+----------+------------------------------------+-------------------+---------+---------+-------------
 pg_default | postgres |                                    |                   |         | 23 MB   | 
 pg_global  | postgres |                                    |                   |         | 574 kB  | 
 tbs_shop   | postgres | /var/lib/pgsql/tablespace/tbs_shop |                   |         | 0 bytes | 
(3 rows)
```

#### 6-3. 데이터베이스 생성 ####

```
postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)

postgres=# create database shop_db owner = shop tablespace = tbs_shop;
CREATE DATABASE

postgres=# \l+
                                                                    List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   |  Size   | Tablespace |                Description                 
-----------+----------+----------+-------------+-------------+-----------------------+---------+------------+--------------------------------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |                       | 7973 kB | pg_default | default administrative connection database
 shop_db   | shop     | UTF8     | en_US.UTF-8 | en_US.UTF-8 |                       | 7833 kB | tbs_shop   | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +| 7833 kB | pg_default | unmodifiable empty database
           |          |          |             |             | postgres=CTc/postgres |         |            | 
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +| 7833 kB | pg_default | default template for new databases
           |          |          |             |             | postgres=CTc/postgres |         |            | 
(4 rows)
```

#### 6-4. 외부 접속 설정 ####

postgres 는 기본적으로 로컬 접속만 허용하기 때문에 외부에서 접속하기 위해서는 2가지의 수정 사항이 필요한다.

* /var/lib/pgsql/data/postgresql.conf

```
listen_addresses = '*'
```

* /var/lib/pgsql/data/pg_hba.conf

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             shop  					            md5            <--- 추가
local   all             all                                     peer

# IPv4 local connections:
host    all             all             127.0.0.1/32            ident

# IPv6 local connections:
host    all             all             ::1/128                 ident

# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            ident
host    replication     all             ::1/128                 ident

host    all             all             0.0.0.0/0               md5            <--- 추가
```

두개의 설정 파일을 위와 같이 수정한 후, 아래 명령어를 이용하여 postgresql 서버를 재시작한다. 

```
[ec2-user@ip-172-31-42-82 ~]$ sudo systemctl restart postgresql
[ec2-user@ip-172-31-42-82 ~]$ sudo systemctl status postgresql
● postgresql.service - PostgreSQL database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql.service; enabled; vendor preset: disabled)
   Active: active (running) since 월 2021-01-18 09:02:59 UTC; 8s ago
  Process: 18142 ExecStartPre=/usr/libexec/postgresql-check-db-dir %N (code=exited, status=0/SUCCESS)
 Main PID: 18145 (postmaster)
   CGroup: /system.slice/postgresql.service
           ├─18145 /usr/bin/postmaster -D /var/lib/pgsql/data
           ├─18147 postgres: logger   
           ├─18149 postgres: checkpointer   
           ├─18150 postgres: background writer   
           ├─18151 postgres: walwriter   
           ├─18152 postgres: autovacuum launcher   
           ├─18153 postgres: stats collector   
           └─18154 postgres: logical replication launcher   
```

### 7. 오라클 데이터 로딩 ###

#### 7-1. 스키마 생성하기 ####

소스 DB 인 오라클데이터베이스에 실습용 스키마를 생성하고, 샘플 데이터를 로딩하기 위해서 tf_loadgen 서버로 로그인 한 후,  
아래 명령어를 실행한다. 

```
(base) f8ffc2077dc2:~ soonbeom$ ssh -i ~/.ssh/tf_key ec2-user@3.34.179.8

[ec2-user@ip-172-31-37-6 ~]$ cd pyoracle
[ec2-user@ip-172-31-37-6 pyoracle]$ sh create-schema.sh 
find and replace oracle ip ... /home/ec2-user/oracle/tnsnames.ora
find and replace oracle ip ... /home/ec2-user/pyoracle/config.ini

SQL*Plus: Release 21.0.0.0.0 - Production on Mon Jan 25 08:16:52 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production


Tablespace dropped.


Tablespace created.


User dropped.


User created.


Grant succeeded.


Sequence created.


Sequence created.


Sequence created.


Table created.


Table created.


Index created.


Table created.


Index created.


Table created.


Table created.

SQL> 
```

#### 7-2. 샘플 데이터 생성 및 확인하기 ####

pyoracle.py 파이썬 프로그램을 아래와 같이 실행한다.

[샘플 데이터 생성]
```
[ec2-user@ip-172-31-37-6 pyoracle]$ pwd
/home/ec2-user/pyoracle
[ec2-user@ip-172-31-37-6 pyoracle]$ python3 pyoracle.py 
ORACLE_DB_URL: shop/shop@172.31.32.20:1521/xe
DATA_PATH" /home/ec2-user/pyoracle/images
PRODUCT_DESCRIPTION_HTML_PATH: /home/ec2-user/pyoracle/images/product_body.html
DEFAULT_PRODUCT_COUNT: 1000
DEFAULT_ORDER_COUNT: 1000000
loading product table... 
```

오라클 서버로 로그인해서 데이터가 제대로 생성되는 지 확인한다 . 

[데이터 생성 확인]
```
SQL> select count(1) from shop.tb_product;
SQL> select count(1) from shop.tf_order;
```



### 8. DMS 설정 ###

DMS 를 이용하여 CDC 방식으로 데이터를 복제하기 위해서는 리플리케이션 인스턴스와 엔드포인트 그리고 데이터베이스 마이그레이션 태스크가 필요하다. 
리플리케이션 인스턴스는 데이터 복제시에 AWS 클라우드 상에 생성되는 복제 전용 서버로 원본 데이터베이스의 트랜잭션 량에 따라서 인스턴스의 크기와 EBS 볼륨의 크기를 설정하면 된다.  
엔드포인트의 경우 소스 및 타켓 데이터베이스에 접속하기 위한 설정으로 오라클의 경우 로그 마이너 방식과 바이너리 리더 방식을 지원하고 있다.  
이 예제에서는 오라클용 엔드 포인트를 로그 마이너용 1개와 바이너리 리더용 1개를 각각 만들게 된다. 이와는 달리 postgres 용 엔드포인트는 하나만을 만들게 된다.
엔드 포인트 설정갑 중 extra_connection_attributes 의 값이 로그마이너 용인 경우 설정하지 않고, 바이너리 모드인 경우에는 "useLogminerReader=N; useBfile=Y" 로 설정하게 된다.

본 실습에서는 CDC 복제에 필요한 리플리케이션 인스턴스 2대와 오라클 및 postgres 용 엔드포인트는 테라폼을 이용하여 자동으로 빌드하는데, 세부적인 설정 내용에 대해서는
테라폼 HCL 설정값을 확인하도록 한다. 물론 AWS Console 상에서 UI 를 이용한 수동 설정 역시 가능하다.

#### 8.1 테라폼이 생성한 리소스 확인 ####

DMS 인스턴스와 소스 및 타켓 데이터베이스에 대한 엔드포인트는 테라폼에 의해 자동으로 생성된다. 아래는 생성된 DMS 인스턴스와 엔드포인트에 대한 결과 화면이다. 

![rep-instance](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-replication-instnace.png)

![rep-endpoint](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-endpoint.png)


#### 8.2 엔드포인트 접속 테스트 ####

자동으로 생성된 엔드포인트에 대한 접속 테스트를 아래와 같이 실행한다. 

![endpoint test](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-endpint-test.png)


#### 8.3 마이그레이션 태스크 설정 ####

마이그레이션 태스크 설정은 3단계로 구성되는 태스크 설정과 태스크 셋팅 그리고 태스크 매핑이다. 본 워크샵에서 다양한 형태의 데이터 타입에 대한 마이그레이션
테스트로 구성되어지는데, 상품(TB_PRODUCT) 테이블의 경우 상품 이미지를 저장하는 BLOB 및 상품 설명 본문을 저장하기 위해 CLOB 칼럼을 사용하고 있다.

테이블 매핑과 관련해서 오라클의 경우 태이블, 칼럼과 같은 스키마의 명칭에 대소문자를 가리지 않은 것에 반해, postgresql 의 경우 명시적으로 Quote를 사용하여 테이블 또는 칼럼을 만드는 경우 대소문자를
구분하게 된다. SCT 를 사용하지 않고 DMS 만을 사용하여 매핑을 설정하는 경우, DMS 가 자동으로 데이터 타입을 인지하여 스키마를 만들게 되는데, 스키마 생성시 Quote("") 를
사용하기 때문에 postgres 입장에서는 대소문자를 구분짓게 되는 것이다.

마이그레이션 태스트 매핑 설정시 스미카, 테이블 및 칼럼 명칭에 대헛 lower case 매핑룰을 설정해서 이러한 문제를 사전에 방지해야 한다. lower case 룰을 설정하지 않는 경우
postgresql 클라이언트를 사용하여 테이블에 대한 데이터 입력 및 조회시 쌍따옴표를 이용하여 오브젝트 명칭을 감싸줘야 제대로 SQL 이 에러없이 동작하게 된다. 

아래의 내용은 참고하여 마이그레이션 태스크 설정을 수행한다. 

![task-configuration](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-task-configuration.png)
![task-setting]https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-task-setting.png
![task-mapping](https://github.com/gnosia93/postgres-terraform/blob/main/images/dms-task-table-mapping.png)








- binary reader

- log miner


### 9. DMS 모니터링하기 ###














