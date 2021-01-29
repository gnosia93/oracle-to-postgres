
아파치 Jmeter 를 이용하여 이관후 postgres 의 성능을 측정합니다. 

오라클사의 JDBC 드라이버가 필요하며, 오라클 홈페이지에 제공되는 드라이버들은 Java Version 10 (class file version 54.0) 으로 컴파일되어 있어서, 

JDK 또는 JRE 10 버전 이상으로 설치가 필요합니다. 

## 측정 대상 SQL ##

성능 측정의 대상이 되는 SQL 은 오라클 v$sqlarea 에서 관찰되는 SQL 중 다음과 같은 우선순위로 선정합니다.

* Block IO / exec 가 높은 SQL
* exec 수치가 높은 SQL
* physical IO 가 높은 SQL 

```
select * from v$sql;
```

## 아피치 JMeter 설치 ##


## JMeter 설정 ##







## JMeter 스트레스 테스트 ##



## 레퍼런스 ##

* [Proxy 사용법](https://sncap.tistory.com/547)

* [플러그인](https://huistorage.tistory.com/89?category=723808)

* https://stackoverflow.com/questions/47457105/class-has-been-compiled-by-a-more-recent-version-of-the-java-environment

* https://jmeter.apache.org/usermanual/build-db-test-plan.html

* https://jongsma.wordpress.com/2019/08/08/oracle-stress-testing-using-apache-jmeter/
