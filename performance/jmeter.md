## PostgreSQL 성능 테스트 ##

아파치 Jmeter 를 이용하여 postgres 의 성능을 측정할 수 있습니다. 실제 마이그레이션 프로젝트에서는 신규 데이터베이스로 이관하기 전에 성능 테스트가 진행하게 되는데, 성능 측정을 위해서는 테스트 시나리오 설정이 필요합니다. 

### 측정 대상 SQL 선정 ###

성능 측정의 대상이 되는 SQL 은 DBA 또는 어플리케이션 개발자로 부터 자주 사용되는 억세스 패턴에 대해 관련 SQL 정보를 수집할 수도 있지만, 원본 데이터베이스가 오라클인 경우 v$sqlarea 을 이용하여 관련 정보를 조회할 수 있습니다. 바인드 변수값이 필요한 경우 v$bind_parameter 뷰를 통해 정보를 조회할 수 있으며, 관련 SQL 및 수집 방법은 아래와 같습니다. 

* Block IO / exec 가 높으면서 실행빈호가 높은 SQL 
* physical IO 가 높은 SQL 

[측정 대상 선정SQL]
```

```

[바인드 변수 조회 SQL]
```

```

본 실습에서는 아래의 3개의 SQL 을 이용하여 성능 측정을 하도록 하겠습니다.  
성능 측정 대상 SQL 은 쇼핑몰의 전형 적인 쿼리 패턴중 사용자별 주문내역을 조회할때 실행되는 SQL로 아래의 경우 
회원ID 가 user100 인 사용자의 주문 이력(페이징 처리)과 579번 상품에 대한 상세 정보 조회 및 특정 주문번호에 대한 세부 주문 상품 조회로 구성됩니다.   
```
select * from (select rownum as rn, o.* from shop.tb_order o where member_id = 'user100' order by order_ymdt desc) where rn <= 10;
select * from shop.tb_product where product_id = 579;
select * from shop.tb_order_detail where order_no = '20210223000032789943';
```


### JMeter 테스트 플랜 작성하기 ###

테스트 플랜을 작성하기 위해서는 먼저 부하를 발생시킬 쓰레드 그룹 생성이 필요합니다. 아래의 그림과 같이 Test Plan 을 우클릭한 후, 쓰레드 그룹을 생성하고,
에러 발생시 쓰레드를 정지 시키기 위해서 Stop Thread 를 선택한 후, Number of Threads, Ramp-up peroid 값을 1로 설정하고, Loop Count 는 Infinite 로 설정합니다. 여기서 쓰레드의 수는 SQL 을 실행하는 유저수입니다.   

![ThreadGroup1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ThreadGroup1.png)
![ThreadGroup2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ThreadGroup2.png)

하나의 쓰레드가 순차적으로 여러개의 SQL 을 실행하기 위해서는 CSV Data Set Config 설정이 필요합니다. 아래의 그림에서 보이는 바와 같이  
Test Plan 을 우클릭한 후 CSV Data Set Config 를 하나 생성합니다. 
![CsvConfig1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/CsvConfig1.png)

Filename 필드에는 성능 테스트시 실행할 SQL Query를 담고 있는 파일의 경로를 설정하도록 하고, 
![CsvConfig2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/CsvConfig2.png)

Variable Names 필드의 값으로는 sqlQuery 를 입력하고, Delimiter 필드에는 ;(세미콜론)을 입력하도록 합니다. 
![CsvConfig3](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/CsvConfig3.png)

[order-list.sql 파일 내용]
```
select * from (select rownum as rn, o.* from shop.tb_order o where member_id = 'user100' order by order_ymdt desc) where rn <= 10;
select * from shop.tb_product where product_id = 579;
select * from shop.tb_order_detail where order_no = '20210223000032789943';
```

테스트 대상 데이터베이스의 접속 정보를 설정하기 위해서 Thread Group 를 선택한 후 우클릭해서 JDBC Connection Configuration 을 선택합니다. 
![JdbcConnection1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/JdbcConnection1.png)

Variable Name for created pool 필드에 datasource 를 입력하고, Database URL 은 jdbc:oracle:thin:@<19c oracle public ip>:1521/pdb1 
을 입력하고, JDBC Driver class 로는 oracle.jdbc.OracleDriver 를 선택합니다.
Username 과 Password 란에는 shop 으로 입력합니다. 
![JdbcConnection2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/JdbcConnection2.png)


성능 테스트 결과를 확인하기 위해서 여러개의 리스너를 아래와 같이 등록합니다. 

![LIstenerSummaryReport](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/LIstenerSummaryReport.png)

![JdbcConnection2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/JdbcConnection2.png)

![JdbcConnection2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/JdbcConnection2.png)











### 레퍼런스 ###

* http://www.leeladharan.com/running-multiple-sql-queries-in-jmeter

* https://sqa.stackexchange.com/questions/46305/jmeter-how-do-i-run-parallel-jdbc-requests-in-jmeter

* [Proxy 사용법](https://sncap.tistory.com/547)

* [플러그인](https://huistorage.tistory.com/89?category=723808)

* https://stackoverflow.com/questions/47457105/class-has-been-compiled-by-a-more-recent-version-of-the-java-environment

* https://jmeter.apache.org/usermanual/build-db-test-plan.html

* https://jongsma.wordpress.com/2019/08/08/oracle-stress-testing-using-apache-jmeter/
