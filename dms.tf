resource "null_resource" "previous" {}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [null_resource.previous]

  create_duration = "30s"
}



# 
# DMS를 위한 서브넷의 경우 설정하지 않더라도 default 라는 이름의 서브넷 그룹을 자동으로 생성해 준다. 
#
resource "aws_dms_replication_instance" "tf_dms_11xe" {
    allocated_storage = 50
    apply_immediately = true
    engine_version = "3.4.3"
    multi_az = false
    publicly_accessible = true
    replication_instance_class = "dms.t3.medium"
    replication_instance_id = "tf-dms-11xe"

    depends_on = [time_sleep.wait_30_seconds]       # delay resource creation for 30 sec for waiting role/dms-vpc-role creation
}

resource "aws_dms_replication_instance" "tf_dms_19c" {
    allocated_storage = 50
    apply_immediately = true
    engine_version = "3.4.3"
    multi_az = false
    publicly_accessible = true
    replication_instance_class = "dms.t3.medium"
    replication_instance_id = "tf-dms-19c"

    depends_on = [time_sleep.wait_30_seconds]
}

resource "aws_dms_endpoint" "tf_dms_11xe_ep_oracle" {
    endpoint_id = "tf-dms-11xe-ep-oracle"
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

# log minor is not supported in oracle PDB environment.
# end point must be configured with binary reader mode
resource "aws_dms_endpoint" "tf_dms_19c_ep_oracle" {
    endpoint_id = "tf-dms-19c-ep-oracle"
    endpoint_type = "source"
    engine_name = "oracle"
    server_name = aws_instance.tf_oracle_19c.public_dns
    database_name = "pdb1"                                        ## oracle sid
    username = "system"
    password = "manager"
    port = 1521
    extra_connection_attributes = "useLogminerReader=N; useBfile=Y"
    ssl_mode = "none"
}

resource "aws_dms_endpoint" "tf_dms_11xe_ep_postgres" {
    endpoint_id = "tf-dms-11xe-ep-postgres"
    endpoint_type = "target"
    engine_name = "postgres"
    server_name = aws_instance.tf_postgres_11xe.public_dns
    database_name = "shop_db"                                      ## database name
    username = "shop"
    password = "shop"
    port = 5432
    extra_connection_attributes = ""
    ssl_mode = "none"
}

resource "aws_dms_endpoint" "tf_dms_19c_ep_postgres" {
    endpoint_id = "tf-dms-19c-ep-postgres"
    endpoint_type = "target"
    engine_name = "postgres"
    server_name = aws_instance.tf_postgres_19c.public_dns
    database_name = "shop_db"                                      ## database name
    username = "shop"
    password = "shop"
    port = 5432
    extra_connection_attributes = ""
    ssl_mode = "none"
}

#
# Output Section
#
/*
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
*/
