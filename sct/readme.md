본 튜토리얼에서 SCT 를 사용하여 사전 스키마 매핑 작업을 수행하지 않고, DMS 자체의 스키마 생성 및 변환 기능만을 이용하여 데이터를 이관하였다.
이관이후, 자동으로 생성된 테이블에 대한 메타 정보를 확인하기 위해서는 pgadmin 과 같은 클라이언트 툴을 사용하여거나, postgresql 의 카탈로그를 이용하여
원하는 정보를 조회할 수 있다.

### 1. pgadmin 을 이용한 정보 조회 ###

![pgadmin schema](https://github.com/gnosia93/postgres-terraform/blob/main/images/pgadmin-schema-table.png)

### 2. postgresql 카탈로그 이용하기 ###

```
postgres=# \c shop_db
You are now connected to database "shop_db" as user "postgres".
shop_db=# select table_catalog, table_schema, table_name,
shop_db-# column_name, ordinal_position,
shop_db-# column_default, is_nullable, 
shop_db-# data_type, character_maximum_length,
shop_db-# numeric_precision, numeric_scale,
shop_db-# udt_name
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


---

마이그레이션 작업 수행이전에 타겟 데이터베이스인 postgresql에 스키마를 생성하고자 하는 경우 AWS SCT 를 이용하여 스키마 매핑 및 원하는 형태의 스키마로 수정할 수 있으며, 이와 관련된 내용은 AWS 메뉴얼(https://docs.aws.amazon.com/SchemaConversionTool/latest/userguide/CHAP_Welcome.html) 을 참고하길 바란다.
