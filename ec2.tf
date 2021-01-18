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
    user_data = <<EOF
#! /bin/bash
sudo yum install -y python37
sudo pip3 install cx_oracle
sudo -u ec2-user mkdir images
sudo -u ec2-user curl -o /home/ec2-user/images/images.tar https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/images/images.tar
sudo -u ec2-user curl -o /home/ec2-user/client.zip https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/instantclient-basic-linux.x64-21.1.0.0.0.zip
sudo -u ec2-user tar xvf /home/ec2-user/images/images.tar
sudo -u ec2-user unzip /home/ec2-user/client.zip
EOF

    tags = {
      "Name" = "tf_loadgen"
    } 
}
