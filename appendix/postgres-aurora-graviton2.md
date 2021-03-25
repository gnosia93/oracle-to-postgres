### 데이터베이스 생성 ###

- r6g.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps 4,750 Mbps / EBS IO1 30,000 IPOS (Graviton2)
- r5.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps 4,750 Mbps / EBS IO1 30,000 IPOS (X86-64)

```
$ aws rds describe-db-engine-versions --default-only --engine aurora-postgresql

$ aws rds create-db-instance \
    --db-instance-identifier postgres-graviton2 \
    --db-instance-class db.r6g.4xlarge \
    --engine aurora-postgresql \
    --engine-version 12.4 \
    --master-username postgres \
    --master-user-password postgres 
```

* https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CreateDBInstance.html
