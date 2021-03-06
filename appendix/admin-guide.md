## 아키텍처 ##

![architecture](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/images/Architect%20Postgresql.png)

![server](https://github.com/gnosia93/postgres-terraform/blob/main/appendix/images/Postgresql%20Server.png)


## 설정파일 (예시) ##

### postgres.conf ###

```
#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -
listen_addresses = '*'
port = 3000
max_connections = 1000

#------------------------------------------------------------------------------
# RESOURCE USAGE (except WAL)
#------------------------------------------------------------------------------

# - Memory -
shared_buffers = 1024MB    
work_mem = 4MB   
maintenance_work_mem = 512MB 

dynamic_shared_memory_type = posix
effective_io_concurrency = 200

max_worker_processes=8
max_parallel_workers_per_gather = 2
max_parallel_workers = 8

#------------------------------------------------------------------------------
# WRITE AHEAD LOG
#------------------------------------------------------------------------------

# - Settings -
wal_level = logical
wal_buffers = 2MB
max_wal_size = 1GB

# - Archiving -
archive_mode = on
archive_command = 'cp %p /home/ec2-user/arch/%f'

#------------------------------------------------------------------------------
# QUERY TUNING
#------------------------------------------------------------------------------

random_page_cost = 1.1
default_statistics_target = 100
effective_cache_size = 3GB   # max. Physical M * 0.75

#------------------------------------------------------------------------------
# ERROR REPORTING AND LOGGING
#------------------------------------------------------------------------------

# - Where to Log -
log_destination = 'stderr'
logging_collector = on
log_filename = 'alert_db.log'

# - What to Log -
log_line_prefix = '%t '

#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------

# - Statement Behavior -
search_path = '"$user"'
temp_tablespaces = 'TS_TEMP'

timezone='Asia/Seoul'
lc_messages = 'en_US.UTF-8' 
lc_monetary = 'en_US.UTF-8' 
lc_numeric = 'en_US.UTF-8' 
lc_time = 'en_US.UTF-8' 
default_text_search_config = 'pg_catalog.english'
```

### pg_hba.conf ####
postgresql 접속 인증 관련 설정으로 oracle 의 sqlnet.ora 에 해당.
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
```



## 기본 명령어 ##


## psql 사용법 ##

* https://browndwarf.tistory.com/51

* https://brownbears.tistory.com/category/DB/PostgreSQL

## CRUD / Index 생성 ##



### 데이터 디렉토리 조회 ###

```
postgres=# show data_directory;
   data_directory    
---------------------
 /var/lib/pgsql/data
(1 row)
```

### 데이터 사이즈 조회 ###
```
postgres=# select pg_database_size('shop_db');
 pg_database_size 
------------------
      15937761951
(1 row)
```

## 카탈로그 정보 조회 ##

postgres 데이터베이스 역시 오라클의 fixed 또는 동적 뷰에 해당하는 시스템 카탈로그 및 뷰를 지원하고 있으며, 이를 통해 여러가지 데이터베이스 오브젝트 정보를 조회할 수 있습니다. 

```
pg_class : 테이블, 인덱스, 시퀀스, 뷰
pg_constraint : 제약조건
pg_database : 해당 클러스터에 속한 데이터베이스
pg_extension : 설치된 extension
pg_index : 상세 인덱스
pg_namespace : 스키마
pg_tablespace : 해당 클러스터에 속한 데이터베이스

pg_available_extensions : 사용 가능한 extension
pg_file_settings : 파일 컨텐츠 구성 요약
pg_grouop : 데이터베이스 사용자 그룹
pg_indexes : 인덱스
pg_roles : 데이터베이스 롤
pg_settings : 구성 파라미터
pg_shadow : 데이터베이스 사용자
pg_stats : 플래너 통계
pg_tables : 테이블
pg_timezone_name : 타임존 명
pg_user : 데이터베이스 사용자
pg_views : 뷰
```


### 사용자 조회 ###

```
psql> select * from pg_roles;
          rolname          | rolsuper | rolinherit | rolcreaterole | rolcreatedb | rolcanlogin | rolreplication | rolconnlimit | rolpassword | rolvaliduntil | rolbypassrls | rolconfig |  oid  
---------------------------+----------+------------+---------------+-------------+-------------+----------------+--------------+-------------+---------------+--------------+-----------+-------
 pg_signal_backend         | f        | t          | f             | f           | f           | f              |           -1 | ********    |               | f            |           |  4200
 pg_read_server_files      | f        | t          | f             | f           | f           | f              |           -1 | ********    |               | f            |           |  4569
 postgres                  | t        | t          | t             | t           | t           | t              |           -1 | ********    |               | t            |           |    10
 pg_write_server_files     | f        | t          | f             | f           | f           | f              |           -1 | ********    |               | f            |           |  4570
 pg_execute_server_program | f        | t          | f             | f           | f           | f              |           -1 | ********    |               | f            |           |  4571
 pg_read_all_stats         | f        | t          | f             | f           | f           | f              |           -1 | ********    |               | f            |           |  3375
 pg_monitor                | f        | t          | f             | f           | f           | f              |           -1 | ********    |               | f            |           |  3373
 shop                      | f        | t          | f             | f           | t           | f              |           -1 | ********    |               | f            |           | 16384
 pg_read_all_settings      | f        | t          | f             | f           | f           | f              |           -1 | ********    |               | f            |           |  3374
 pg_stat_scan_tables       | f        | t          | f             | f           | f           | f              |           -1 | ********    |               | f            |           |  3377
(10 rows)
```

```
psql> select * from pg_shadow;
 usename  | usesysid | usecreatedb | usesuper | userepl | usebypassrls |               passwd                | valuntil | useconfig 
----------+----------+-------------+----------+---------+--------------+-------------------------------------+----------+-----------
 postgres |       10 | t           | t        | t       | t            |                                     |          | 
 shop     |    16384 | f           | f        | f       | f            | md5f0c1de5eb2934ac9f886a646a0a46ba4 |          | 
```

### 데이터베이스 ###
```
select * from pg_database;
```

### 테이블 스페이스 ###
```
select * from pg_tablespace;
```

### 제약조건 ###
* https://www.postgresql.org/docs/9.3/ddl-constraints.html
```
select t.relname, t.relpages, t.reltuples,
	c.conrelid, c.confrelid, c.conname, c.contype, c.consrc 
from pg_class t inner join pg_roles r on t.relowner = r.oid
	        left outer join pg_constraint c on t.oid = c.conrelid
where r.rolname = 'shop' 
  and t.relkind = 'r'      -- v means ordinary view
  and t.relname like 'tb_%';	
```


### 인덱스 ###

* https://blog.gaerae.com/2015/09/postgresql-index.html

* 인덱스 리스트 조회
```
SELECT * FROM pg_indexes;
```


### 뷰 ###

* 뷰 리스트 조회
```
select * fromselect t.relname, t.relpages, t.reltuples,
	c.conrelid, c.confrelid, c.conname, c.contype, c.consrc 
from pg_class t inner join pg_roles r on t.relowner = r.oid
	        left outer join pg_constraint c on t.oid = c.conrelid
where r.rolname = 'shop' 
  and t.relkind = 'v'      -- r means ordinary table
  and t.relname like 'view_%';	
````
* 뷰 Definition 조회
```
select definition from pg_views where viewname = 'view_recent_order_30';
```

### 프로시저 / 함수 ###

* PostgreSQL 11 이하
```
select n.nspname as function_schema,
       p.proname as function_name,
       l.lanname as function_language,
       case when l.lanname = 'internal' then p.prosrc
            else pg_get_functiondef(p.oid)
            end as definition,
       pg_get_function_arguments(p.oid) as function_arguments,
       t.typname as return_type
from pg_proc p
left join pg_namespace n on p.pronamespace = n.oid
left join pg_language l on p.prolang = l.oid
left join pg_type t on t.oid = p.prorettype 
where n.nspname not in ('pg_catalog', 'information_schema', 'aws_oracle_ext')
order by function_schema,
         function_name;
```
* PostgreSQL 11 이상
```
select n.nspname as schema_name,
       p.proname as specific_name,
       case p.prokind 
            when 'f' then 'FUNCTION'
            when 'p' then 'PROCEDURE'
            when 'a' then 'AGGREGATE'
            when 'w' then 'WINDOW'
            end as kind,
       l.lanname as language,
       case when l.lanname = 'internal' then p.prosrc
            else pg_get_functiondef(p.oid)
            end as definition,
       pg_get_function_arguments(p.oid) as arguments,
       t.typname as return_type
from pg_proc p
left join pg_namespace n on p.pronamespace = n.oid
left join pg_language l on p.prolang = l.oid
left join pg_type t on t.oid = p.prorettype 
where n.nspname not in ('pg_catalog', 'information_schema', 'aws_oracle_ext')
order by schema_name,
         specific_name;
```


### 트리거 ###
```
select event_object_schema as table_schema,
       event_object_table as table_name,
       trigger_schema,
       trigger_name,
       string_agg(event_manipulation, ',') as event,
       action_timing as activation,
       action_condition as condition,
       action_statement as definition
from information_schema.triggers;
```

### 실행중인 SQL 조회 ###

```
select * from pg_stat_activity order by query_start asc;
```


## 레퍼런스 ##

* https://www.db-book.com/db7/online-chapters-dir/32.pdf

* https://waspro.tistory.com/146?category=826974

* https://stricky.tistory.com/367

* https://aws.amazon.com/ko/blogs/korea/how-to-migrate-your-oracle-database-to-postgresql/

* https://github.com/experdb/eXperDB-DB2PG

* https://www.enterprisedb.com/blog/the-complete-oracle-to-postgresql-migration-guide-tutorial-move-convert-database-oracle-alternative?gclid=CjwKCAiAouD_BRBIEiwALhJH6EYfjIYgfljHPqXSBbnmgypKWRxzegJ7hbYfSb_vAxrj2ywcVu1C7xoCOpwQAvD_BwE&utm_campaign=Q42020_APAC&utm_medium=cpc&utm_source=google


* https://blog.daum.net/initdb/category/PostgreSQL/PG.-%20Configuration

* https://sungthcom.tistory.com/entry/%EA%B4%80%EB%A6%AC%EC%9E%90%EA%B0%80-%EC%95%8C%EC%95%84%EC%95%BC-%ED%95%A0-Postgresql

* https://momjian.us/main/writings/pgsql/administration.pdf

* https://postgresql.kr/docs/9.6/admin.html

* https://m.blog.naver.com/PostView.nhn?blogId=geartec82&logNo=221144534637&proxyReferer=https:%2F%2Fwww.google.com%2F
