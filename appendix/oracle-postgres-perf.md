## Oracle / PostgreSQL 성능 비교 ##

hammerdb(https://www.hammerdb.com/download.html) 라는 데이터베이스 성능 분석툴을 이용하여 Oracle 데이터베이스와 PostgreSQL 간의 성능을 비교하도록 하겠습니다. 


### 설치하기 ###
```
$ aws ec2 describe-instances --filters "Name=tag:Name,Values=cl_stress-gen"  --query "Reservations[].Instances[*].{InstanceId:InstanceId, PublicIpAddress:PublicIpAddress, Name:Tags[0].Value}" --output table
-------------------------------------------------------------
|                     DescribeInstances                     |
+---------------------+-----------------+-------------------+
|     InstanceId      |      Name       |  PublicIpAddress  |
+---------------------+-----------------+-------------------+
|  i-01296b0081a5a653d|  cl_stress-gen  |  3.35.131.217     |
+---------------------+-----------------+-------------------+

$ ssh -i ~/.ssh/tf_key ubuntu@3.35.131.217
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-1038-aws x86_64)

ubuntu@ip-172-31-1-64:~$ ubuntu@ip-172-31-1-64:~$ mkdir hammer; cd hammer

ubuntu@ip-172-31-1-64:~/hammer$ wget https://github.com/TPC-Council/HammerDB/releases/download/v4.0/HammerDB-4.0-Linux.tar.gz

ubuntu@ip-172-31-1-64:~/hammer$ tar xvfz HammerDB-4.0-Linux.tar.gz 

ubuntu@ip-172-31-1-64:~/hammer$ cd HammerDB-4.0/
```
