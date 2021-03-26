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
    --db-cluster-identifier aurora-postgres-graviton2-4x \
    --engine aurora-postgresql \
    --engine-version 12.4 \
    --master-username postgres \
    --master-user-password postgres \
    --vpc-security-group-ids sg-06ad944bc6fccec5c          

$ aws rds create-db-instance \
    --db-cluster-identifier aurora-postgres-graviton2-4x \
    --db-instance-identifier aurora-postgres-graviton2-4x-1 \
    --db-instance-class db.r6g.4xlarge \
    --engine aurora-postgresql \
    --db-parameter-group-name pg-aurora-postgres
    
    
$ aws rds create-db-cluster \
    --db-cluster-identifier aurora-postgres-x64-4x \
    --engine aurora-postgresql \
    --engine-version 12.4 \
    --master-username postgres \
    --master-user-password postgres \
    --vpc-security-group-ids sg-06ad944bc6fccec5c
    
$ aws rds create-db-instance \
    --db-cluster-identifier aurora-postgres-x64-4x \
    --db-instance-identifier aurora-postgres-x64-4x-1 \
    --db-instance-class db.r5.4xlarge \
    --engine aurora-postgresql \
    --db-parameter-group-name pg-aurora-postgres
    
```

* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-parameter-group.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/modify-db-parameter-group.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-security-group.html


### Aurora 엔드포인트 확인하기 ###

```
$ aws rds describe-db-instances --db-instance-identifier aurora-postgres-graviton2-4x-1 --query DBInstances[].Endpoint.Address
[
    "aurora-postgres-graviton2-4x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]

$ aws rds describe-db-instances --db-instance-identifier aurora-postgres-x64-4x-1 --query DBInstances[].Endpoint.Address
[
    "aurora-postgres-x64-4x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]
```


### 성능 테스트 준비하기 ###

https://github.com/gnosia93/postgres-terraform/blob/main/appendix/postgres-ec2-graviton2.md 에서 생성한 cl_stress_gen 으로 로그인 한 후, 아래의 명령어를 차례로 수행한다. 

psql 클라이언트 프로램으로 aurora-postgres-graviton2-8x-1, aurora-postgres-x64-8x-1 에 각각 접속하여 테스트 유저와 데이터베이스 및 권한을 만든다. 

```
ubuntu@ip-172-31-45-65:~$ sudo apt-get install postgresql-client

ubuntu@ip-172-31-45-65:~$ psql -V
psql (PostgreSQL) 12.6 (Ubuntu 12.6-0ubuntu0.20.04.1)

ubuntu@ip-172-31-45-65:~$ psql -h aurora-postgres-graviton2-4x-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com -U postgres
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

[aurora-postgres-x64-4x-1] - cpu 90%
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0095s      82320      23520    11760     97.98    1959.64       0      19.10      20.41     235.45      20.74
   4   60.0147s     162848      46528    23264    193.81    3876.29       0      19.29      20.64     251.62      21.11
   8   60.0204s     323792      92512    46256    385.33    7706.53       0      19.23      20.76      34.50      21.50
  16   60.0155s     638652     182472    91236    760.09   15201.71       0      19.55      21.05      33.94      21.89
  32   60.0152s    1234198     352626   176314   1468.86   29377.53       1      19.87      21.78      64.16      23.10
  64   60.0165s    2302412     657821   328917   2740.07   54802.85       5      20.37      23.35      68.86      25.28
 128   60.0697s    2933518     838136   419078   3488.08   69762.88       4      21.45      36.67     334.34      48.34
 256   60.1194s    2947084     842004   421024   3501.31   70027.47       4      22.57      73.02     430.06     112.67
 512   60.2576s    2826614     807560   403830   3350.42   67010.79       8      25.11     152.42    1081.66     257.95
1024   60.4985s    3041430     868859   434559   3590.40   71815.82      26      25.35     283.65    1903.82     419.45
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```

[aurora-postgres-x64-8x-1] - cpu 83%
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

[aurora-postgres-x64-12x-1] - cpu 85%
```
 thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0186s      79912      22832    11416     95.10    1902.03       0      19.52      21.03      46.74      22.69
   4   60.0061s     161000      46000    23000    191.64    3832.85       0      19.45      20.87      26.02      22.28
   8   60.0142s     320964      91704    45852    382.00    7640.02       0      19.34      20.94      62.74      21.89
  16   60.0070s     641396     183256    91628    763.46   15269.19       0      19.08      20.95      23.74      21.89
  32   60.0129s    1252468     357845   178925   1490.66   29813.52       1      19.48      21.46      65.69      23.10
  64   60.0147s    2418514     690991   345503   2878.31   57567.97       6      19.66      22.23      64.31      24.38
 128   60.0350s    4455388    1272954   636484   5300.69  106015.97       7      20.18      24.13      69.55      27.66
 256   60.0773s    7416794    2118992  1059570   8817.42  176358.01      32      20.55      29.01     767.85      31.94
 512   60.2131s    8967616    2562054  1281152  10637.21  212752.80      29      22.72      48.01    1107.89     106.75
1024   60.4027s    9786924    2795885  1398323  11571.59  231459.80      94      22.92      88.09    4213.54     219.36
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```

[aurora-postgres-x64-16x-1] - cpu 79%
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0150s      82040      23440    11720     97.64    1952.80       0      19.13      20.48     250.78      20.74
   4   60.0190s     163576      46736    23368    194.67    3893.34       0      19.42      20.55      23.42      21.11
   8   60.0049s     323036      92296    46148    384.53    7690.52       0      19.60      20.80      24.45      21.50
  16   60.0212s     636286     181796    90898    757.20   15143.97       0      19.27      21.13      24.79      21.89
  32   60.0211s    1238538     353865   176935   1473.88   29477.94       1      19.48      21.71     272.19      22.69
  64   60.0306s    2402946     686550   343278   2859.08   57182.40       3      19.78      22.38     188.87      24.38
 128   60.0368s    4334442    1238392   619210   5156.63  103135.02       8      20.22      24.81     321.43      29.19
 256   60.0835s    7281694    2080413  1040261   8656.00  173127.72      26      21.25      29.54    1136.28      31.94
 512   60.1786s   10102596    2886285  1443319  11990.27  239817.42      40      23.24      42.60     616.10      84.47
1024   60.3610s   11086908    3167290  1584048  13117.85  262385.87      97      23.59      77.68    1452.74     183.21
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2) 
```






* graviton2   
[aurora-postgres-graviton2-4x-1] - cpu 86%
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0022s     297528      85008    42504    354.18    7083.58       0       4.67       5.65     227.64       6.09
   4   60.0073s     533008     152288    76144    634.44   12688.83       0       4.79       6.30     227.42       6.67
   8   60.0024s    1086834     310524   155262   1293.77   25875.38       0       4.77       6.18     265.42       6.79
  16   60.0099s    1886948     539122   269566   2245.91   44918.81       2       4.74       7.12     299.82       8.43
  32   60.0162s    2776060     793155   396583   3303.85   66077.23       1       5.19       9.68      63.16      12.98
  64   60.0481s    3111724     889050   444542   3701.35   74027.53       2       5.79      17.28     309.36      27.17
 128   60.0605s    3133578     895288   447662   3726.50   74531.89       6       6.40      34.32     426.51      53.85
 256   60.1518s    3028914     865380   432714   3596.57   71933.17       6       7.02      71.07     620.57     116.80
 512   60.3154s    2998072     856543   428317   3550.16   71007.30      14       7.60     143.76    1797.06     231.53
1024   60.4985s    3041430     868859   434559   3590.40   71815.82      26      25.35     283.65    1903.82     419.45
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```

[aurora-postgres-graviton2-8x-1] - cpu 71%
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

[aurora-postgres-graviton2-12x-1] - cpu 60%
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0087s      80444      22984    11492     95.75    1915.01       0      19.39      20.89     244.81      21.11
   4   60.0066s     158480      45280    22640    188.64    3772.83       0      19.89      21.20     263.54      21.50
   8   60.0073s     316344      90384    45192    376.55    7530.91       0      19.66      21.24      64.07      21.89
  16   60.0133s     624288     178368    89184    743.02   14860.37       0      19.68      21.53      66.66      22.28
  32   60.0106s    1224874     349964   174982   1457.89   29157.84       0      19.60      21.95      68.12      23.10
  64   60.0158s    2334794     667076   333544   2778.67   55574.30       3      19.91      23.03     217.68      25.28
 128   60.0637s    4368546    1248141   624079   5194.89  103899.95       7      20.19      24.62     285.14      28.16
 256   60.1222s    7418894    2119619  1059879   8813.63  176276.81      14      20.92      29.00     516.98      40.37
 512   60.2770s    8718934    2490975  1245637  10331.13  206633.60      37      22.23      49.39    1481.43     118.92
1024   60.4425s    9802828    2800427  1400607  11582.84  231683.26      89      22.09      87.80    2092.49     227.40
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```

[aurora-postgres-graviton2-16x-1] - cpu 77%
```
 thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0247s      66864      19104     9552     79.57    1591.30       0      23.88      25.13     231.25      25.28
   4   60.0037s     134876      38536    19268    160.55    3211.06       0      23.62      24.91      67.45      25.28
   8   60.0126s     266350      76100    38050    317.01    6340.19       0      23.25      25.23      70.77      25.74
  16   60.0139s     529984     151424    75712    630.77   12615.46       0      23.28      25.36      70.55      26.20
  32   60.0178s    1037862     296532   148266   1235.16   24703.10       0      23.50      25.90      73.26      27.17
  64   60.0321s    2011128     574604   287304   2392.83   47857.23       2      23.80      26.74     210.17      28.16
 128   60.0703s    3806950    1087682   543850   4526.53   90533.27       9      24.15      28.25     117.05      31.37
 256   60.0861s    6490918    1854474   927286   7715.52  154319.71      31      24.63      33.15     484.57      37.56
 512   60.2523s    9920666    2834304  1417318  11759.82  235210.18      46      25.96      43.37     639.85      81.48
1024   60.5612s   11616122    3318432  1659674  13698.33  274001.12     116      26.38      74.20    1963.98     179.94
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```

