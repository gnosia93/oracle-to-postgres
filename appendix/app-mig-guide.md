## 어플리케이션 변환 가이드 ##



### ROWID, CTID and Identity columns ###

- Oracle 에서 ROWID 는 테이블의 행 주소를 반환하는 Peudo 칼럼(유니크함). 
- PostgreSQL에는 트랜잭션ID 를 관리하기 위한 CTID 라고하는 내부 칼럼이 있으나 VACUUM 기능 후에 CTID가 변경됨 (CTID 는 4byte)/
- Identity를 이용하여 ROWID 칼럼 생성.



[oracle]
```
sql> select rowid, order_no, order_price from shop.tb_order;
ROWID              ORDER_NO             ORDER_PRICE
------------------ -------------------- -----------
AAAR1oAAOAAAV/jAAA 20210202000000000061        2000
AAAR1oAAOAAAV/jAAB 20210202000000000068        4000
AAAR1oAAOAAAV/jAAC 20210202000000000060        5000
AAAR1oAAOAAAV/jAAD 20210202000000000074        5000
AAAR1oAAOAAAV/jAAE 20210202000000000087        4000
```
[postgresql]
```
create table tb_order2
(
   order_no       varchar(20) not null primary key,
   order_price    decimal(19,3) not null,
   rowid	  bigint GENERATED ALWAYS AS IDENTITY
);

insert into tb_order2(order_no, order_price) 
select order_no, order_price from shop.tb_order;

select ROWID, order_no, order_price from tb_order2;
```











-------------

* https://www.pgcon.org/2008/schedule/track/Tutorial/62.en.html
------
* https://wiki.postgresql.org/wiki/Converting_from_other_Databases_to_PostgreSQL#Oracle


-------------


* SQL변환 가이드

  - 데이터타입 비교.
  - SQL syntax 비교
  - query.


;  https://uple.net/1601

* 오브젝트 변환가이드.

- 오라클과 오브젝트 비교..


## 레퍼런스 ##

https://www.enterprisedb.com/blog/the-complete-oracle-to-postgresql-migration-guide-tutorial-move-convert-database-oracle-alternative?gclid=CjwKCAiAouD_BRBIEiwALhJH6EYfjIYgfljHPqXSBbnmgypKWRxzegJ7hbYfSb_vAxrj2ywcVu1C7xoCOpwQAvD_BwE&utm_campaign=Q42020_APAC&utm_medium=cpc&utm_source=google
