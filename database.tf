# AMI 정보를 어떻게 출력하는지 ?
data "aws_ami" "amazon-linux-2" {
    most_recent = true
    owners = [ "amazon" ]

    filter {
        name   = "owner-alias"
        values = ["amazon"]
    }

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm*"]
    }
}


# How to list the latest available RHEL images on Amazon Web Services (AWS)
# https://access.redhat.com/solutions/15356
data "aws_ami" "rhel-8" {
    most_recent = true
    owners = [ "309956199498" ]            # owner 309956199498 means redhat inc.

    #filter {
    #    name   = "owner-alias"
    #    values = ["309956199498"]
    #}

    filter {
        name   = "name"
        values = ["RHEL-8.3.0_HVM-20201031-x86*"]
    }
}


# ubuntu image for oracle 11g 
# ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20201026 (ami-007b7745d0725de95)
data "aws_ami" "ubuntu-20" {
    most_recent = true
    owners = [ "099720109477" ]

    #filter {
    #    name   = "owner-alias"
    #    values = ["amazon"]
    #}

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20201026*"]
    }
}



# postgres setup
# 서브넷을 설정하지 않으면 자동으로 매핑된다. 
resource "aws_instance" "tf_postgres" {
    ami = data.aws_ami.amazon-linux-2.id
    associate_public_ip_address = true
    instance_type = "t2.xlarge"
    monitoring = true
    root_block_device {
        volume_size = "100"
    }
    key_name = aws_key_pair.tf_key.id
    vpc_security_group_ids = [ aws_security_group.tf_sg_pub.id ]
    user_data = <<EOF
#! /bin/bash
sudo amazon-linux-extras install postgresql11 epel -y
sudo yum install postgresql-server postgresql-contrib postgresql-devel -y
sudo -u ec2-user postgres --version >> /home/ec2-user/postgres.out
sudo postgresql-setup --initdb
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo -u ec2-user ps aux | grep postgres >> /home/ec2-user/postgres.out
EOF
    tags = {
      "Name" = "tf_postgres",
      "Project" = "oracle2postgres"
    } 
}


# oracle 11xe setup
resource "aws_instance" "tf_oracle_11xe" {
    ami = data.aws_ami.ubuntu-20.id
    associate_public_ip_address = true
    instance_type = "t2.xlarge"
    monitoring = true
    root_block_device {
        volume_size = "100"
    }
    key_name = aws_key_pair.tf_key.id
    vpc_security_group_ids = [ aws_security_group.tf_sg_pub.id ]
    user_data = <<_DATA
#! /bin/bash
sudo apt update
sudo apt-get install -y alien libaio1 unixodbc net-tools

sudo cat > /sbin/chkconfig <<EOF
#!/bin/bash
# Oracle 11gR2 XE installer chkconfig hack for Ubuntu
file=/etc/init.d/oracle-xe
if [[ ! `tail -n1 $file | grep INIT` ]]; then
    echo >> $file
    echo '### BEGIN INIT INFO' >> $file
    echo '# Provides: OracleXE' >> $file
    echo '# Required-Start: $remote_fs $syslog' >> $file
    echo '# Required-Stop: $remote_fs $syslog' >> $file
    echo '# Default-Start: 2 3 4 5' >> $file
    echo '# Default-Stop: 0 1 6' >> $file
    echo '# Short-Description: Oracle 11g Express Edition' >> $file
    echo '### END INIT INFO' >> $file
fi
update-rc.d oracle-xe defaults 80 01
EOF

sudo chmod 755 /sbin/chkconfig

sudo cat > /etc/sysctl.d/60-oracle.conf <<EOF
# Oracle 11g XE kernel parameters
fs.file-max=6815744
net.ipv4.ip_local_port_range=9000 65000
kernel.sem=250 32000 100 128
kernel.shmmax=536870912
EOF

sudo service procps start
sudo touch /var/lock/subsys/listener

sudo curl -o oracle-xe_11.2.0-2_amd64.deb https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/oracle-xe_11.2.0-2_amd64.deb
sudo dpkg --install oracle-xe_11.2.0-2_amd64.deb
sudo cat > xe.rsp <<EOF
ORACLE_HTTP_PORT=8080
ORACLE_LISTENER_PORT=1521
ORACLE_PASSWORD=manager
ORACLE_CONFIRM_PASSWORD=manager
ORACLE_DBENABLE=y
EOF

sudo /etc/init.d/oracle-xe configure responseFile=xe.rsp
sudo cat > /u01/app/oracle/.bash_profile <<EOF
# Oracle Settings
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export ORACLE_SID=XE
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
export ORACLE_BASE=/u01/app/oracle
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=/u01/app/oracle/product/11.2.0/xe/bin:$PATH
EOF

sudo chown oracle:dba /u01/app/oracle/.bash_profile
_DATA
    
    tags = {
      "Name" = "tf_oracle_11xe",
      "Project" = "oracle2postgres"
    } 
}


# oracle 19c setup
# 서브넷을 설정하지 않으면 자동으로 매핑된다. 

resource "aws_instance" "tf_oracle_19c" {
    ami = data.aws_ami.rhel-8.id
    associate_public_ip_address = true
    instance_type = "t2.xlarge"
    key_name = aws_key_pair.tf_key.id
    vpc_security_group_ids = [ aws_security_group.tf_sg_pub.id ]
    user_data = <<EOF
#! /bin/bash
sudo touch /home/ec2-user/aaa.txt
EOF 

    tags = {
      "Name" = "tf_oracle_19c"
    } 
}

#
# Output Section
#
output "tf_oracle_11xe" {
    value = aws_instance.tf_oracle_11xe.id 
}

output "tf_postgres" {
    value = aws_instance.tf_postgres.id 
}

