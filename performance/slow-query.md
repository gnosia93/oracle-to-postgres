## Slow Query 확인하기 ##

PostgreSQL 에서 슬로우 쿼리를 확이한느 방법은 아래와 같이 3가지의 방법이 있습니다. 

* Slow Query 로그 
* auto_explain으로 실행 계획 확인
* 쿼리 실행 통계(pg_stat_statements)


### Slow Query 로그 ###


```
select b.product_id, min(a.order_no), max(a.order_no)
from tb_order a, tb_order_detail b
where a.order_no = b.order_no
  and a.member_id = 'user001'
  and a.order_price >= 10000
group by b.product_id
order by b.product_id 
limit 10 offset 0;
```













### RDS Slow Query 확인하기 ###

* https://aws.amazon.com/ko/premiumsupport/knowledge-center/rds-postgresql-query-logging/



### 레퍼런스 ###

* [(PostgreSQL) 슬로우쿼리를 잡아내는 3가지 방법](https://americanopeople.tistory.com/288)

* https://aws.amazon.com/ko/blogs/database/optimizing-and-tuning-queries-in-amazon-rds-postgresql-based-on-native-and-external-tools/

* https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html
