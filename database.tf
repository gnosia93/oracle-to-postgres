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
    instance_type = "c5.4xlarge"
    monitoring = true
    root_block_device {
        volume_size = "300"
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
    instance_type = "c5.4xlarge"
    monitoring = true
    root_block_device {
        volume_size = "300"
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
sudo echo "oracle" | passwd oracle --stdin

_DATA
    
    tags = {
      "Name" = "tf_oracle_11xe",
      "Project" = "oracle2postgres"
    } 
}


# oracle 19c setup
# 서브넷을 설정하지 않으면 자동으로 매핑된다. 
# cloud init output 확인
# sudo tail -f /var/log/cloud-init-output.log
# 데이터베이스 설치에 20분 정도가 소요된다.

resource "aws_instance" "tf_oracle_19c" {
    ami = data.aws_ami.rhel-8.id
    associate_public_ip_address = true
    instance_type = "c5.4xlarge"
    monitoring = true
    root_block_device {
        volume_size = "300"
    }
    key_name = aws_key_pair.tf_key.id
    vpc_security_group_ids = [ aws_security_group.tf_sg_pub.id ]
    user_data = <<_DATA
#! /bin/bash
sudo dnf install -y https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64/getPackage/oracle-database-preinstall-19c-1.0-1.el8.x86_64.rpm
sudo cat > /etc/selinux/config <<EOF
SELINUX=permissive
SELINUXTYPE=targeted
EOF
sudo setenforce Permissive

sudo mkdir -p /app/oracle/product/19c/dbhome
sudo mkdir -p /app/oradata
sudo chown -R oracle:oinstall /app
sudo chmod -R 775 /app

sudo cat >> /home/oracle/.bash_profile <<EOF
# Oracle Settings
export TMP=/tmp
export TMPDIR=\$TMP

#export ORACLE_HOSTNAME=ol8-19.localdomain
export ORACLE_UNQNAME=cdb1
export ORACLE_BASE=/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/19c/dbhome
export ORA_INVENTORY=/app/oraInventory
export ORACLE_SID=cdb1
export PDB_NAME=pdb1
export DATA_DIR=/app/oradata

export PATH=/usr/sbin:/usr/local/bin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$PATH

export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
EOF
sudo chown oracle:oinstall /home/oracle/.bash_profile
sudo echo "oracle" | passwd oracle --stdin

sudo chmod u+w /etc/sudoers
sudo cat >> /etc/sudoers <<EOF
oracle        ALL=(ALL)       NOPASSWD: ALL
EOF
sudo chmod u-w /etc/sudoers

export ORACLE_UNQNAME=cdb1
export ORACLE_BASE=/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19c/dbhome
export ORA_INVENTORY=/app/oraInventory
export ORACLE_SID=cdb1
export PDB_NAME=pdb1
export DATA_DIR=/app/oradata
export PATH=/usr/sbin:/usr/local/bin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

sudo -u oracle curl -o $ORACLE_HOME/oracle.zip https://demo-database-postgres.s3.ap-northeast-2.amazonaws.com/LINUX.X64_193000_db_home.zip
sudo -u oracle unzip -o $ORACLE_HOME/oracle.zip -d $ORACLE_HOME
sudo -u oracle rm $ORACLE_HOME/oracle.zip

sudo -u oracle echo "CV_ASSUME_DISTID=OEL7.6" >> $ORACLE_HOME/cv/admin/cvu_config
sudo -u oracle $ORACLE_HOME/runInstaller -ignorePrereq -waitforcompletion -silent      \
    -responseFile $ORACLE_HOME/install/response/db_install.rsp              \
    oracle.install.option=INSTALL_DB_SWONLY                                 \
    ORACLE_HOSTNAME=$ORACLE_HOSTNAME                                        \
    UNIX_GROUP_NAME=oinstall                                                \
    INVENTORY_LOCATION=$ORA_INVENTORY                                       \
    SELECTED_LANGUAGES=en,en_GB                                             \
    ORACLE_BASE=$ORACLE_BASE                                                \
    oracle.install.db.InstallEdition=EE                                     \
    oracle.install.db.OSDBA_GROUP=dba                                       \
    oracle.install.db.OSBACKUPDBA_GROUP=dba                                 \
    oracle.install.db.OSDGDBA_GROUP=dba                                     \
    oracle.install.db.OSKMDBA_GROUP=dba                                     \
    oracle.install.db.OSRACDBA_GROUP=dba                                    \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false                              \
    DECLINE_SECURITY_UPDATES=true > home/oracle/runInstaller.out

/app/oraInventory/orainstRoot.sh
/app/oracle/product/19c/dbhome/root.sh

su - oracle -c "lsnrctl start"
sudo -u oracle $ORACLE_HOME/bin/dbca -silent -createDatabase                          \
     -templateName General_Purpose.dbc                                      \
     -gdbname $ORACLE_SID -sid  $ORACLE_SID -responseFile NO_VALUE          \
     -characterSet AL32UTF8                                                 \
     -sysPassword SysPassword1                                              \
     -systemPassword SysPassword1                                           \
     -createAsContainerDatabase true                                        \
     -numberOfPDBs 1                                                        \
     -pdbName $PDB_NAME                                                     \
     -pdbAdminPassword PdbPassword1                                         \
     -databaseType MULTIPURPOSE                                             \
     -memoryMgmtType auto_sga                                               \
     -totalMemory 2000                                                      \
     -storageType FS                                                        \
     -datafileDestination "$DATA_DIR"                                       \
     -redoLogFileSize 50                                                    \
     -emConfiguration NONE                                                  \
     -ignorePreReqs > /home/oracle/dbca.out

su - oracle <<EOF
sqlplus "/ as sysdba" <<EOS
alter system set db_create_file_dest='$DATA_DIR';
alter pluggable database $PDB_NAME save state;
exit;
EOS
EOF

echo "oracle 19c installation completed..."
_DATA 

    tags = {
      "Name" = "tf_oracle_19c",
      "Project" = "oracle2postgres"
    } 
}

#
# Output Section
#
output "oracle_11xe_public_ip" {
    value = aws_instance.tf_oracle_11xe.public_ip 
}

output "oracle_19c_public_ip" {
    value = aws_instance.tf_oracle_19c.public_ip
}

output "postgres_public_ip" {
    value = aws_instance.tf_postgres.public_ip
}

