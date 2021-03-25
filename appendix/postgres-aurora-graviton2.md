### 데이터베이스 생성 ###

- r6g.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps 4,750 Mbps / EBS IO1 30,000 IPOS (Graviton2)
- r5.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps 4,750 Mbps / EBS IO1 30,000 IPOS (X86-64)

성능 테스트시 적용되는 PostgreSQL 데이터베이스의 파리미터 값입니다. 
```
[postgresql.conf]
  shared_buffers = 5242880      -- 8K 블록 이므로 40GB 로 설정됨
  max_wal_size = 30GB           -- Aurora 에서는 지원하지 않는 파라미터
  min_wal_size = 30GB           -- Aurora 에서는 지원하지 않는 파라미터
  max_connections = 2000
  listen_addresses = '*'        -- default / 수정 불필요
```


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
                    
$ aws rds create-db-cluster \
    --db-cluster-identifier postgres-graviton2 \
    --engine aurora-postgresql \
    --engine-version 12.4 \
    --master-username postgres \
    --master-user-password postgres \
    --db-cluster-parameter-group-name pg-aurora-postgres
    
    // --db-subnet-group-name <blah> \

$ aws rds create-db-instance \
    --db-cluster-identifier postgres-graviton2 \
    --db-instance-identifier postgres-graviton2-1 \
    --db-instance-class db.r6g.4xlarge \
    --engine aurora-postgresql    
```

* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/create-db-parameter-group.html
* https://docs.aws.amazon.com/cli/latest/reference/rds/modify-db-parameter-group.html


