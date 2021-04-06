## Performance of Amazon Aurora MySQL ##

### 데이터베이스 생성 ###

이번 챕터에서는 graviton2(r6g.) 와 x64(r5.) 를 대상으로 그 사이즈가 2x ~ 16x 사이에 있는 인스턴스를 대상으로 성능테스트를 수행합니다. 
성능 테스트시 적용되는 Aurora MySQL 데이터베이스의 파리미터 값은 다음과 같습니다. 운영 환경에서 쓰레드 구조로 동작하는 MySQL 의 경우 통상 physical memory 의 최대 75% 까지 innodb_buffer_pool 을 설정하나, 이번 테스트에서는 40GB 만 설정합니다. 
```
[mysql.conf]
  innodb_buffer_pool_size = 42949672960      -- byte 단위로 설정 (40GB)
  query_cache_type = 0                       -- query cache disable
  max_connections = 2000
```
* https://aws.amazon.com/ko/premiumsupport/knowledge-center/low-freeable-memory-rds-mysql-mariadb/
* https://aws.amazon.com/ko/blogs/database/best-practices-for-amazon-aurora-mysql-database-configuration/
* https://www.chriscalender.com/temporary-files-binlog_cache_size-and-row-based-binary-logging/

데이터베이스를 생성하기 위해 아래의 스크립트를 순차적으로 실행합니다. (2xlarge ~ 16xlarge 까지 테스트할 예정이므로, 인스턴스 사이즈에 맞게 아래 스크립트를 변경한 후 실행합니다.)

```
$ aws rds describe-db-engine-versions --default-only --engine aurora-mysql
5.7.mysql_aurora.2.09.2

$ aws rds describe-db-engine-versions --query "DBEngineVersions[].DBParameterGroupFamily"
aurora-mysql5.7

$ aws rds create-db-parameter-group \
     --db-parameter-group-name pg-aurora-mysql \
     --db-parameter-group-family aurora-mysql5.7 \
     --description "My Aurora MySQL new parameter group"

$ aws rds modify-db-parameter-group \
    --db-parameter-group-name pg-aurora-mysql \
    --parameters "ParameterName='innodb_buffer_pool_size',ParameterValue=42949672960,ApplyMethod=pending-reboot" \
                 "ParameterName='max_connections',ParameterValue=2000,ApplyMethod=pending-reboot"  \
                 "ParameterName='query_cache_type',ParameterValue=0,ApplyMethod=pending-reboot"  

$ aws ec2 create-security-group --group-name sg_aurora_mysql --description "aurora mysql security group"
{
    "GroupId": "sg-0518761208b6e516f"
}

$ aws ec2 authorize-security-group-ingress --group-name sg_aurora_mysql --protocol tcp --port 3306 --cidr 0.0.0.0/0

$ sleep 10       #   (10초 대기)                    
                                        
$ aws rds create-db-cluster \
    --db-cluster-identifier aurora-mysql-graviton2-16x \
    --engine aurora-mysql \
    --engine-version 5.7.mysql_aurora.2.09.2 \
    --master-username myadmin \
    --master-user-password myadmin1234 \
    --vpc-security-group-ids sg-0518761208b6e516f          

$ aws rds create-db-instance \
    --db-cluster-identifier aurora-mysql-graviton2-16x \
    --db-instance-identifier aurora-mysql-graviton2-16x-1 \
    --db-instance-class db.r6g.16xlarge \
    --engine aurora-mysql \
    --db-parameter-group-name pg-aurora-mysql
    
    
$ aws rds create-db-cluster \
    --db-cluster-identifier aurora-mysql-x64-8x \
    --engine aurora-mysql \
    --engine-version 5.7.mysql_aurora.2.09.2 \
    --master-username myadmin \
    --master-user-password myadmin1234 \
    --vpc-security-group-ids sg-0518761208b6e516f
    
$ aws rds create-db-instance \
    --db-cluster-identifier aurora-mysql-x64-8x \
    --db-instance-identifier aurora-mysql-x64-8x-1 \
    --db-instance-class db.r5.8xlarge \
    --engine aurora-mysql \
    --db-parameter-group-name pg-aurora-mysql
    
```


### Aurora 엔드포인트 확인하기 ###

```
$ aws rds describe-db-instances --db-instance-identifier aurora-mysql-graviton2-8x-1 --query DBInstances[].Endpoint.Address
[
    "aurora-mysql-graviton2-8x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]

$ aws rds describe-db-instances --db-instance-identifier aurora-mysql-x64-8x-1 --query DBInstances[].Endpoint.Address
[
    "aurora-mysql-x64-8x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]
```


### 성능 테스트 준비하기 ###

https://github.com/gnosia93/postgres-terraform/blob/main/appendix/postgres-ec2-graviton2.md 에서 생성한 cl_stress_gen 으로 로그인 한 후, 아래의 명령어를 차례로 수행한다. 

mysql 클라이언로 aurora-mysql-graviton2-8x-1, aurora-mysql-x64-8x-1 에 각각 접속하여 테스트 유저와 데이터베이스 및 권한을 만든다. 

```
ubuntu@ip-172-31-45-65:~$ sudo apt-get install mysql-client

ubuntu@ip-172-31-45-65:~$ mysql -V
mysql  Ver 8.0.23-0ubuntu0.20.04.1 for Linux on x86_64 ((Ubuntu))

ubuntu@ip-172-31-45-65:~$ mysql -h aurora-mysql-x64-8x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com -u myadmin -pmyadmin1234
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 12
Server version: 5.7.12 MySQL Community Server (GPL)

Copyright (c) 2000, 2021, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> select version();
+-----------+
| version() |
+-----------+
| 5.7.12    |
+-----------+
1 row in set (0.01 sec)

mysql> show variables like 'innodb_buffer%';
+-------------------------------------+----------------+
| Variable_name                       | Value          |
+-------------------------------------+----------------+
| innodb_buffer_pool_chunk_size       | 1342177280     |
| innodb_buffer_pool_dump_at_shutdown | OFF            |
| innodb_buffer_pool_dump_now         | OFF            |
| innodb_buffer_pool_dump_pct         | 25             |
| innodb_buffer_pool_filename         | ib_buffer_pool |
| innodb_buffer_pool_instances        | 32             |
| innodb_buffer_pool_load_abort       | OFF            |
| innodb_buffer_pool_load_at_startup  | OFF            |
| innodb_buffer_pool_load_now         | OFF            |
| innodb_buffer_pool_size             | 42949672960    |
+-------------------------------------+----------------+

mysql> CREATE USER sbtest@'%' identified by 'sbtest';
Query OK, 0 rows affected (0.01 sec)

mysql> CREATE DATABASE sbtest;
Query OK, 1 row affected (0.01 sec)

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sbtest             |
| sys                |
+--------------------+
5 rows in set (0.00 sec)

mysql> GRANT ALL PRIVILEGES ON sbtest.* TO sbtest@'%';
Query OK, 0 rows affected (0.01 sec)

mysql> flush privileges;  

mysql> quit
Bye
```

성능 테스트 아래의 내용으로 perf.sh 파일을 만들고, 대상 데이터베이스의 주소를 변경한 다음 실행합니다. 
```
#! /bin/sh
TARGET_DB=aurora-mysql-graviton2-8x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com
TEST_TIME=60
TABLE_SIZE=5000000
REPORT_INTERVAL=10

# prepare
sysbench --db-driver=mysql \
--table-size=$TABLE_SIZE --tables=32 \
--threads=32 \
--mysql-host=$TARGET_DB --mysql-port=3306 \
--mysql-user=sbtest \
--mysql-password=sbtest \
--mysql-db=sbtest \
/usr/share/sysbench/oltp_read_write.lua prepare

# remove old sysbench.log
rm sysbench.log 2> /dev/null

# run
THREAD="2 4 8 16 32 64 128 256 512 1024"
printf "%4s %10s %10s %10s %8s %9s %10s %7s %10s %10s %10s %10s\n" "thc" "elaptime" "reads" "writes" "others" "tps" "qps" "errs" "min" "avg" "max" "p95"
for THREAD_COUNT in $THREAD
do
  filename=result_$THREAD_COUNT

  sysbench --db-driver=mysql --report-interval=$REPORT_INTERVAL \
  --table-size=$TABLE_SIZE --tables=32 \
  --threads=$THREAD_COUNT \
  --time=$TEST_TIME \
  --mysql-host=$TARGET_DB --mysql-port=3306 \
  --mysql-user=sbtest --mysql-password=sbtest --mysql-db=sbtest \
  --db-ps-mode=disable \
  /usr/share/sysbench/oltp_read_write.lua run | tee -a $filename >> sysbench.log

  while read line
  do
   case "$line" in
      *read:*)  read=$(echo $line | cut -d ' ' -f2) ;;
      *write:*) write=$(echo $line | cut -d ' ' -f2) ;;
      *other:*) other=$(echo $line | cut -d ' ' -f2) ;;
      *transactions:*) tps=$(echo $line | cut -d ' ' -f3 | cut -d '(' -f2) ;;
      *queries:*) qps=$(echo $line | cut -d ' ' -f3 | cut -d '(' -f2) ;;
      *ignored" "errors:*) err=$(echo $line | cut -d ' ' -f3) ;;
      *total" "time:*) ttime=$(echo $line | cut -d ' ' -f3) ;;
      *min:*)  min=$(echo $line | cut -d ' ' -f2) ;;
      *avg:*)  avg=$(echo $line | cut -d ' ' -f2) ;;
      *max:*)  max=$(echo $line | cut -d ' ' -f2) ;;
      *95th" "percentile:*) p95=$(echo $line | cut -d ' ' -f3) ;;
   esac
  done < $filename

  #echo $THREAD_COUNT $ttime $read $write $other $tps $qps $err $min $avg $max $p95 
  printf "%4s %10s %10s %10s %8s %9s %10s %7s %10s %10s %10s %10s\n" $THREAD_COUNT $ttime $read $write $other $tps $qps $err $min $avg $max $p95

done

# cleanup
sysbench --db-driver=mysql --report-interval=$REPORT_INTERVAL \
--table-size=$TABLE_SIZE --tables=32 \
--threads=1 \
--time=$TEST_TIME \
--mysql-host=$TARGET_DB --pgsql-port=5432 \
--mysql-user=sbtest --mysql-password=sbtest --mysql-db=sbtest \
/usr/share/sysbench/oltp_read_write.lua cleanup
```
MySQL 의 경우 preapred statement 에러를 방지하기 위해서 --db-ps-mode=disable 파라미터를 설정한다. prepared statment 를 disable 하지 않고 테스트하면 아래와 같이 에러가 발생하게 되고, 제대로 된 부하 테스트를 수행할 수 없게 된다. 
```
FATAL: MySQL error: 1461 "Can't create more than max_prepared_stmt_count statements (current value: 16382)"
```

### sysbench OLTP 시나리오 ##

* /usr/share/sysbench 의 oltp_common.lua 확인


### 테스트 결과 ###

* X64
 
[aurora-mysql-x64-8x-1] - cpu %
```
 thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0215s      64540      18440     9220     76.80    1536.08       0      24.59      26.04      30.33      27.17
   4   60.0117s     127232      36352    18176    151.43    3028.67       0      24.52      26.41      54.00      27.66
   8   60.0186s     248500      71000    35500    295.73    5914.70       0      24.23      27.05      55.93      28.16
  16   60.0249s     473298     135228    67614    563.20   11264.07       0      24.81      28.41      58.26      29.72
  32   60.0246s     866600     247600   123800   1031.22   20624.39       0      25.35      31.02      66.86      33.72
  64   60.0432s    1665524     475860   237930   1981.26   39625.81       2      25.51      32.29      75.78      36.89
 128   60.0386s    2993676     855318   427659   3561.38   71230.11       9      26.21      35.92      88.86      42.61
 256   60.0604s    4802518    1372113   686058   5711.13  114227.14      16      30.48      44.79     242.59      53.85
 512   60.1142s    6468910    1848153   924085   7685.52  153722.84      45      27.82      66.50     522.42      81.48
1024   60.2581s    8186276    2338772  1169411   9702.65  194068.15      57      27.24     105.17     925.32     153.02
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```


* graviton2   


[aurora-mysql-graviton2-8x-1] - cpu 73%
```
 thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0129s      61964      17704     8852     73.75    1474.98       0      25.34      27.12      31.55      27.66
   4   60.0127s     122542      35012    17506    145.85    2916.98       0      25.03      27.42      32.06      28.16
   8   60.0033s     240632      68752    34376    286.44    5728.89       0      25.29      27.93      55.13      29.19
  16   60.0196s     461566     131876    65938    549.29   10985.82       0      25.13      29.12      65.00      30.81
  32   60.0159s     835548     238728   119364    994.41   19888.28       0      25.88      32.17      70.95      34.33
  64   60.0335s    1607382     459250   229625   1912.42   38248.67       1      25.95      33.46      76.68      37.56
 128   60.0461s    2971108     848873   424437   3534.12   70684.27       7      26.81      36.20      83.68      42.61
 256   60.0802s    5032426    1437802   718904   5982.61  119656.12      14      28.96      42.75     102.21      52.89
 512   60.1298s    7313068    2089327  1044675   8686.22  173737.91      49      28.26      58.83     317.06      80.03
1024   60.2750s    8903888    2543773  1271913  10550.07  211020.57      71      30.55      96.67     571.22     132.49
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```

[aurora-postgres-graviton2-16x-1] - cpu %
```
 
```



