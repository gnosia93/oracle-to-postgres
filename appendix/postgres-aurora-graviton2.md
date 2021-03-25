## Performance of Amazon Aurora PostgreSQL ##

### 데이터베이스 생성 ###

아래와 같은 사양한 Aurora PostgreSQL 클러스터를 각각 생성합니다. RDS 역시 graviton2 용 인스턴스와 X86 용 인스턴스의 EBS Network 대역폭이 4xlarge 만 동일하고 다른 타입은 서로 상이한 관계로 4xlarge 에 대해 테스트 합니다.  

- r6g.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps / EBS Network 4,750 Mbps / EBS n/a IPOS (Graviton2)
- r5.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps / EBS Network 4,750 Mbps / EBS n/a IPOS (X86-64)

성능 테스트시 적용되는 PostgreSQL 데이터베이스의 파리미터 값으로 EC2 PostgreSQL 에서 적용한 값과 동일한 값을 적용합니다. wal log 관련 파리미터는 Aurora PostgreSQL 구조상 불필요한 파리미터입니다. 또한 shared buffers 는 Aurora에서는 메모리 총 사이즈가 아닌 블록수로 입력해야 합니다. 
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
    --db-cluster-identifier postgres-graviton2 \
    --engine aurora-postgresql \
    --engine-version 12.4 \
    --master-username postgres \
    --master-user-password postgres \
    --vpc-security-group-ids sg-06ad944bc6fccec5c          

$ aws rds create-db-instance \
    --db-cluster-identifier postgres-graviton2 \
    --db-instance-identifier postgres-graviton2-1 \
    --db-instance-class db.r6g.4xlarge \
    --engine aurora-postgresql \
    --db-parameter-group-name pg-aurora-postgres
    
    
$ aws rds create-db-cluster \
    --db-cluster-identifier postgres-x64 \
    --engine aurora-postgresql \
    --engine-version 12.4 \
    --master-username postgres \
    --master-user-password postgres \
    --vpc-security-group-ids sg-06ad944bc6fccec5c
    
$ aws rds create-db-instance \
    --db-cluster-identifier postgres-x64 \
    --db-instance-identifier postgres-x64-1 \
    --db-instance-class db.r5.4xlarge \
    --engine aurora-postgresql \
    --db-parameter-group-name pg-aurora-postgres
    
```

* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-parameter-group.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/modify-db-parameter-group.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-security-group.html


### RDS 엔드포인트 확인하기 ###

```
$ aws rds describe-db-instances --db-instance-identifier postgres-graviton2-1 --query DBInstances[].Endpoint.Address
[
    "postgres-graviton2-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]

$ aws rds describe-db-instances --db-instance-identifier postgres-x64-1 --query DBInstances[].Endpoint.Address
[
    "postgres-x64-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com"
]
```


### 성능 테스트 준비하기 ###

https://github.com/gnosia93/postgres-terraform/blob/main/appendix/postgres-ec2-graviton2.md 에서 생성한 cl_stress_gen 으로 로그인 한 후, 아래의 명령어를 차례로 수행한다. 

psql 클라이언트 프로램으로 postgres-graviton2-1, postgres-x64-1 에 각각 접속하여 테스트 유저와 데이터베이스 및 권한을 만든다. 

```
ubuntu@ip-172-31-45-65:~$ sudo apt-get install postgresql-client

ubuntu@ip-172-31-45-65:~$ psql -V
psql (PostgreSQL) 12.6 (Ubuntu 12.6-0ubuntu0.20.04.1)

ubuntu@ip-172-31-45-65:~$ psql -h postgres-graviton2-1.cwhptybasok6.ap-northeast-2.rds.amazonaws.com -U postgres
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
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0035s      68768      19648     9824     81.86    1637.20       0      23.09      24.43     201.85      24.83
   4   60.0192s     136234      38924    19462    162.13    3242.55       0      23.24      24.67     231.59      25.28
   8   60.0104s     271936      77696    38848    323.67    6473.39       0      23.23      24.71      31.13      25.28
  16   60.0181s     534226     152636    76318    635.78   12715.54       0      23.51      25.16      67.27      26.20
  32   60.0110s    1042160     297758   148880   1240.39   24808.14       1      23.29      25.79      53.52      27.17
  64   60.0260s    1992704     569340   284674   2371.17   47423.67       1      23.55      26.98     204.54      29.19
 128   60.0657s    2848328     813794   406908   3386.99   67741.36       5      26.08      37.76     359.23      47.47
 256   60.1230s    2975742     850180   425116   3535.03   70703.97      11      25.69      72.33     301.61     112.67
 512   60.2552s    2846704     813306   406692   3374.35   67489.71       9      27.99     151.36    1013.57     253.35
1024   60.2552s    2846704     813306   406692   3374.35   67489.71       9      27.99     151.36    1013.57     253.35
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)

* graviton2
```
thc   elaptime      reads     writes   others       tps        qps    errs        min        avg        max        p95
   2   60.0069s     290500      83000    41500    345.79    6915.70       0       4.71       5.78     228.97       6.21
   4   60.0026s     546084     156024    78012    650.06   13001.13       0       4.71       6.15     220.54       6.43
   8   60.0039s    1055376     301536   150768   1256.29   25125.79       0       4.76       6.37     225.87       7.04
  16   60.0083s    1843996     526856   263428   2194.88   43897.56       0       5.02       7.29     383.50       8.58
  32   60.0199s    2701762     771929   385967   3215.23   64304.84       1       5.14       9.95      94.93      13.22
  64   60.0322s    3078782     879634   439834   3663.08   73263.16       5       5.48      17.46     302.61      28.16
 128   60.0761s    3068072     876574   438308   3647.70   72954.97       3       6.70      35.06     420.20      58.92
 256   60.1633s    3007340     859217   429633   3570.28   71407.07       5       6.47      71.59     681.51     121.08
 512   60.2857s    2944956     841358   420738   3488.97   69783.55      14       6.28     146.24     966.40     244.38
1024   60.2857s    2944956     841358   420738   3488.97   69783.55      14       6.28     146.24     966.40     244.38
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
```




