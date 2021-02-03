## 오브젝트 변환하기 ##

### 오브젝트 매핑 (Oracle to Postgresql) ###

* 데이터 타입 매핑 

  SCT 의해 자동 매핑되는 타입 변환 정보는 다음과 같습니다. 
```
number        ---> double precision
number(n)     ---> numeric(n, 0)             n 의 범위의 1 ~ 39
number(p, s)  ---> numeric(p, s)
float         ---> double precision
char(n)       ---> character(n)              n 의 범위는 1 ~ 2000
varchar2(n)   ---> character varying(n)      n 의 범위는 1 ~ 4000
date          ---> timestamp(0)
timestamp     ---> timestamp(6)
nchar(n)      ---> character(n)
nvarchar2(n)  ---> character varying(n)
blob          ---> bytea
clob          ---> text
long          ---> text
bfile         ---> 지원하지 않음
```

* 코드 오브젝트 매핑

  postgresql는 시퀀스, 뷰, 머티리얼라이즈 뷰, 함수, 프로시저, 트리거와 같은 코드성 오브젝트는 지원되나, 오라클의 패키지 및 Synonym 은 지원하지 않습니다.
  원본 데이터베이스인 오라클 데이터베이스에서 패키지를 사용하고 있고 해당 패키지가 이관 대상인 경우는 postgresql 의 namespace 에 해당하는 스키마로 매핑하도록 합니다.  


### 리포트 출력하기 ###

오라클의 오브젝트를 postgresql 로 변환하기 전에 리포트 생성 기능을 이용하여 매핑시 발생하는 오류를 사전에 확인할 수 있습니다.    
아래와 같이 오라클의 SHOP 스키마를 선택하고 팝업 메뉴에서 create report 를 선택합니다.  

[리포트 만들기]
![create report](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-create-report.png)

[리포트 결과]
![create report](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-report.png)

수정 또는 확인이 필요한 액션 아이템을 보여준고 있다. 주로 프로시저나 함수, 트리거와 같은 코드성 오브젝트에서 발생한다. 

[액션 아이템]
![action item](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-action-item.png)


### 스키마 변환하기 ###

아래의 그림과 같이 오라클의 스키마를 postgres 용으로 변환합니다. 

![convert1](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-convert-schema1.png)

![convert2](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-convert-schema2.png)

![convert3](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-convert-schema3.png)


### 스미카 적용하기 ###

변환된 스키마를 확인하여 최종적으로 postgresql 에 적용합니다.

![convert1](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-apply1.png)

![convert2](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-apply2.png)


### 오류 수정하기 ###

지금부터는 스키마 적용과정에서 오류가 발생한 shop.view_recent_order_30 를 수정하도록 하겠습니다. 

아래 오라클 원본 뷰의 definicatin 으로 보아, 조인 결과를 정렬한 후 순서대로 30건만 출력하는 것을 확인할 수 있습니다. 

[oracle view]
```
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
```

SCT 에 의한 자동 코드 변환 결과를 보면 문법 오류와 깔끔하지 않은 LIMIT 문장 처리 부분을 확인할 수 있습니다. 

[sct에 의해 postgresql 에 생성된 뷰] 
```
CREATE OR REPLACE VIEW shop.view_recent_order_30 (name, order_no, member_id, order_price, order_ymdt) AS
SELECT
    name, order_no, member_id, order_price, order_ymdt
    FROM (SELECT
        p.name, o.order_no, o.member_id, o.order_price, o.order_ymdt
        FROM shop.tb_order AS o, shop.tb_order_detail AS d, shop.tb_product AS p
        WHERE o.order_no = d.order_no AND d.product_id = p.product_id
        LIMIT
        CASE
            WHEN TRUNC(30) <= 0 THEN 0
            WHEN TRUNC(1) < 0 THEN TRUNC(30)
            WHEN (TRUNC(1) - 1) = 0 THEN TRUNC(30)
            ELSE TRUNC(30) - 1
        END OFFSET
        CASE
            WHEN TRUNC(1) <= 0 THEN 0
            WHEN (TRUNC(1) - 1) < 0 THEN 0
            ELSE TRUNC(1) - 1
        END) AS var_sbq
    ORDER BY o.order_ymdt DESC;             <--- 문장 오류
```


![example3](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-example1-3.png)

postgresql 의 View Definition 선택하고 아래의 문장을 이용하여 수정합니다.  
```
CREATE OR REPLACE VIEW shop.view_recent_order_30 (name, order_no, member_id, order_price, order_ymdt) AS
SELECT
   p.name, o.order_no, o.member_id, o.order_price, o.order_ymdt
FROM shop.tb_order AS o, shop.tb_order_detail AS d, shop.tb_product AS p
WHERE o.order_no = d.order_no AND d.product_id = p.product_id
ORDER BY o.order_ymdt DESC
LIMIT 30;       
```

[apply to database] 로 타켓 DB 에 적용합니다.  
![example2](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-example1-2.png)

최종적으로 오류 내용이 사라진 것을 확인할 수 있습니다. 
![example2](https://github.com/gnosia93/postgres-terraform/blob/main/sct/images/sct-example1-1.png)


