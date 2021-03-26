## Performance of Amazon Aurora PostgreSQL ##

### 데이터베이스 생성 ###

아래와 같은 스팩으로 Aurora PostgreSQL 클러스터를 각각 생성합니다. Aurora 역시 graviton2 용 인스턴스와 X86 용 인스턴스의 EBS Network 대역폭이 4xlarge 만 동일하고 다른 타입은 서로 상이한 관계로 4xlarge 에 대해 테스트 합니다.  

- r6g.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps / EBS Network 4,750 Mbps / EBS n/a IPOS (Graviton2)
- r5.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps / EBS Network 4,750 Mbps / EBS n/a IPOS (X86-64)

성능 테스트시 적용되는 Aurora PostgreSQL 데이터베이스의 파리미터 값은 EC2 PostgreSQL 에서 적용한 값과 동일한 값을 적용합니다. wal log 관련 파리미터는 Aurora PostgreSQL 분산 스토리지 구조상 불필요한 파리미터입니다. 또한 shared buffers 는 Aurora에서는 메모리 총 사이즈가 아닌 블록수로 입력해야 합니다. 
```
[postgresql.conf]
  shared_buffers = 5242880      -- 8K 블록 이므로 40GB 로 설정됨
  max_wal_size = 30GB           -- Aurora 에서는 지원하지 않는 파라미터
  min_wal_size = 30GB           -- Aurora 에서는 지원하지 않는 파라미터
  max_connections = 2000
  listen_addresses = '*'        -- default / 수정 불필요
```

아래의 스크립트를 순차적으로 실행합니다. 

```
$ aws rds describe-db-engine-versions --default-only --engine aurora-postgresql
12.4

$ aws rds describe-db-engine-versions --query "DBEngineVersions[].DBParameterGroupFamily"
aurora-postgresql12

$ aws rds create-db-parameter-group \
    --db-parameter-group-name pg-aurora-postgres \
    --db-parameter-group-family aurora-postgresql12 \
    --description "My Aurora PostgreSQL new parameter group"

$ aws rds modify-db-parameter-group \
    --db-parameter-group-name pg-aurora-postgres \
    --parameters "ParameterName='shared_buffers',ParameterValue=5242880,ApplyMethod=pending-reboot" \
                 "ParameterName='max_connections',ParameterValue=2000,ApplyMethod=pending-reboot"   

$ aws ec2 create-security-group --group-name sg_aurora_postgres --description "aurora postgres security group"
{
    "GroupId": "sg-06ad944bc6fccec5c"
}

$ aws ec2 authorize-security-group-ingress --group-name sg_aurora_postgres --protocol tcp --port 5432 --cidr 0.0.0.0/0

$ sleep 10       #   (10초 대기)                    
                                        
$ aws rds create-db-cluster \
    --db-cluster-identifier aurora-postgres-graviton2-12x \
    --engine aurora-postgresql \
    --engine-version 12.4 \
    --master-username postgres \
    --master-user-password postgres \
    --vpc-security-group-ids sg-06ad944bc6fccec5c          

$ aws rds create-db-instance \
    --db-cluster-identifier aurora-postgres-graviton2-12x \
    --db-instance-identifier aurora-postgres-graviton2-12x-1 \
    --db-instance-class db.r6g.12xlarge \
    --engine aurora-postgresql \
    --db-parameter-group-name pg-aurora-postgres
    
    
$ aws rds create-db-cluster \
    --db-cluster-identifier aurora-postgres-x64-12x \
    --engine aurora-postgresql \
    --engine-version 12.4 \
    --master-username postgres \
    --master-user-password postgres \
    --vpc-security-group-ids sg-06ad944bc6fccec5c
    
$ aws rds create-db-instance \
    --db-cluster-identifier aurora-postgres-x64-12x \
    --db-instance-identifier aurora-postgres-x64-12x-1 \
    --db-instance-class db.r5.12xlarge \
    --engine aurora-postgresql \
    --db-parameter-group-name pg-aurora-postgres
    
```

* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-parameter-group.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/modify-db-parameter-group.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-security-group.html


### Aurora 엔드포인트 확인하기 ###

```
$ aws rds describe-db-instances --db-instance-identifier aurora-postgres-graviton2-8x-1 --query DBInstances[].Endpoint.Address
[
    "aurora-postgres-graviton2-8x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]

$ aws rds describe-db-instances --db-instance-identifier aurora-postgres-x64-8x-1 --query DBInstances[].Endpoint.Address
[
    "postgres-x64-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]
```


### 성능 테스트 준비하기 ###

https://github.com/gnosia93/postgres-terraform/blob/main/appendix/postgres-ec2-graviton2.md 에서 생성한 cl_stress_gen 으로 로그인 한 후, 아래의 명령어를 차례로 수행한다. 

psql 클라이언트 프로램으로 aurora-postgres-graviton2-8x-1, aurora-postgres-x64-8x-1 에 각각 접속하여 테스트 유저와 데이터베이스 및 권한을 만든다. 

```
ubuntu@ip-172-31-45-65:~$ sudo apt-get install postgresql-client

ubuntu@ip-172-31-45-65:~$ psql -V
psql (PostgreSQL) 12.6 (Ubuntu 12.6-0ubuntu0.20.04.1)

ubuntu@ip-172-31-45-65:~$ psql -h aurora-postgres-graviton2-8x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com -U postgres
Password for user postgres: 
psql (12.6 (Ubuntu 12.6-0ubuntu0.20.04.1), server 12.4)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

postgres=> select version();
                                                   version                                                   
-------------------------------------------------------------------------------------------------------------
 PostgreSQL 12.4 on aarch64-unknown-linux-gnu, compiled by aarch64-unknown-linux-gnu-gcc (GCC) 7.4.0, 64-bit
(1 row)

postgres=> CREATE USER sbtest WITH PASSWORD 'sbtest';
CREATE ROLE
postgres=> CREATE DATABASE sbtest;
CREATE DATABASE
postgres=> GRANT ALL PRIVILEGES ON DATABASE sbtest TO sbtest;
GRANT
postgres=> \q
```



성능 테스트 방법은 기존과 동일하다. [테스트 자동화하기] 섹션에 나온대로 perf.sh 파일을 만들고, 대상 데이터베이스의 주소를 변경한 다음 실행한다. 

### 테스트 결과 ###

* X64

[aurora-postgres-x64-4x-1]
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0094s      68488      19568     9784     81.52    1630.37       0      23.36      24.53      92.17      24.83
   4   60.0239s     136024      38864    19432    161.86    3237.30       0      23.42      24.71      56.82      25.28
   8   60.0118s     270466      77276    38638    321.91    6438.25       0      23.17      24.85      69.25      25.28
  16   60.0178s     533344     152384    76192    634.73   12694.59       0      23.38      25.20      68.64      25.74
  32   60.0238s    1039444     296978   148492   1236.86   24738.15       3      23.88      25.87      54.42      27.17
  64   60.0224s    1983254     566643   283323   2360.08   47201.61       0      23.98      27.11      69.24      29.19
 128   60.0694s    2864008     818273   409151   3405.45   68110.12       4      25.97      37.56      86.69      47.47
 256   60.1269s    2909424     831238   415646   3456.11   69123.93       6      26.08      73.98     526.86     114.72
 512   60.2796s    2850694     814442   407262   3377.68   67556.81      11      28.07     151.17    1143.25     253.35
1024   60.5652s    3042144     869089   434641   3587.34   71753.57      23      29.48     283.81    1820.13     450.77
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```

[aurora-postgres-x64-8x-1] - cpu 70%
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0055s     295330      84380    42190    351.54    7030.86       0       4.76       5.69     197.98       6.09
   4   60.0025s     611436     174696    87348    727.85   14557.05       0       4.50       5.49     203.49       5.88
   8   60.0053s    1137752     325071   162537   1354.31   27086.27       0       4.62       5.91     283.94       6.55
  16   60.0094s    2092720     597918   298960   2490.87   49817.67       1       4.91       6.42      59.79       7.43
  32   60.0122s    3479910     994253   497131   4141.76   82836.06       3       5.00       7.72     311.40       8.90
  64   60.0216s    5036206    1438892   719468   5993.07  119863.41       7       5.24      10.67     369.07      13.46
 128   60.0597s    5327574    1522136   761100   6335.82  126717.81       5       5.38      20.18     602.48      36.24
 256   60.1093s    5799934    1657082   828582   6891.78  137838.92      11       8.78      37.10     600.59      92.42
 512   60.1933s    5812170    1660526   830350   6896.41  137936.28      27       8.97      74.07     832.09     186.54
1024   60.4032s    6097602    1741915   871223   7209.43  144206.39      60      11.07     141.36    1075.93     267.41
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```

[aurora-postgres-x64-12x-1] - cpu 0%
```
```





* graviton2
 
[aurora-postgres-graviton2-4x-1] 
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0035s     271670      77620    38810    323.39    6467.80       0       4.65       6.18      50.15       6.67
   4   60.0022s     552020     157720    78860    657.13   13142.54       0       4.55       6.09      50.25       6.67
   8   60.0034s    1025304     292944   146472   1220.50   24410.02       0       4.84       6.55      51.97       7.17
  16   60.0060s    1841420     526119   263061   2191.89   43837.90       0       4.92       7.30     101.59       8.28
  32   60.0208s    2688910     768256   384134   3199.90   63997.98       0       5.21      10.00      97.05      13.46
  64   60.0532s    3132934     895121   447563   3726.27   74525.77       1       5.75      17.16     122.15      26.68
 128   60.0727s    3154830     901364   450696   3751.03   75022.13       5       6.36      34.09     210.45      55.82
 256   60.1492s    3035340     867211   433635   3604.34   72088.82       7       6.92      70.91     454.75     121.08
 512   60.3207s    2970884     848767   424445   3517.68   70357.12      12       6.84     145.10     907.14     240.02
1024   60.3483s    3394300     969713   484931   4016.95   80347.29      28       7.72     254.14     673.59     369.77
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```

[aurora-postgres-graviton2-8x-1] - cpu 70%
```
 thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0124s      81648      23328    11664     97.18    1943.55       0      19.12      20.58     164.17      20.74
   4   60.0035s     159040      45440    22720    189.32    3786.36       0      19.41      21.13     210.65      21.50
   8   60.0046s     314328      89808    44904    374.16    7483.25       0      19.31      21.38      66.33      21.50
  16   60.0212s     620620     177320    88660    738.56   14771.11       0      19.07      21.66      67.79      22.28
  32   60.0297s    1227870     350818   175410   1460.98   29219.83       1      19.40      21.90      75.22      23.10
  64   60.0347s    2350614     671598   335802   2796.62   55933.23       3      19.79      22.88     204.06      24.83
 128   60.0736s    4257694    1216465   608247   5062.24  101246.94       7      20.10      25.26     432.69      29.19
 256   60.1324s    5110840    1460203   730135   6070.61  121415.45      11      21.28      42.11     776.03      81.48
 512   60.3072s    5710376    1631445   815807   6762.86  135264.88      26      21.89      75.44    1868.66     193.38
1024   60.5939s    6608854    1888003   944235   7789.33  155805.54      64      23.17     130.49    2083.99     308.84
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```



