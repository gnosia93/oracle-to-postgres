resource "aws_instance" "tf_loadgen" {
    ami = data.aws_ami.amazon-linux-2.id
    associate_public_ip_address = true
    instance_type = "t2.xlarge"
    monitoring = true
    root_block_device {
        volume_size = "30"
    }
    key_name = aws_key_pair.tf_key.id
    vpc_security_group_ids = [ aws_security_group.tf_sg_pub.id ]
    user_data = <<_DATA
#! /bin/bash
sudo yum install -y python37 git
sudo pip3 install cx_oracle
sudo -u ec2-user git clone https://github.com/gnosia93/postgres-pyoracle.git /home/ec2-user/pyoracle
sudo -u ec2-user mkdir -p /home/ec2-user/pyoracle/images
sudo -u ec2-user curl -o /home/ec2-user/pyoracle/images/images.tar https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/images/images.tar
sudo -u ec2-user tar xvf /home/ec2-user/pyoracle/images/images.tar -C /home/ec2-user/pyoracle/images
sudo -u ec2-user curl -o /home/ec2-user/client.zip https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/instantclient-basic-linux.x64-21.1.0.0.0.zip
sudo -u ec2-user mkdir -p /home/ec2-user/oracle
sudo -u ec2-user unzip /home/ec2-user/client.zip -d /home/ec2-user/oracle
sudo -u ec2-user mv /home/ec2-user/oracle/instantclient_21_1 /home/ec2-user/oracle/lib
sudo cat >> /home/ec2-user/.bash_profile <<EOF
export ORACLE_HOME=/home/ec2-user/oracle
EOF
_DATA

    tags = {
      "Name" = "tf_loadgen"
    } 
}
