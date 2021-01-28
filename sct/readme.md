본 튜토리얼에서 SCT 를 사용하여 사전 스키마 매핑 작업을 수행하지 않고, DMS 자체의 스키마 생성 및 변환 기능만을 이용하여 데이터를 이관하였다.
이관이후, 자동으로 생성된 테이블에 대한 메타 정보를 확인하기 위해서는 pgadmin 과 같은 클라이언트 툴을 사용하여거나, postgresql 의 카탈로그를 이용하여
원하는 정보를 조회할 수 있다.


## 1. 데이터 타입 매핑 ##

오라클의 데이터타입은 postgresql 전환시 아래와 같은 규칙으로 매핑된다.

### 숫자형 ###
* number(4) --> smallint
* number(9) --> int
* number(19,3) --> numeric(19,3)
* number --> numeric(38,10)

### 문자형 ###
* char(n) -->
* varchar2(4000) --> character varying(4000)
* clob --> text

### 날짜형 ###
* date --> timestamp


### 1-1. pgadmin 을 이용한 정보 조회 ###

![pgadmin schema](https://github.com/gnosia93/postgres-terraform/blob/main/images/pgadmin-schema-table.png)

### 1-2. postgresql 카탈로그 이용하기 ###

```
(base) f8ffc2077dc2:~ soonbeom$ ssh -i ~/.ssh/tf_key ec2-user@3.36.16.13
Last login: Wed Jan 27 23:25:04 2021 from 218.238.107.63

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
No packages needed for security; 2 packages available
Run "sudo yum update" to apply all updates.
[ec2-user@ip-172-31-16-173 ~]$ sudo su - postgres
마지막 로그인: 수  1월 27 23:25:17 UTC 2021 일시 pts/0
-bash-4.2$ psql
psql (11.5)
Type "help" for help.

postgres=# \c shop_db
You are now connected to database "shop_db" as user "postgres".

shop_db=# select table_catalog, table_schema, table_name, shop_db-# column_name, ordinal_position, shop_db-# column_default, is_nullable, 
shop_db-# data_type, character_maximum_length, shop_db-# numeric_precision, numeric_scale, shop_db-# udt_name
shop_db-# from information_schema.columns
shop_db-# where table_name = 'tb_product';
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
postgresql의 경우 오라클 달리 5개의 제약조건만 지원하고 Default 에 대한 지원은 하지 않는다. 

https://www.postgresql.org/docs/9.3/ddl-constraints.html


예를 들어, tb_product 테이블의 경우 comment_cnt, buy_cnt, display_yn, reg_ymdt 칼럼에 대해서 default 값을 수동으로 입력해 주어야 한다. 
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

아래와 같이 default 값을 추가적으로 입혁해 주기 위해서 postgresql 의 테이블을 alter 시켜줘야 한다. 
```
alter table tb_product alter column comment_cnt set default 0;
alter table tb_product alter column buy_cnt set default 0;
alter table tb_product alter column display_yn set default 'Y';
alter table tb_product alter column reg_ymdt set default now();
```

---

마이그레이션 작업 수행이전에 타겟 데이터베이스인 postgresql에 스키마를 생성하고자 하는 경우 AWS SCT 를 이용하여 스키마 매핑 및 원하는 형태의 스키마로 수정할 수 있으며, 이와 관련된 내용은 AWS 메뉴얼(https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html) 을 참고하길 바란다.
