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
    --db-cluster-identifier aurora-mysql-x64-16x \
    --engine aurora-mysql \
    --engine-version 5.7.mysql_aurora.2.09.2 \
    --master-username myadmin \
    --master-user-password myadmin1234 \
    --vpc-security-group-ids sg-0518761208b6e516f
    
$ aws rds create-db-instance \
    --db-cluster-identifier aurora-mysql-x64-16x \
    --db-instance-identifier aurora-mysql-x64-16x-1 \
    --db-instance-class db.r5.16xlarge \
    --engine aurora-mysql \
    --db-parameter-group-name pg-aurora-mysql
    
```


### Aurora 엔드포인트 확인하기 ###

```
$ aws rds describe-db-instances --db-instance-identifier aurora-mysql-graviton2-16x-1 --query DBInstances[].Endpoint.Address
[
    "aurora-mysql-graviton2-16x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]

$ aws rds describe-db-instances --db-instance-identifier aurora-mysql-x64-16x-1 --query DBInstances[].Endpoint.Address
[
    "aurora-mysql-x64-16x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]
```


### 성능 테스트 준비하기 ###

https://github.com/gnosia93/postgres-terraform/blob/main/appendix/postgres-ec2-graviton2.md 에서 생성한 cl_stress_gen 으로 로그인 한 후, 아래의 명령어를 차례로 수행한다. 

psql 클라이언트 프로램으로 aurora-postgres-graviton2-8x-1, aurora-postgres-x64-8x-1 에 각각 접속하여 테스트 유저와 데이터베이스 및 권한을 만든다. 

```
ubuntu@ip-172-31-45-65:~$ sudo apt-get install mysql-client

ubuntu@ip-172-31-45-65:~$ mysql -V
mysql  Ver 8.0.23-0ubuntu0.20.04.1 for Linux on x86_64 ((Ubuntu))

ubuntu@ip-172-31-45-65:~$ mysql -h aurora-mysql-graviton2-16x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com -u myadmin -pmyadmin1234
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
TARGET_DB=aurora-mysql-graviton2-16x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com
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


### 테스트 결과 ###

* X64
 
[aurora-postgres-x64-16x-1] - cpu 29%
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0181s      78302      22372    11186     93.19    1863.73       0      20.33      21.46      35.72      22.28
   4   60.0056s     153496      43856    21928    182.71    3654.24       0      20.16      21.89      43.41      22.69
   8   60.0157s     295708      84488    42244    351.93    7038.66       0      19.80      22.73      45.52      23.95
  16   60.0069s     560602     160172    80086    667.29   13345.82       0      20.37      23.97      51.90      25.74
  32   60.0149s    1016372     290390   145195   1209.62   24192.71       1      20.84      26.45      58.54      29.19
  64   60.0737s    1387694     396484   198242   1649.95   32999.07       0      25.28      38.75     210.69      53.85
 128   60.1138s    1399888     399966   199986   1663.34   33266.78       0      26.26      76.87     378.15     137.35
 256   60.2353s    1353212     386624   193322   1604.62   32092.70       1      25.98     159.20    1027.78     257.95
 512   60.6957s    1341690     383328   191676   1578.86   31578.01       3      26.92     321.90    1037.54     467.30
1024   60.4985s    3041430     868859   434559   3590.40   71815.82      26      25.35     283.65    1903.82     419.45
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```


* graviton2   


[aurora-postgres-graviton2-16x-1] - cpu 20%
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0086s      62818      17948     8974     74.77    1495.42       0      24.80      26.75      57.04      28.16
   4   60.0133s     123788      35368    17684    147.33    2946.61       0      24.68      27.15      31.70      28.67
   8   60.0166s     239176      68336    34168    284.65    5692.96       0      24.81      28.10      53.32      29.72
  16   60.0328s     454580     129880    64940    540.86   10817.16       0      24.86      29.58      59.36      31.37
  32   60.0202s     817404     233544   116772    972.75   19454.98       0      26.27      32.89      87.58      36.24
  64   60.0737s    1387694     396484   198242   1649.95   32999.07       0      25.28      38.75     210.69      53.85
 128   60.1138s    1399888     399966   199986   1663.34   33266.78       0      26.26      76.87     378.15     137.35
 256   60.2353s    1353212     386624   193322   1604.62   32092.70       1      25.98     159.20    1027.78     257.95
 512   60.6957s    1341690     383328   191676   1578.86   31578.01       3      26.92     321.90    1037.54     467.30
1024   60.4985s    3041430     868859   434559   3590.40   71815.82      26      25.35     283.65    1903.82     419.45
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```


