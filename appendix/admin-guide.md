# 어드민 가이드 #

## 아키텍처 ##

## 설정파일 ##

## 기본 명령어 ##

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
select * from pg_roles;
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



## 레퍼런스 ##

* https://stricky.tistory.com/367

* https://aws.amazon.com/ko/blogs/korea/how-to-migrate-your-oracle-database-to-postgresql/

* https://github.com/experdb/eXperDB-DB2PG

* https://www.enterprisedb.com/blog/the-complete-oracle-to-postgresql-migration-guide-tutorial-move-convert-database-oracle-alternative?gclid=CjwKCAiAouD_BRBIEiwALhJH6EYfjIYgfljHPqXSBbnmgypKWRxzegJ7hbYfSb_vAxrj2ywcVu1C7xoCOpwQAvD_BwE&utm_campaign=Q42020_APAC&utm_medium=cpc&utm_source=google
