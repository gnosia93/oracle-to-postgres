## postgres 설정 ##

postgresql 은 default 로 로컬 접속만을 허용한다. 외부에서 접속하고자 하는 경우 아래와 같이 설정 파일 2개를 수정해야 한다.   
또한 DMS 를 이용하여 오라클 데이터베이스의 변경 데이터를 복제하기 위해서는 postgresql 역시 데이터베이스, 테이블스페이스 및 접속 유저에 대한 설정이 필요하다.   
postgresql는 여러개의 작은 데이터베이스들로 구성이 되어져 있으며, 각각의 데이터베이스는 동일한 인스턴스에 의해 관리되지만, 실제로는 완전히 분리된 데이터베이스로
생각해야 하며, 서로 다른 데이터베이스 테이블간의 조인은 불가능하다.
오라클 12c 부터는 경우 PDB, CDB 구조로 되어 있어 postgresql 와 비슷한 데이터베이스 구조로 설계되어 있지만, 오라클 11g 의 겨우
하나의 데이터베이스로 설계되어져 있어서, postgresql 전환시 하나의 데이터베이스 매핑 되도록 해야 한다. 

이 단계에서는 타켓 데이터베이스인 postgres 에서 사용할 유저와 데이터베이스, 테이블스페이스 및 유저를 생성하고, 외부 접속을 위한 설정파일을 수정할 예정이다. 
또한 외부 접속을 위한 설정이 완료된 후, pgadmin 을 이용하여 외부에서 접속 테스트를 수행할 예정이다. 

### 유저 생성 ###

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

### 테이블스페이스 생성 ###

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

### 데이터베이스 생성 ###

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

