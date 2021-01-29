
아파치 Jmeter 를 이용하여 이관후 postgres 의 성능을 측정합니다. 

## 측정 대상 SQL ##

성능 측정의 대상이 되는 SQL 은 오라클 v$sqlarea 에서 관찰되는 SQL 중 다음과 같은 우선순위로 선정합니다.

* Block IO / exec 가 높은 SQL
* exec 수치가 높은 SQL
* physical IO 가 높은 SQL 

```
select * from v$sql;
```


## JMeter 설정 ##







## JMeter 스트레스 테스트 ##



## 레퍼런스 ##

* https://jongsma.wordpress.com/2019/08/08/oracle-stress-testing-using-apache-jmeter/
