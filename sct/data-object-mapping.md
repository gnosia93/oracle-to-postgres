본 튜토리얼에서 SCT 를 사용하여 사전 스키마 매핑 작업을 수행하지 않고, DMS 자체의 스키마 생성 및 변환 기능만을 이용하여 데이터를 이관하였다.

## 1. 데이터 타입 매핑 ##

DMS 의 자동 스키마 생성 기능을 이용하는 경우, 오라클의 데이터타입은 postgresql 전환시 아래와 같은 규칙으로 자동 매핑된다.
오라클의 테이블이 NCLOB, LONG 및 BFILE 같은 칼럼을 가지고 있는 경우, 자동 매핑되지 않고, 복제 대상에서 제외되니 주의가 필요하다. (DMS 로그에 warning 으로만 표시됨)

### 숫자형 ###
       number(4) --> smallint
       number(9) --> int
       number(10) --> numeric(10,0)
       number(30) --> numeric(30,0)
       number(19,3) --> numeric(19,3)
       number --> numeric(38,10)
       float --> double precision
       float(n) --> double precision
       
### 문자형 ###
       char(n) --> character varying(n)
       varchar2(4000) --> character varying(4000)
       clob --> text

### binary ###
       blob --> bytea

### 날짜형 ###
       date --> timestamp
       timestamp --> timestamp

DMS 에 의해 자동으로 매핑 및 생성된 테이블 정보는 다음과 같은 방법을 이용하여 테이블별 메타 데이터를 조회해 볼 수 있다.  

### 1-1. Pgadmin4 로 테이블 메타 데이터 조회 ###

![pgadmin schema](https://github.com/gnosia93/postgres-terraform/blob/main/images/pgadmin-schema-table.png)

### 1-2. postgresql 카탈로그 이용하기 ###

```
shop_db=# select table_catalog, table_schema, table_name, 
          column_name, ordinal_position, column_default, is_nullable, 
          data_type, character_maximum_length, 
          numeric_precision, numeric_scale, udt_name
          from information_schema.columns
          where table_name = 'tb_product';
          
 table_catalog | table_schema | table_name |   column_name   | ordinal_position | column_default | is_nullable |          data_type          | character_maximum_length | numeric_precision | numeric_scale | udt_name  
---------------+--------------+------------+-----------------+------------------+----------------+-------------+-----------------------------+--------------------------+-------------------+---------------+-----------
 shop_db       | shop         | tb_product | product_id      |                1 |                | NO          | integer                     |                          |                32 |             0 | int4
 shop_db       | shop         | tb_product | category_id     |                2 |                | NO          | smallint                    |                          |                16 |             0 | int2
 shop_db       | shop         | tb_product | name            |                3 |                | NO          | character varying           |                      100 |                   |               | varchar
 shop_db       | shop         | tb_product | price           |                4 |                | NO          | numeric                     |                          |                19 |             3 | numeric
 shop_db       | shop         | tb_product | description     |                5 |                | YES         | text                        |                          |                   |               | text
 shop_db       | shop         | tb_product | image_data      |                6 |                | YES         | bytea                       |                          |                   |               | bytea
 shop_db       | shop         | tb_product | thumb_image_url |                7 |                | YES         | character varying           |                      300 |                   |               | varchar
 shop_db       | shop         | tb_product | image_url       |                8 |                | YES         | character varying           |                      300 |                   |               | varchar
 shop_db       | shop         | tb_product | delivery_type   |                9 |                | NO          | character varying           |                       10 |                   |               | varchar
 shop_db       | shop         | tb_product | comment_cnt     |               10 |                | NO          | integer                     |                          |                32 |             0 | int4
 shop_db       | shop         | tb_product | buy_cnt         |               11 |                | NO          | integer                     |                          |                32 |             0 | int4
 shop_db       | shop         | tb_product | display_yn      |               12 |                | YES         | character varying           |                        1 |                   |               | varchar
 shop_db       | shop         | tb_product | reg_ymdt        |               13 |                | NO          | timestamp without time zone |                          |                   |               | timestamp
 shop_db       | shop         | tb_product | upd_ymdt        |               14 |                | YES         | timestamp without time zone |                          |                   |               | timestamp
(14 rows)
```


## 2. 제약조건 ##

오라클은 6가지 제약조건을 지원하는데, Primary Key, UNIQUE, Foreign Key, NOT NULL, CHECK, Default 타입의 제약조건을 지원한다. 이에 반해 
postgresql의 경우 오라클 달리 5개의 제약조건만 지원하고 Default 제약조건은 지원하지 않는다. 대신 칼럼에 대한 default 값 설정 형태로 지원된다. 

https://www.postgresql.org/docs/9.3/ddl-constraints.html


아래는 원본 데이터베이스인 오라클 데이터 베이스에 tb_product 을 생성할때 사용된 스크립트로, comment_cnt, buy_cnt, display_yn, reg_ymdt 칼럼에 default 제약조건이 설정되어 있는것을 확인할 수 있다. 
```
create table shop.tb_product 
(
   product_id         number(9) not null,
   category_id        number(4) not null,
   name               varchar2(100) not null,
   price              number(19,3) not null,,
   description        clob,
   image_data         blob,
   thumb_image_url    varchar2(300),
   image_url          varchar2(300),
   delivery_type      varchar2(10) not null,
   comment_cnt        number(9) default 0 not null,
   buy_cnt            number(9) default 0 not null,
   display_yn         char(1) default 'Y',
   reg_ymdt           date default sysdate not null,
   upd_ymdt           date,
   primary key(product_id)
);
```

DMS 에 의해 postgresql 데이터베이스로 변환된 테이블의 메타 정보를 조회해 보면 아래와 같이 default 제약조건이 존재하지 않음을 확인할 수 있다. 
```
CREATE TABLE shop.tb_product
(
    product_id integer NOT NULL,
    category_id smallint NOT NULL,
    name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    price numeric(19,3) NOT NULL,
    description text COLLATE pg_catalog."default",
    image_data bytea,
    thumb_image_url character varying(300) COLLATE pg_catalog."default",
    image_url character varying(300) COLLATE pg_catalog."default",
    delivery_type character varying(10) COLLATE pg_catalog."default" NOT NULL,
    comment_cnt integer NOT NULL,
    buy_cnt integer NOT NULL DEFAULT 0,
    display_yn character varying(1) COLLATE pg_catalog."default",
    reg_ymdt timestamp without time zone NOT NULL DEFAULT now(),
    upd_ymdt timestamp without time zone,
    CONSTRAINT tb_product_pkey PRIMARY KEY (product_id)
        USING INDEX TABLESPACE tbs_shop
);
```

default 제약조건은 개발시 자주 사용되는 기능이므로 아래와 같이 postgresql 테이블별의 칼럼별로 default 값을 설정해 줘야한다.  
```
alter table tb_product alter column comment_cnt set default 0;
alter table tb_product alter column buy_cnt set default 0;
alter table tb_product alter column display_yn set default 'Y';
alter table tb_product alter column reg_ymdt set default now();
```


### 3. 인덱스 ###

DMS 는 원본 테이블에 여러개의 인덱스가 있더라도 PK 인덱스만을 생성해 준다. (UK 는 생성하는가 ??)
아래와 같이 이관된 테이블의 인덱스 정보를 조회해 보면, 오라클의 원본 테이블에 존재하는 idx_product_01 인덱스는 postgresql 에서 보이지 않는다. 
이는 데이터 이관 완료 후, PK 인덱스를 제외한 나머지 인덱스를 수동으로 빌드해 줘야 함을 의미한다. 

[oracle 인덱스 정보]
```
SQL> select table_name, index_name, index_type, constraint_index from dba_indexes where table_name = 'TB_PRODUCT';

TABLE_NAME	INDEX_NAME		       INDEX_TYPE		   CON
--------------- ------------------------------ --------------------------- ---
TB_PRODUCT	SYS_IL0000073061C00005$$       LOB			   NO
TB_PRODUCT	SYS_IL0000073061C00006$$       LOB			   NO
TB_PRODUCT	SYS_C007612		       NORMAL			   YES
TB_PRODUCT	IDX_PRODUCT_01		       NORMAL			   NO
```

[postgresql 인덱스 정보]
```
shop_db=# SELECT * FROM pg_indexes WHERE tablename = 'tb_product';
 schemaname | tablename  |    indexname    | tablespace |                                    indexdef                                     
------------+------------+-----------------+------------+---------------------------------------------------------------------------------
 shop       | tb_product | tb_product_pkey |            | CREATE UNIQUE INDEX tb_product_pkey ON shop.tb_product USING btree (product_id)
(1 row)
```


---

마이그레이션 작업 수행이전에 타겟 데이터베이스인 postgresql에 스키마를 생성하고자 하는 경우 AWS SCT 를 이용하여 스키마 매핑 및 원하는 형태의 스키마로 수정할 수 있으며, 이와 관련된 내용은 AWS 메뉴얼(https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html) 을 참고하길 바란다.
