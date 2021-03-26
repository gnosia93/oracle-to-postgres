
```
$ aws rds describe-db-engine-versions --default-only --engine aurora-postgresql
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
