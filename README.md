# Oracle2Postgres Migration Workshop #

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

### 8. DMS 태스크 설정 ###

- binary reader

- log miner


### 9. DMS 모니터링하기 ###














