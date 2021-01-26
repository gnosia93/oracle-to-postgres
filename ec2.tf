
// resource "aws_iam_role" "tf_ec2_service_role" {

resource "aws_instance" "tf_loadgen" {
    ami = data.aws_ami.amazon-linux-2.id
    associate_public_ip_address = true
    instance_type = "t2.xlarge"
    iam_instance_profile = aws_iam_instance_profile.tf_ec2_profile.name
    monitoring = true
    root_block_device {
        volume_size = "30"
    }
    key_name = aws_key_pair.tf_key.id
    vpc_security_group_ids = [ aws_security_group.tf_sg_pub.id ]
    user_data = <<_DATA
#! /bin/bash
sudo yum install -y python37 git telnet
sudo pip3 install cx_oracle
sudo -u ec2-user git clone https://github.com/gnosia93/postgres-pyoracle.git /home/ec2-user/pyoracle
sudo -u ec2-user mkdir -p /home/ec2-user/pyoracle/images
sudo -u ec2-user curl -o /home/ec2-user/pyoracle/images/images.tar https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/images/images.tar
sudo -u ec2-user tar xvf /home/ec2-user/pyoracle/images/images.tar -C /home/ec2-user/pyoracle/images
sudo -u ec2-user curl -o /home/ec2-user/client.zip https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/instantclient-basic-linux.x64-21.1.0.0.0.zip
sudo -u ec2-user mkdir -p /home/ec2-user/oracle
sudo -u ec2-user unzip /home/ec2-user/client.zip -d /home/ec2-user/oracle
sudo -u ec2-user mv /home/ec2-user/oracle/instantclient_21_1 /home/ec2-user/oracle/lib
sudo -u ec2-user curl -o /home/ec2-user/sqlplus.zip https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/instantclient-sqlplus-linux.x64-21.1.0.0.0.zip
sudo -u ec2-user unzip /home/ec2-user/sqlplus.zip -d /home/ec2-user/oracle/lib
sudo -u ec2-user mv /home/ec2-user/oracle/lib/instantclient_21_1/*.so /home/ec2-user/oracle/lib
sudo -u ec2-user mv /home/ec2-user/oracle/lib/instantclient_21_1/sqlplus /home/ec2-user/oracle
export ORACLE_HOME=/home/ec2-user/oracle
sudo -u ec2-user cat >> /home/ec2-user/.bash_profile <<EOF
export ORACLE_HOME=$ORACLE_HOME
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export TNS_ADMIN=$ORACLE_HOME
export PATH=$PATH:$ORACLE_HOME
EOF
sudo -u ec2-user cat > $ORACLE_HOME/tnsnames.ora <<EOF
#
# replace <your-oracle-private-ip> with oracle server private ip or dns 
# caution : 
#    if you replace <your-oracle-private-ip> with public ip, you can't connect oracle
#
xe =
    (DESCRIPTION =
        (ADDRESS_LIST =
            (ADDRESS = (PROTOCOL = TCP)(HOST = <your-oracle-private-ip>)(PORT = 1521))
        )
        (CONNECT_DATA =
            (SERVER = DEDICATED)
            (SERVICE_NAME = xe)
        )
    )

cdb1 =
    (DESCRIPTION =
        (ADDRESS_LIST =
            (ADDRESS = (PROTOCOL = TCP)(HOST = <your-oracle-private-ip>)(PORT = 1521))
        )
        (CONNECT_DATA =
            (SERVER = DEDICATED)
            (SERVICE_NAME = cdb1)
        )
    )
EOF
sudo chown ec2-user:ec2-user $ORACLE_HOME/tnsnames.ora
_DATA

    tags = {
      "Name" = "tf_loadgen",
      "Project" = "oracle2postgres"
    } 
}


output "load_gen_public_ip" {
    value = aws_instance.tf_loadgen.public_ip
}
