## 스키마 생성하기 ##

### ERD ###

워크샵에서는 아래의 ERD에 나와있는 오브젝트를 소스 데이터베이스인 오라클 DB에 생성합니다. 노란색으로 표시된 부분은 check 및 default contraint 로 postgresql 로 마이그레이션시 제약조건(constraint) 가 제대로 생성되는지 역시 확인할 예정입니다. 

![erd](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/migration-erd.png)



### DDL ###

워크샵용 샘플 스키마는 아래와 같이 테이블 8개, 뷰 1개, 프리서저 2개, 함수 1개, 트리거 1개, 시퀀스 3개 및 테이블별 인덱스로 구성되어 있습니다.

```
--drop sequence shop.seq_product_product_id;
create sequence shop.seq_product_product_id
start with 1
increment by 1
cache 20;

--drop sequence shop.seq_comment_comment_id;
create sequence shop.seq_comment_comment_id
start with 1
increment by 1
cache 20;

--drop sequence shop.seq_order_order_id;
create sequence shop.seq_order_order_id
start with 1
increment by 1
nomaxvalue
nocycle
cache 20;


-- rownum 를 이용한 페이징 처리 체크.
-- lob 데이터 마이그 확인
-- 각종 데이터타입 변환 정보확인
-- display 의 경우 char, varchar로 서로 다름.

--drop table shop.tb_category;
create table shop.tb_category
(
   category_id       number(4) not null primary key,
   category_name     varchar(300) not null,
   display_yn        varchar(1) default 'Y' not null
);

--drop table shop.tb_product;
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

--drop table shop.tb_comment;
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


-- order_no YYYYMMDD + serial(12자리) 어플리케이션에서 발행(프로시저로 만듬)
-- 체크 제약조건이 제대로 변환되는지 확인한다.

--drop table shop.tb_order;
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


--drop table shop.tb_order_detail;
create table shop.tb_order_detail
(
   order_no                varchar2(20) not null,
   product_id              number(9),
   product_price           number(19,3) not null,
   product_cnt             number,
   primary key(order_no, product_id)
);


--drop table shop.tb_product_summary;
create table shop.tb_product_summary
(
   year           varchar2(4) not null,
   month          varchar2(2) not null,
   day            varchar2(2) not null,
   hour           varchar2(2) not null,
   min            varchar2(2) not null,
   product_id     number(9) not null,
   order_cnt      number not null,
   total_price    number not null,
   comment_cnt    number not null,
   primary key(year, month, day, hour, min, product_id)
);


--drop table shop.tb_sct_typeconv;
create table shop.tb_sct_typeconv
(
   num              number,
   num1             number(1),
   num8             number(8),
   num9             number(9),
   num10            number(10),
   num11            number(11),
   num18            number(18),
   num19            number(19),
   num20            number(20),
   num30            number(30),
   num38            number(38),
   num10_3          number(10, 3),
   num38_4          number(38, 4),
   long_col         long,
   float_col1       float,
   float_col10      float(10),
   float_col20      float(20),
   chr1             char(1),
   chr2             char(2),
   chr3             char(2000),
   str1             varchar2(1),
   str4000          varchar2(4000),
   date_col         date,
   timestamp_col    timestamp,
   nchar_col        nchar(1),
   nvarchar         nvarchar2(100),
   nclob_col        nclob,
   bfile_col        bfile
);

--drop table shop.tb_order_summary;
create table shop.tb_order_summary
(
    order_no        varchar2(20) not null unique,
    product_cnt     number(9),
    reg_ymdt        timestamp
);


-- added 2021/02/01
-- trigger
create or replace trigger shop.tr_after_insert_order
after insert on shop.tb_order
for each row
declare
    v_product_cnt   number;
    v_order_no      tb_order.order_no%type;
begin
    dbms_output.put_line('tr_after_insert_order executed...');

  --  v_order_no :=

  --  select count(1) into v_product_cnt
  --  from shop.tb_order o, shop.tb_order_detail d
  --  where o.order_no = d.order_no
  --    and o.order_no = :new.order_no;


    -- 실행시 권한 오류로 인해 임시적으로 주서처리 함. 원인은 알수 없음 ㅜㅜ
    --insert into shop.tb_order_summary values(:NEW.order_no, v_product_cnt, sysdate);
end;
/


-- view
create or replace view shop.view_recent_order_30 as
select name, order_no, member_id, order_price, order_ymdt
from (
    select rownum as rn, p.name, o.order_no, o.member_id, o.order_price, o.order_ymdt
    from shop.tb_order o, shop.tb_order_detail d, shop.tb_product p
    where o.order_no = d.order_no
      and d.product_id = p.product_id
    order by o.order_ymdt desc
)
where rn between 1 and 30;

-- function
-- DROP FUNCTION shop.get_product_id;
CREATE OR REPLACE FUNCTION shop.get_product_id
RETURN VARCHAR2
IS
    v_today           VARCHAR2(8);
    v_sub_order_no    VARCHAR(12);
BEGIN

    select to_char(sysdate, 'yyyymmdd') into v_today from dual;
    select lpad(shop.seq_order_order_id.nextval, 12, '0') into v_sub_order_no from dual;

    return v_today || v_sub_order_no;
END;
/

-- procedure
-- outer join example
CREATE OR REPLACE PROCEDURE shop.sp_product_summary(v_interval in number)
IS
    v_cnt NUMBER := 0;
BEGIN
    -- truncate table.
    execute immediate 'truncate table test_table';

    insert into shop.tb_product_summary
    select to_char(o.order_ymdt, 'yyyy') as year,
        to_char(o.order_ymdt, 'mm') as month,
        to_char(o.order_ymdt, 'dd') as day,
        to_char(o.order_ymdt, 'hh') as hour,
        to_char(o.order_ymdt, 'mm') as min,
        p.product_id,
        count(1) as order_cnt,
        sum(d.product_price) as total_price,
        max(c.comment_cnt) as comment_cnt
    from
        shop.tb_order o,
        shop.tb_order_detail d,
        shop.tb_product p,
        (select product_id, count(1) as comment_cnt
         from shop.tb_comment
         group by product_id) c
    where o.order_no = d.order_no
      and d.product_id = p.product_id
      and p.product_id = c.product_id(+)
    group by to_char(o.order_ymdt, 'yyyy'),
        to_char(o.order_ymdt, 'mm'),
        to_char(o.order_ymdt, 'dd'),
        to_char(o.order_ymdt, 'hh'),
        to_char(o.order_ymdt, 'mm'),
        p.product_id;

    COMMIT;
END;
/

-- this code doesn't work so don't execute this.
-- loop example
-- DROP PROCEDURE SHOP.LOAD_DATA;
CREATE OR REPLACE PROCEDURE SHOP.LOAD_DATA(rowcnt IN NUMBER)
IS
    v_cnt NUMBER := 0;
    v_price NUMBER := 0;
    v_delivery_cd NUMBER := 0;
    v_delivery_type VARCHAR2(10);
    v_image_url VARCHAR2(300);
    v_random int;
BEGIN

    LOOP
        v_cnt := v_cnt + 1;

        BEGIN
            v_price := (MOD(v_cnt, 10) + 1) * 1000;
            select round(dbms_random.value(1,10)) into v_random from dual;

            IF v_random = 1 THEN
                v_delivery_type := 'Free';
            ELSE
                v_delivery_type := 'Charged';
            END IF;

            v_image_url := 'https://ocktank-prod-image.s3.ap-northeast-2.amazonaws.com/jeans/jean-' || v_random || '.png';

            INSERT INTO SHOP.TB_PRODUCT(product_id, name, price, description, delivery_type, image_url)
                VALUES(SHOP.seq_product_product_id.nextval,
                      'ocktank 청바지' || SHOP.seq_product_product_id.currval,
                      v_price,
                      '청바지 전문!!!',
                      v_delivery_type,
                      v_image_url);
        EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Exception ..');
        END;

        IF MOD(v_cnt, 1000) = 0 THEN
            COMMIT;
        END IF;

        EXIT WHEN v_cnt >= rowcnt;

    END LOOP;
    COMMIT;
END;
/
```


### 스키마 빌드 ###

오라클 데이터베이스에 실습용 스키마를 생성하기 위해, tf_loadgen EC2 인스턴스로 로그인하여 아래와 같은 명령어를 수행합니다. pyoracle 디렉토리로 이동한 후, create-schema.sh 쉘을 실행하면
오라클 11xe 및 19c 데이터베이스에 각각 유저, 테이블스페이스 및 스키마를 생성합니다. 설치 대상인 오라클 데이베이스들의 IP는 자동으로 detection 됩니다. 

```
$ ssh -i ~/.ssh/tf_key ec2-user@<tf_loadgen IP>
Last login: Fri Jan 29 10:50:02 2021 from 218.238.107.63

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/

[ec2-user@ip-172-31-34-59 ~]$ cd pyoracle
[ec2-user@ip-172-31-37-6 pyoracle]$ sh create-schema.sh 

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
