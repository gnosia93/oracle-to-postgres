## Slow Query 확인하기 ##

PostgreSQL 에서 슬로우 쿼리를 확이한느 방법은 아래와 같이 3가지의 방법이 있습니다. 

* Slow Query 로그 
* auto_explain으로 실행 계획 확인
* 쿼리 실행 통계(pg_stat_statements)


### Slow Query 로그 ###

슬로우 쿼리 로그를 확인하기 위해서는 postgres.conf 파일을 변경해야 합니다. 아래와 같이 PostgreSQL 가 설치된 tf_postgre_19c 인스턴스로 로그인해서 해당 파일을 변경하도록 합니다. tf_postgre_19c 의 공인 IP 는 AWS Console 또는 terraform 을 이용하여 확인할 수 있습니다. 

```
(base) f8ffc2077dc2:~ soonbeom$ ssh -i ~/.ssh/tf_key ec2-user@3.36.11.115
Last login: Wed Feb  3 01:16:53 2021 from 218.238.107.63

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
20 package(s) needed for security, out of 31 available
Run "sudo yum update" to apply all updates.

[ec2-user@ip-172-31-17-131 ~]$ sudo su - postgres


```

아래의 SQL을 pgadmin 을 이용하여 실행합니다. 
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
