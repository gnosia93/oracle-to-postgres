## PostgreSQL 성능 테스트 ##

아파치 Jmeter 를 이용하여 postgres 의 성능을 측정할 수 있습니다. 실제 마이그레이션 프로젝트에서는 신규 데이터베이스로 이관하기 전에 성능 테스트가 진행된다고 생각하면 됩니다.  

Jmeter 를 이용하여 테스트하시기 위해서는 postgres 용 JDBC 드라이버가 필요합니다.


### 대상 SQL 선정 ###

성능 측정 대상 SQL 을 수집하기 위해서 오라클 데이터베이스의 v$sqlarea 를 조회합니다. 바인드 변수값이 필요한 경우 v$bind ?? 역시 조회하고, 다음과 같은 방법으로 SQL 을 수집합니다. 

* Block IO / exec 가 높으면서 실행빈호가 높은 SQL 
* physical IO 가 높은 SQL 

[측정 대상 선정SQL]
```


```

본 실습에서는 아래의 SQL 을 이용하여 성능 측정을 하도록 하겠습니다.  
성능 측정 대상 SQL 은 회원ID 가 user100 인 사용자의 주문 이력(페이징 처리)과 579번 상품에 대한 상세 정보 조회 및 특정 주문번호에 대한 세부 주문 상품 조회로 구성됩니다.   
```
select * from (select rownum as rn, o.* from shop.tb_order o where member_id = 'user100' order by order_ymdt desc) where rn <= 10;
select * from shop.tb_product where product_id = 579;
select * from shop.tb_order_detail where order_no = '20210223000032789943';
```


### 테스트 플랜 설정하기 ###

















### 레퍼런스 ###

* http://www.leeladharan.com/running-multiple-sql-queries-in-jmeter

* https://sqa.stackexchange.com/questions/46305/jmeter-how-do-i-run-parallel-jdbc-requests-in-jmeter

* [Proxy 사용법](https://sncap.tistory.com/547)

* [플러그인](https://huistorage.tistory.com/89?category=723808)

* https://stackoverflow.com/questions/47457105/class-has-been-compiled-by-a-more-recent-version-of-the-java-environment

* https://jmeter.apache.org/usermanual/build-db-test-plan.html

* https://jongsma.wordpress.com/2019/08/08/oracle-stress-testing-using-apache-jmeter/
