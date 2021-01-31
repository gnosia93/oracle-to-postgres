## 어드민 가이드 ##

### 사용자 조회 ###

```
select * from pg_roles;
```


### 제약조건 ###

```
select t.relname, t.relpages, t.reltuples,
	c.conrelid, c.confrelid, c.conname, c.contype, c.consrc 
from pg_class t inner join pg_roles r on t.relowner = r.oid
	        left outer join pg_constraint c on t.oid = c.conrelid
where r.rolname = 'shop' 
  and t.relkind = 'r'      -- r means ordinary table
  and t.relname like 'tb_%';	
```


### 인덱스 ###

* https://blog.gaerae.com/2015/09/postgresql-index.html



### postgres 시스템 카탈로그 / 뷰 ###

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


## 레퍼런스 ##

* https://stricky.tistory.com/367

* https://aws.amazon.com/ko/blogs/korea/how-to-migrate-your-oracle-database-to-postgresql/

* https://github.com/experdb/eXperDB-DB2PG

* https://www.enterprisedb.com/blog/the-complete-oracle-to-postgresql-migration-guide-tutorial-move-convert-database-oracle-alternative?gclid=CjwKCAiAouD_BRBIEiwALhJH6EYfjIYgfljHPqXSBbnmgypKWRxzegJ7hbYfSb_vAxrj2ywcVu1C7xoCOpwQAvD_BwE&utm_campaign=Q42020_APAC&utm_medium=cpc&utm_source=google
