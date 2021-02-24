## JMeter를 활용한 PostgreSQL 성능 테스트 ##

아파치 Jmeter 를 이용하여 postgres 의 성능을 측정할 수 있습니다. 실제 마이그레이션 프로젝트에서는 신규 데이터베이스로 이관하기 전에 성능 테스트가 진행하게 되는데, 성능 측정을 위해서는 테스트 시나리오 설정이 필요합니다. 

### 측정 대상 SQL 선정 ###

성능 측정의 대상이 되는 SQL 은 담당 DBA 또는 어플리케이션 개발자로 부터 자주 사용되는 억세스 패턴과 관련된 SQL 리스트를 수집할 수도 있지만, 원본 데이터베이스가 오라클인 경우 v$sqlarea 을 조회한다거나, AWR Report 를 통해 관련 정보를 손쉽게 수집할 수 있습니다. 
아래는 오라클의 v$sqlarea 뷰를 이용하여 실행빈도가 높으면서, 각각의 선정기준에 맞는 SQL 을 찾는 방법을 보여주고 있습니다. 

* buffer_gets/executions 값이 높은 SQL
* disk_reads/executions 값이 높은 SQL
* elapsed_time/executions 값이 높은 SQL
* cpu_time/executions 값이 높은 SQL

[성능측정 후보 조회 SQL]

아래 SQL 은 실행횟수 대비 buffer_gets가 높은 SQL 을 찾아내는 쿼리로 만약 cpu_time 기준으로 후보 SQL 을 찾고자 한다면 아래의 order by 절의 buffer_gets/executions 구문을 cpu_time/executions 으로 수정한 후, 해당 쿼리를 실행하면 됩니다. 
또한 이 예제에서는 SQL 을 실행하는 module 기준으로 쿼리를 필터링 하고는 있지만, SQL 을 실행하는 유저 기준으로도 후보 대상 SQL 을 찾아 볼 수도 있습니다. 

v$sqlarea 뷰의 definitin 에 대해서는 [ URL](https://docs.oracle.com/cd/B19306_01/server.102/b14237/dynviews_2129.htm#REFRN30259
)를 참조하시기 바랍니다. 

```
select module, sql_fulltext, executions,
    round(buffer_gets/executions, 1) as gets_by_exec,
    round(disk_reads/executions, 1) as gets_by_exec,
    round(elapsed_time/executions, 1) as elaps_by_exec,
    round(cpu_time/executions, 1) as cpu_by_exec
from v$sqlarea
where executions > 0
  and module like 'SQL Developer%' or module like 'python3%'
order by buffer_gets/executions desc, executions desc;
```

데이터베이스 변경에 따른 성능측정 시나리오 작성시 가장 효과적인 방법은 해당 어플리케이션의 특성을 알고 있는 현업 담당자(DBA 또는 어플리케이션 개발자) 로 부터 여러가지 테스트 시나리오와 관련 SQL 및 바인드 변수값을 받아서 아피치 JMeter 의 Test Plan 을 작성하는 것이 가장 효과적이면서 안정적인 방법입니다.

본 실습에서는 아래의 3개의 SQL 을 이용하여 성능 측정을 하도록 하겠습니다.  
성능 측정 대상 SQL 은 쇼핑몰의 전형적인 쿼리 패턴중 사용자별 주문내역을 조회할때 실행되는 SQL의 간소화된 버전입니다.  
회원ID 가 user100 인 사용자의 주문 이력(페이징 처리)과 579번 상품에 대한 상세 정보 조회 및 특정 주문의 세부 상품 구성 목록으로 구성되어 있으며,   
세번째 SQL 의 경우 order_no 는 여러분들이 생성한 주문번호 중 아무거나 하나를 입력하기시 바랍니다. 

```
select * from (select rownum as rn, o.* from shop.tb_order o where member_id = 'user100' order by order_ymdt desc) where rn <= 10;
select * from shop.tb_product where product_id = 579;
select * from shop.tb_order_detail where order_no = '<your generated order-no>';
```

### JMeter 이해하기 ###

Apache JMeter는 웹어플리케이션의 성능 테스트를 위해서 만들어진 100% 순수 자바 프로그램으로, 단위/성능/스트레스 테스트 등 많은 곳에서 활용될 수 있습니다. JMeter 가 지원하는 프로토콜(Protocol)은 TCP, HTTP(S), FTP, JDBC, LDAP, SMTP, SAP/XML, RPC 등을 지원하고 있으며, GUI 형태 또는 CLI 기반으로 어플리케이션의 성능 테스트에 활용됩니다.

![archigecture](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/JMeter%20Architecture.png)
출처: https://multicore-it.com/

### JMeter 테스트 플랜 작성하기 ###

JMeter 처음 실행하면 아무런 설정이 없는 Test Plan를 확인하실 수 있습니다. Test Plan 에 대한 설정을 진행하기 전에 우선 테스트하고자 하는 데이터베이스의 JDBC 드라이버를 JMeter 에 등록해야 합니다.
여기서 우리는 소스 데이터베이스인 오라클과 타켓 데이터베이스인 PostgreSQL 에 대해 동일 형태의 Test Plan를 생성하여 테스트를 진행할 예정이므로, 아래와 같이 오라클용 및 PostgreSQL 용 JDBC 드라이버를 등록하도록 합니다. JDBC 드라이버를 등록하기 위해서는 로컬 PC에 JDBC 드리어버 jar 파일이 다운로드 되어져 있어야 합니다. 드라이버가 없는 경우 아래 URL에서 JDBC 드라이버를 로컬 PC로 다운로드 받으십시오.

* https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/ojdbc8.jar
* https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/postgresql-42.2.18.jar

좌측 메뉴의 Test Plan을 선택한 후, 화면하단의 [Browse...] 버튼을 클릭하여 PC에 저장된 ojdbc8.jar 파일과 postgresql-42.2.18.jar 파일을 선택합니다. 

![ThreadGroup1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/TestPlan.png)

테스트 플랜 설정의 첫번째 단계는 부하를 발생시킬 쓰레드 그룹 생성하는 일입니다. 아래의 그림과 같이 Test Plan 을 우클릭하여, 쓰레드 그룹을 생성하고,
에러 발생시 쓰레드를 정지 시키기 위해서 Stop Thread 를 선택한 후, Number of Threads, Ramp-up peroid 값을 1로 설정하고, Loop Count 는 Infinite 로 설정합니다. 여기서 쓰레드의 수는 SQL 을 실행하는 유저수에 해당 합니다. 

![ThreadGroup1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ThreadGroup1.png)
![ThreadGroup2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ThreadGroup2.png)


이번 테스트 플랜에서는 하나의 쓰레드가 여러개의 SQL을 순차적으로 실행할 예정입니다. 이는 실제 프로덕션 환경에서 발생하는 트래픽과 거의 흡사한 형태의 테스트를
가능하게 하는 것으로, 여러분의 PC 에 order-list.sql 이라는 이름의 파일을 만들고, 해당 파일안에 아래의 SQL 을 입력합니다.
SQL 문장 입력시 주의할 점은 모든 SQL 은 세미콜론으로 끝나야 하며, 하나의 SQL는 한 줄로 기술되어야 하고, 줄과 줄 사이에는 공백이 있어서는 안됩니다. 

[order-list.sql]
```
select * from (select rownum as rn, o.* from shop.tb_order o where member_id = 'user100' order by order_ymdt desc) where rn <= 10;
select * from shop.tb_product where product_id = 579;
select * from shop.tb_order_detail where order_no = '20210223000032789943';
```

아파치 Jmeter 에서 하나의 쓰레드가 순차적으로 여러개의 SQL 을 순차적으로 실행하기 위해서는 CSV Data Set Config 설정이 필요합니다. 아래의 그림에서 보이는 바와 같이  
Test Plan 을 우클릭한 후 CSV Data Set Config 를 하나 생성합니다. 
![CsvConfig1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/CsvConfig1.png)

Filename 필드에는 위에서 생성해 놓은 SQL Query를 담고 있는 파일의 경로를 설정하도록 하고, 
![CsvConfig2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/CsvConfig2.png)

Variable Names 필드의 값으로는 sqlQuery 를 입력하며, Delimiter 필드에는 ;(세미콜론)을 입력하도록 합니다. 
![CsvConfig3](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/CsvConfig3.png)

다음 단계는 테스트 대상 데이터베이스를 등록하는 것입니다. 우선 오라클 데이터베이스를 먼저 등록한 후, 오라클 데이터베이스에 대한 성능 테스트를 진행한 후, 익숙해 지면
postgreSQL 에 대해 등록하도록 하겠습니다. 테스트 대상 데이터베이스의 접속 정보를 설정하기 위해서 Thread Group 를 선택한 후 우클릭해서 JDBC Connection Configuration 을 선택합니다. 
![JdbcConnection1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/JdbcConnection1.png)

Variable Name for created pool 필드에 datasource 를 입력하고, Database URL 은 jdbc:oracle:thin:@<19c oracle public ip>:1521/pdb1 
을 입력하고, JDBC Driver class 로는 oracle.jdbc.OracleDriver 를 선택합니다.
Username 과 Password 란에는 shop 으로 입력합니다.   
[그림 #1]
![JdbcConnection2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/JdbcConnection2.png)

아파치 Jmeter 는 성능 테스트 결과를 확인하기 위한 도구를 리스너(Listener)라는 형태로 지원해 주고 있습니다. 여기서는 여러개의 리스너중 Summary Report 와 ViewResultTable을 사용하도록 하겠습니다.
아래 그림에서 보이는 바와 같이 두개의 리스너를 차례대로 등록하도록 합니다. 

![ListenerViewResultTree](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ListenerViewResultTree.png)
![LIstenerSummaryReport](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/LIstenerSummaryReport.png)
![ListnerViewResultTable](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ListnerViewResultTable.png)

이제 마지막으로 할일은 실제 부하를 만들어낼 샘플러를 등록하는 일입니다. 아래의 그림에서 보이는 바와 같이 Thread Group 을 선택한 후, 우클릭하여 JDBC Request 샘플러를 하나 등록하도록 합니다. 기본적으로 하나의 JDBC Request 샘플러는 하나의 SQL 만 실행하도록 구현되어 있으나, 이 예제에서는 CSV Data Set 를 이용하여 여러개의 SQL 을 하나의 JDBC Request 샘플러가 실행하도록 설정하였습니다. 

![SamplerJDBCRequest1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/SamplerJDBCRequest1.png)

JDBC Request 샘플러를 새롭게 등록한 후, Query 섹션에 ${sqlQuery} 라는 텍스트 값을 입력하도록 합니다. 
![SamplerJDBCRequest2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/SamplerJDBCRequest2.png)


### 테스트 실행 및 결과보기 ###

상단메뉴의 녹색 시작 버튼을 눌러서 테스트를 시작합니다. 
![TestPlanStart](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/TestPlanStart.png)

아래와 같이 테스트 도중 중간 결과값을 Summary 형태의 테이블로 확인할 수 있습니다. 
![ResultSummary](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ResultSummary.png)

아래와 같이 개별 SQL의 응답시간을 실행 순서대로 확인할 수 있습니다. 
![ResultTable](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ResultTable.png)

트리뷰를 이용하여 실행되는 SQL 및 리턴되는 데이터베이스 레코드 또한 확인할 수 있습니다. 
![ResultTree1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ResultTree1.png)

![ResultTree2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/ResultTree2.png)


### PostgreSQl 테스트 플랜 작성 및 실행하기 ###

[order-list.sql]
```
select o.* from shop.tb_order o where member_id = 'user100' order by order_ymdt desc limit 10 offset 0;
select * from shop.tb_product where product_id = 579;
select * from shop.tb_order_detail where order_no = '20210223000032789943';
```

[그림1]

[그림2] 변경.

### 레퍼런스 ###

* https://jmeter.apache.org/usermanual/build-db-test-plan.html

* https://story.stevenlab.io/207

* https://multicore-it.com/67

* https://www.google.co.kr/search?source=hp&ei=jjU1YN6YMIuymAWwv5v4Ag&iflsig=AINFCbYAAAAAYDVDnvEjPLlVJL_f3p3FY-QuSWzoOWYe&q=apache+jmeter+%EC%95%84%ED%82%A4%ED%85%8D%EC%B2%98&oq=apache+jmeter+%EC%95%84%ED%82%A4%ED%85%8D%EC%B2%98&gs_lcp=Cgdnd3Mtd2l6EAM6BQgAELEDOggIABCxAxCDAToCCAA6BAgAEAo6BAgAEA06BQghEKABUIkCWNtRYNFTaA9wAHgDgAG-AYgB-h-SAQQwLjI4mAEAoAEBqgEHZ3dzLXdperABAA&sclient=gws-wiz&ved=0ahUKEwjel-jDvoDvAhULGaYKHbDfBi8Q4dUDCAc&uact=5

* https://blog.naver.com/PostView.nhn?blogId=raonsql&logNo=220988925526&categoryNo=31&parentCategoryNo=0&viewDate=&currentPage=1&postListTopCurrentPage=1&from=search
