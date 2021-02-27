## 슬로우 쿼리 확인하기 ##

슬로우 쿼리의 확인은 오픈전 쿼리 성능 테스트 단계 또는 실제 서비스를 오픈 한 이후 시스템의 성능 저하의 원인을 찾는데 중요한 역할을 합니다. 
PostgreSQL 에서 슬로우 쿼리를 확인하는 방법은 아래와 같이 3가지의 방법이 있습니다.

* 슬로우 쿼리 로그 
* auto_explain으로 실행 계획 확인
* 쿼리 실행 통계(pg_stat_statements)
* 세션 SQL 관찰 

이중 실제 운영 단계에서도 많이 사용되고 있는 슬로우 쿼리로그 방식과 쿼리 실행 통계 방식에 대해서 한번 자세하게 살펴볼 것입니다.
auto_explain 방식의 경우 슬로우 쿼리로그와 기본적으로 동일하며, 추가적으로 실행계획까지 로그 파일에 출력해 주는 기능합니다. 하지만 실행계획을 출력하기 위해서 내부적으로 동일한 SQL 을 한번더 실행하게 되므로, 필요하다면 성능 테스트 단계에서만 활용하고 운영단계에서는 되도록 쓰지 않는 것이 좋습니다. 

아마존 RDS 를 사용하는 경우 [본 링크](https://aws.amazon.com/ko/premiumsupport/knowledge-center/rds-postgresql-query-logging/
)를 통해서 슬로우 쿼리를 확인할 수 있는 방법을 배우실 수 있습니다.  


### 슬로우 쿼리 로그 ###

PostgreSQL 에서 슬로우 쿼리 로깅 기능은 기본적으로 활성화 되어 있지 않기 때문에 쿼리 확인하기 위해서는 postgres.conf 설정 파일을 변경이 필요합니다. 아래와 같이 PostgreSQL 가 설치된 tf_postgre_19c 인스턴스로 로그인해서 해당 파일을 변경하도록 합니다. tf_postgre_19c 의 공인 IP 는 AWS Console 또는 terraform 을 이용하여 확인할 수 있습니다. 

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
-bash-4.2$ cd /var/lib/pgsql/data
-bash-4.2$ ls -la
total 68
drwx------ 20 postgres postgres  4096 Feb 27 00:00 .
drwx------  5 postgres postgres   143 Feb  3 02:22 ..
drwx------  6 postgres postgres    58 Feb 27 00:45 base
-rw-------  1 postgres postgres    30 Feb 27 00:00 current_logfiles
drwx------  2 postgres postgres  4096 Feb  3 01:26 global
drwx------  2 postgres postgres   188 Feb  8 00:00 log
drwx------  2 postgres postgres     6 Feb  2 11:44 pg_commit_ts
drwx------  2 postgres postgres     6 Feb  2 11:44 pg_dynshmem
-rw-------  1 postgres postgres  4393 Feb  2 11:44 pg_hba.conf
-rw-------  1 postgres postgres  1636 Feb  2 11:44 pg_ident.conf
drwx------  4 postgres postgres    68 Feb 24 01:09 pg_logical
drwx------  4 postgres postgres    36 Feb  2 11:44 pg_multixact
drwx------  2 postgres postgres    18 Feb  2 11:44 pg_notify
drwx------  2 postgres postgres     6 Feb  2 11:44 pg_replslot
drwx------  2 postgres postgres     6 Feb  2 11:44 pg_serial
drwx------  2 postgres postgres     6 Feb  2 11:44 pg_snapshots
drwx------  2 postgres postgres     6 Feb  2 11:44 pg_stat
drwx------  2 postgres postgres    84 Feb 27 01:13 pg_stat_tmp
drwx------  2 postgres postgres    18 Feb  2 11:44 pg_subtrans
drwx------  2 postgres postgres    19 Feb  3 00:09 pg_tblspc
drwx------  2 postgres postgres     6 Feb  2 11:44 pg_twophase
-rw-------  1 postgres postgres     3 Feb  2 11:44 PG_VERSION
drwx------  3 postgres postgres  4096 Feb 23 14:43 pg_wal
drwx------  2 postgres postgres    18 Feb  2 11:44 pg_xact
-rw-------  1 postgres postgres    88 Feb  2 11:44 postgresql.auto.conf
-rw-------  1 postgres postgres 23867 Feb  2 11:44 postgresql.conf
-rw-------  1 postgres postgres    45 Feb  2 11:44 postmaster.opts
-rw-------  1 postgres postgres    92 Feb  2 11:44 postmaster.pid

-bash-4.2$ vi postgresql.conf 
log_min_duration_statement = 3000

-bash-4.2$ psql 
psql (11.5)
Type "help" for help.

postgres=# select pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
postgres=# exit
```
log_min_duration_statement 파라미터의 값을 3000 으로 설정했기 때문에, 실행시간이 3초 이상 걸리는 SQL 에 대해서는 로그로 출력될 것입니다. 

실제 테스트를 위해서 아래의 SQL을 pgadmin 을 이용하여 실행합니다.    
[테스트 쿼리 #1]
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

![slowquery](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/slowquery1.png)


로그 출력을 확인하기 위해서 아래와 같이 /var/lib/pgsql/data/log 디렉토리로 이동하여 당일 요일에 맞는 로그 파일을 tail 로 확인 합니다.
아래 출력 결과로 볼때 우리가 실행한 SQL 의 실행시간은 약 4.4초 정도 소요된 것을 확인 할 수 있습니다. 
실행로그가 관찰되지 않는 경우, 한번 더 [테스트 쿼리 #1] 을 실행해 봅니다. 
```
-bash-4.2$ cd log
-bash-4.2$ pwd
/var/lib/pgsql/data/log
-bash-4.2$ ls -la
total 2440
drwx------  2 postgres postgres     188 Feb  8 00:00 .
drwx------ 20 postgres postgres    4096 Feb 27 01:21 ..
-rw-------  1 postgres postgres       0 Feb 26 00:00 postgresql-Fri.log
-rw-------  1 postgres postgres       0 Feb 22 00:00 postgresql-Mon.log
-rw-------  1 postgres postgres    3264 Feb 27 01:24 postgresql-Sat.log
-rw-------  1 postgres postgres       0 Feb 21 00:00 postgresql-Sun.log
-rw-------  1 postgres postgres       0 Feb 25 00:00 postgresql-Thu.log
-rw-------  1 postgres postgres 1422660 Feb 23 23:59 postgresql-Tue.log
-rw-------  1 postgres postgres 1063308 Feb 24 12:00 postgresql-Wed.log

-bash-4.2$ tail -f postgresql-Sat.log

2021-02-27 01:28:01.148 UTC [29030] LOG:  duration: 4466.196 ms  statement: select b.product_id, min(a.order_no), max(a.order_no)
	from tb_order a, tb_order_detail b
	where a.order_no = b.order_no
	  and a.member_id = 'user001'
	  and a.order_price >= 10000
	group by b.product_id
	order by b.product_id 
	limit 10 offset 0;
```


### auto_explain으로 실행 계획 확인 ###

슬로우 쿼리 로그의 경우 해당 SQL의 실행계획 정보는 출력해 주지 않는다. 쿼리 로그와 더불어 실행계획까지 출력하고자 하는 경우 postgres.conf 설정 파일에 아래 내용을 추가하고,
설정 파일을 reload 하도록 한다. 

```
-bash-4.2$ vi postgresql.conf 
session_preload_libraries = 'auto_explain'

-bash-4.2$ psql 
psql (11.5)
Type "help" for help.

postgres=# select pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
postgres=# exit
```

### 쿼리 실행 통계(pg_stat_statements)  ###

pg_stat_statements 는 오라클의 v$sqlarea 와 비슷한 정보를 제공하는 쿼리실행 통계 뷰입니다. 해당 뷰는 기본적으로 비활성화 상태이기 때문에 활성화 하기위해서는 아래와 같이 postgres.conf 설정 파일의 shared_preload_libraries 부분을 수정한 후, 서버를 재기동 해야 합니다.
```
shared_preload_libraries = 'pg_stat_statements' # (change requires restart)
```
postgresql 서버를 재기동을 위해서는 sudo 권한이 있는 ec2-user 로 스위칭 한후, systemctl 명령어를 이용하여 재시작합니다. 재시작이 완료되면 psql 커맨드라인 툴을 이용하여 extension를 생성하고, 데이터베이스 어드민 유저인 postgres 유저의 remote 로그인이 가능하게 하기위해 아래와 같이 패스워드를 설정 합니다. 
```
[ec2-user@ip-172-31-17-131 ~]$ sudo systemctl restart postgresql

[ec2-user@ip-172-31-17-131 ~]$ sudo systemctl status postgresql
● postgresql.service - PostgreSQL database server
   Loaded: loaded (/usr/lib/systemd/system/postgresql.service; enabled; vendor preset: disabled)
   Active: active (running) since 토 2021-02-27 02:12:49 UTC; 7s ago
  Process: 30857 ExecStartPre=/usr/libexec/postgresql-check-db-dir %N (code=exited, status=0/SUCCESS)
 Main PID: 30860 (postmaster)
   CGroup: /system.slice/postgresql.service
           ├─30860 /usr/bin/postmaster -D /var/lib/pgsql/data
           ├─30862 postgres: logger   
           ├─30864 postgres: checkpointer   
           ├─30865 postgres: background writer   
           ├─30866 postgres: walwriter   
           ├─30867 postgres: autovacuum launcher   
           ├─30868 postgres: stats collector   
           ├─30869 postgres: logical replication launcher   
           └─30870 postgres: shop shop_db 218.238.107.63(60363) idle

 2월 27 02:12:49 ip-172-31-17-131.ap-northeast-2.compute.internal systemd[1]: Starting PostgreSQL database server...
 2월 27 02:12:49 ip-172-31-17-131.ap-northeast-2.compute.internal postmaster[30860]: 2021-02-27 02:12:49.615 UTC [30860] LOG:  listening on IPv4 address ... 5432
 2월 27 02:12:49 ip-172-31-17-131.ap-northeast-2.compute.internal postmaster[30860]: 2021-02-27 02:12:49.615 UTC [30860] LOG:  listening on IPv6 address ... 5432
 2월 27 02:12:49 ip-172-31-17-131.ap-northeast-2.compute.internal postmaster[30860]: 2021-02-27 02:12:49.616 UTC [30860] LOG:  listening on Unix socket "...5432"
 2월 27 02:12:49 ip-172-31-17-131.ap-northeast-2.compute.internal postmaster[30860]: 2021-02-27 02:12:49.618 UTC [30860] LOG:  listening on Unix socket "...5432"
 2월 27 02:12:49 ip-172-31-17-131.ap-northeast-2.compute.internal postmaster[30860]: 2021-02-27 02:12:49.627 UTC [30860] LOG:  redirecting log output to ...ocess
 2월 27 02:12:49 ip-172-31-17-131.ap-northeast-2.compute.internal postmaster[30860]: 2021-02-27 02:12:49.627 UTC [30860] HINT:  Future log output will ap...log".
 2월 27 02:12:49 ip-172-31-17-131.ap-northeast-2.compute.internal systemd[1]: Started PostgreSQL database server.
Hint: Some lines were ellipsized, use -l to show in full.

[ec2-user@ip-172-31-17-131 ~]$ sudo su - postgres
-bash-4.2$ psql 
psql (11.5)
Type "help" for help.

postgres=# CREATE EXTENSION pg_stat_statements;
postgres=# alter user postgres with password 'postgres';
postgres=# exit
```

pg_stat_statements 뷰는 admin 권한을 가지고 있는 유저만이 접근 가능한 시스템 뷰입니다. pgadmin 툴에서 아래와 같이 postgres 어드민 유저용 connection 을 생성한 후, postgres 유저로 로그인 합니다. 새로운 connection 을 만들기 위해서는 좌측 메뉴의 Servers(1)를 선택한 후, 팝업메유에서 Create -> Server 순으로 선택합니다.

![slowquery3-admin1](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/slowquery3-admin1.png)

Create-Server 팝업창의 General 탭의 Name 필드에 그림처럼 tf-postgres-19c-admin 로 입력한 후, 
![slowquery3-admin2](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/slowquery3-admin2.png)
Connection 탭으로 이동하여 Host name / address 필드에는 여러분들의 tf-postgres-19c EC2 인스턴스의 공인 IP를, Password 필드에는 어드민 유저 명칭과 동일하게 postgres 로 입력한 후, Save 버튼을 눌러서 설정을 저장하도록 합니다. 
![slowquery3-admin3](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/slowquery3-admin3.png)


먼저 아래의 SQL 들을 shop 유저로 로그인해서 순차적으로 실행 합니다. 
```
select b.product_id, min(a.order_no), max(a.order_no)
from tb_order a, tb_order_detail b
where a.order_no = b.order_no
  and a.member_id = 'user001'
  and a.order_price >= 10000
group by b.product_id
order by b.product_id 
limit 10 offset 0;



...
...


```

shop 유저에 의해 실행된 SQL 들의 통계정보를 조회하기 위해서 pg_stat_statements 뷰를 아래와 같이 조회합니다. 
```
select s.* 
from pg_stat_statements s, pg_shadow u
where s.userid = u.usesysid
  and s.query like '%tb_order%'
  and u.usename = 'shop';
```

![slowquery3](https://github.com/gnosia93/postgres-terraform/blob/main/performance/images/slowquery3.png)

pg_stat_statements 뷰에 대한 상세한 정보를 https://www.postgresql.org/docs/9.4/pgstatstatements.html 에서 확인하실 수 있습니다. 


### 세션 SQL 관찰 ###

pg_stat_activity 뷰를 이용하면 실시간으로 실행되는 SQL 을 권찰할 수 있습니다. 
```
SELECT current_timestamp - query_start AS runtime, datname, usename, query
FROM pg_stat_activity
WHERE state = 'active' AND current_timestamp - query_start > '3 sec'
ORDER BY 1 DESC;
```
