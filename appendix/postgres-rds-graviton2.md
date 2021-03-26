## Performance of Amazon RDS PostgreSQL ##

### 데이터베이스 생성 ###

아래와 같은 사양한 RDS PostgreSQL 데이터베이스를 각각 생성합니다. RDS 역시 graviton2 용 인스턴스와 X86 용 인스턴스의 EBS Network 대역폭이 4xlarge 만 동일하고 다른 타입은 서로 상이한 관계로 4xlarge 에 대해 테스트 합니다.  

- r6g.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps / EBS Network 4,750 Mbps / EBS n/a IPOS (Graviton2)
- r5.4xlarge: 16 vCPU / 128 GB / Network 최대 10 Gbps / EBS Network 4,750 Mbps / EBS n/a IPOS (X86-64)

성능 테스트시 적용되는 PostgreSQL 데이터베이스의 파리미터 값으로 EC2 PostgreSQL 에서 적용한 값과 동일한 값을 적용합니다. wal log 관련 파리미터는 Aurora PostgreSQL 구조상 불필요한 파리미터입니다. 또한 shared buffers 는 Aurora에서는 메모리 총 사이즈가 아닌 블록수로 입력해야 합니다. 
```
[postgresql.conf]
  shared_buffers = 5242880      -- 8K 블록 이므로 40GB 로 설정됨
  max_wal_size = 30720          -- MB 단위로 지정(30GB)
  min_wal_size = 30720B         -- MB 단위로 지정(30GB)
  max_connections = 2000
  listen_addresses = '*'        -- default / 수정 불필요
```

아래의 스크립트를 순차적으로 실행합니다. 


```
$ aws rds describe-db-engine-versions --engine postgres
12.4

$ aws rds describe-db-engine-versions --query "DBEngineVersions[].DBParameterGroupFamily" | grep postgres
postgres12

$ aws rds create-db-parameter-group \
    --db-parameter-group-name pg-rds-postgres \
    --db-parameter-group-family postgres12 \
    --description "My RDS PostgreSQL new parameter group"

$ aws rds modify-db-parameter-group \
    --db-parameter-group-name pg-rds-postgres \
    --parameters "ParameterName='shared_buffers',ParameterValue=5242880,ApplyMethod=pending-reboot" \
                 "ParameterName='max_connections',ParameterValue=2000,ApplyMethod=pending-reboot" \
                 "ParameterName='max_wal_size',ParameterValue=30720,ApplyMethod=pending-reboot"  \
                 "ParameterName='min_wal_size',ParameterValue=30720,ApplyMethod=pending-reboot"  


$ aws ec2 create-security-group --group-name sg_rds_postgres --description "rds postgres security group"
{
    "GroupId": "sg-0976d787e21a0eb07"
}

$ aws ec2 authorize-security-group-ingress --group-name sg_rds_postgres --protocol tcp --port 5432 --cidr 0.0.0.0/0

$ sleep 10       #   (10초 대기)                    

# RDS 의 그라비톤2는 지원하지 않으므로 x86 만 생성한다. 

$ aws rds create-db-instance \
    --db-instance-identifier rds-postgres-x64 \
    --db-instance-class db.r5.4xlarge \
    --engine postgres \
    --engine-version 12.4 \
    --db-parameter-group-name pg-rds-postgres \
    --master-username postgres \
    --master-user-password postgres \
    --iops 30000 \
    --storage-type io1 \
    --vpc-security-group-ids sg-0976d787e21a0eb07 \
    --no-multi-az \
    --no-deletion-protection
        
```
