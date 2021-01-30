## 스키마 생성하기 ##

### ERD ###

워크샵에서는 아래의 ERD에 나와있는 테이블 5개와 시퀀스 3개 PK 인덱스와 더불어 추가적으로 2개의 인덱스를 생성합니다. 노란색으로 표시된 부분은 check 및 default contraint 로 postgresql 로 마이그레이션시 제약조건(constraint) 가 제대로 생성되는지 역시 확인할 예정입니다. 

![erd](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/migration-erd.png)



### DDL ###

```
create sequence shop.seq_product_product_id
start with 1 increment by 1 cache 20;

create sequence shop.seq_comment_comment_id
start with 1 increment by 1 cache 20;

create sequence shop.seq_order_order_id
start with 1 increment by 1 cache 20;

create table shop.tb_category
(
   category_id       number(4) not null primary key,
   category_name     varchar(300) not null,
   display_yn        varchar(1) default 'Y' not null
);

create table shop.tb_product
(
   product_id         number(9) not null,
   category_id        number(4) not null,
   name               varchar2(100) not null,
   price              number(19,3) not null,
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

create index shop.idx_product_01 on shop.tb_product(category_id, product_id);

create table shop.tb_comment
(
   comment_id         number not null,
   member_id          varchar2(30) not null,
   product_id         number(9) not null,
   score              varchar(1) not null,
   comment_body       varchar(4000),
   primary key(comment_id)
);

create index shop.idx_comment_01 on shop.tb_comment(member_id, comment_id);

-- order_no YYYYMMDD + serial(12자리) 어플리케이션에서 생성
create table shop.tb_order
(
   order_no                varchar2(20) not null primary key,
   member_id               varchar2(30) not null,
   order_price             number(19,3) not null,
   order_ymdt              date default sysdate,
   pay_status              varchar2(10) not null,
   pay_ymdt                date,
   error_ymdt              date,
   error_message           date,
   error_cd                varchar2(3),
   constraint check_pay_status
   check(pay_status in ('Queued', 'Processing', 'error', 'Completed'))
);

create table shop.tb_order_detail
(
   order_no                varchar2(20) not null,
   product_id              number(9),
   product_price           number(19,3) not null,
   product_cnt             number,
   primary key(order_no, product_id)
);
```


### 스키마 생성하기 ###

오라클 데이터베이스에 실습용 스키마를 생성하기 위해, tf_loadgen EC2 인스턴스로 로그인하여 아래와 명령어를 수행합니다. pyoracle 디렉토리 밑에 create-schema.sh 일 실행합니다. 

```
$ ssh -i ~/.ssh/tf_key ec2-user@<tf_loadgen IP>
Last login: Fri Jan 29 10:50:02 2021 from 218.238.107.63

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
[ec2-user@ip-172-31-34-59 ~]$ cd pyoracle
[ec2-user@ip-172-31-37-6 pyoracle]$ sh create-schema.sh 

[ec2-user@ip-172-31-34-59 pyoracle]$ sh create-schema.sh 
find and replace oracle ip ... /home/ec2-user/oracle/tnsnames.ora <11xe-oracle-private-ip> tf_oracle_11xe
find and replace oracle ip ... /home/ec2-user/oracle/tnsnames.ora <19c-oracle-private-ip> tf_oracle_19c

SQL*Plus: Release 21.0.0.0.0 - Production on Sat Jan 30 14:13:31 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production


Tablespace dropped.


Tablespace created.


User dropped.


User created.


Grant succeeded.


Sequence created.


Sequence created.


Sequence created.


Table created.


Table created.


Index created.


Table created.


Index created.


Table created.


Table created.

Disconnected from Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production

SQL*Plus: Release 21.0.0.0.0 - Production on Sat Jan 30 14:13:36 2021
Version 21.1.0.0.0

Copyright (c) 1982, 2020, Oracle.  All rights reserved.

Last Successful login time: Fri Jan 29 2021 11:40:02 +00:00

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0


Session altered.


Tablespace dropped.


Tablespace created.


User dropped.


User created.


Grant succeeded.


Sequence created.


Sequence created.


Sequence created.


Table created.


Table created.


Index created.


Table created.


Index created.


Table created.


Table created.

Disconnected from Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0
find and replace oracle ip ... /home/ec2-user/pyoracle/config.ini <11xe-oracle-private-ip> tf_oracle_11xe
ORACLE_11XE_URL = shop/shop@<11xe-oracle-private-ip>:1521/xe
finding oracle ec2 private ip ....
find and replace oracle ip ... /home/ec2-user/pyoracle/config.ini <19c-oracle-private-ip> tf_oracle_19c
ORACLE_19C_URL = shop/shop@<19c-oracle-private-ip>:1521/pdb1
finding oracle ec2 private ip ....
```
