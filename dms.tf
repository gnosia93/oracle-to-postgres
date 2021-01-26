# 
# DMS를 위한 서브넷의 경우 설정하지 않더라도 default 라는 이름의 서브넷 그룹을 자동으로 생성해 준다. 
#
resource "aws_dms_replication_instance" "tf_dms_logm" {
    allocated_storage = 50
    apply_immediately = true
    engine_version = "3.4.3"
    multi_az = false
    publicly_accessible = true
    replication_instance_class = "dms.t3.medium"
    replication_instance_id = "tf-dms-logm"

    depends_on = [aws_iam_role.dms-vpc-role]
}

resource "aws_dms_replication_instance" "tf_dms_binr" {
    allocated_storage = 50
    apply_immediately = true
    engine_version = "3.4.3"
    multi_az = false
    publicly_accessible = true
    replication_instance_class = "dms.t3.medium"
    replication_instance_id = "tf-dms-binr"

    depends_on = [aws_iam_role.dms-vpc-role]
}

resource "aws_dms_endpoint" "tf_dms_ep_oracle_logm" {
    endpoint_id = "tf-dms-ep-oracle-logm"
    endpoint_type = "source"
    engine_name = "oracle"
    server_name = aws_instance.tf_oracle_11xe.public_dns
    database_name = "xe"                                       ## oracle sid
    username = "system"
    password = "manager"
    port = 1521
    extra_connection_attributes = ""
    ssl_mode = "none"
}

resource "aws_dms_endpoint" "tf_dms_ep_oracle_binr" {
    endpoint_id = "tf-dms-ep-oracle-binr"
    endpoint_type = "source"
    engine_name = "oracle"
    server_name = aws_instance.tf_oracle_11xe.public_dns
    database_name = "xe"                                                            ## oracle sid
    username = "system"
    password = "manager"
    port = 1521
    extra_connection_attributes = "useLogminerReader=N; useBfile=Y"
    ssl_mode = "none"
}

resource "aws_dms_endpoint" "tf_dms_ep_postgres" {
    endpoint_id = "tf-dms-ep-postgres"
    endpoint_type = "target"
    engine_name = "postgres"
    server_name = aws_instance.tf_postgres.public_dns
    database_name = "shop_db"                                                        ## database name
    username = "shop"
    password = "shop"
    port = 5432
    extra_connection_attributes = ""
    ssl_mode = "none"
}

#
# Output Section
#
output "tf_dms_logm" {
    value = aws_dms_replication_instance.tf_dms_logm.id
}

output "tf_dms_binr" {
    value = aws_dms_replication_instance.tf_dms_binr.id
}

output "tf_dms_ep_oracle_logm" {
    value = aws_dms_endpoint.tf_dms_ep_oracle_logm.server_name
}

output "tf_dms_ep_oracle_binr" {
    value = aws_dms_endpoint.tf_dms_ep_oracle_binr.server_name
}

output "tf_dms_ep_postgres" {
    value = aws_dms_endpoint.tf_dms_ep_postgres.server_name
}

