## postgres 설정 ##

데이터 마이그레이션 테스트를 위한 Postgresql 의 설정은 아래와 같이 두가지로 나뉘어 집니다.  

* DB Configuration 파일 설정

* 타겟 스키마 생성

이중 DB Configuration 파일 설정의 경우 외부 클라이언트의 접속을 허용허기 위한 것으로 postgresql.conf 와 pg_hba.conf 파일에 대한 변경이 필요한데, 테라폼 스크립트 자동으로 적용되어 있습니다.
타겟 스키마 생성의 경우 DMS 을 통해 복제된 트랜잭션 로그가 postgresql 에 적용될 때 필요한 오브젝트들로 데이터베이스, 테이블스페이스 및 유저를 생성하는 것을 의미합니다. 
postgresql는 여러개의 작은 데이터베이스들로 구성이 되어져 있으며, 각각의 데이터베이스는 동일한 인스턴스에 의해 관리되지만, 실제로는 완전히 분리된 데이터베이스로
생각해야 하며, 서로 다른 데이터베이스 테이블간의 조인은 불가능합니다. 
오라클 12c 부터는 경우 PDB, CDB 구조로 되어 있어 postgresql 와 비슷한 형태로 구현되어 있지만, 오라클 11g 의 경우 하나의 데이터베이스로 구성되어 있어, postgresql 전환시 특정 데이터베이스로 매핑될 수 있도록 해야 합니다. 

### 유저 생성 ###

postgres 의 어드민 계정인 postgres 로 로그인 하여, 일반 유저인 shop 유저를 만든 후, 

오라클의 DBA_USER 뷰에 해당하는 pg_shadow 뷰로 부터 shop 유저가 제대로 만들어 졌는지 확인한다.

```
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

### 테이블스페이스 생성 ###

데이터베이스가 테이블 스페이스를 구성하는 운영체제상의 파일을 직접 생성해 주는 오라클과는 달리, postgresql 의 경우 테이블스페이스를 생성하기 위해서는 해당 테이블스페이스가 사용하게 될 OS 상의 디렉토리를 먼저 생성해 줘야 합니다. 본 튜토리얼에서는 /var/lib/pgsql/data 디렉토리 하위에 tbs_shop 이라는 디렉토리를 만들 예정입니다. 

[디렉토리 생성]
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
```

[테이블스페이스 생성]
```
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

### 데이터베이스 생성 ###

아래와 같은 명령어를 이용하여 postgresql 에 shop_db 라는 명칭의 데이터베이스를 생성합니다. 

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

