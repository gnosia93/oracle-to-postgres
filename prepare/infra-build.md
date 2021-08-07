## 인프라 구성하기 ##


### IP 설정하기 ###
워크샵에 필요한 인프라를 빌드하기 위해서 git 허브로 부터 아래와 같이 clone 받은 다음 default 부분의 IP 주소를 여러분들의 주소로 변경합니다. 
해당 정보는 테라폼에 의해 생성되는 EC2 인스턴스들의 시큐리티 그룹(tf_sg_pub) 설정시 사용되는 정보로, 모든 IP 에 대한 허용이 필요한 경우 0.0.0.0/0 으로 설정합니다. 

```
$ git clone https://github.com/gnosia93/oracle-to-postgres.git
$ cd oracle-to-postgres/
$ vi var.tf
variable "your_ip_addr" {
    type = string
    default = "218.238.107.0/24"       ## 네이버 검색창에 "내아이피" 로 검색한 후, 결과값을 CIDR 형태로 입력.
}
```

### Key paris 만들기 ###

ec2 인스턴스들에 ssh 로 로그인 하기 위해서는 Key paris 가 필요합니다. ssh-keygen 명령어를 이용하여 tf_key 라는 명칭의 키페어를 아래와 같이 만들도록 합니다. 
테라폼 내부적으로 키페어 경로를 static하게 참조하고 있으므로, 키페어의 디렉토리 경로와 명칭은 변경해서는 안됩니다.

```
$ ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/tf_key" -N ""
Generating public/private rsa key pair.
Your identification has been saved in /Users/soonbeom/.ssh/tf_key.
Your public key has been saved in /Users/soonbeom/.ssh/tf_key.pub.
The key fingerprint is:
SHA256:JRSXGGVs5XBiaubMz8xxQla/Pi5qsxv+K9Y2/VyV0QA soonbeom@f8ffc2077dc2.ant.amazon.com
The key's randomart image is:
+---[RSA 4096]----+
|        +*BoE..  |
|       ..=+* . ..|
|        =.+ . ...|
|       * =     .o|
|        S o . ...|
|         = + .  .|
|          *. .o .|
|         .=.=..o.|
|         o=Oo+..o|
+----[SHA256]-----+
```

### 테라폼으로 인프라 빌드하기 ###

테라폼 init 명령어를 이용하여 플러그인 모듈을 다운로드 받은 후, apply 명령어를 이용하여 타켓 인프라를 빌드합니다.  
[실습 아키텍처]에 표시된 항목중 마이그레이션 태스크에 해당하는 tf-task-19c를 제외한 모든 리소스가 자동으로 빌드되며, 인프라 구축 완료시 까지 약 30분이 소요됩니다.  
빌드가 완료된 경우, 아래와 같이 output 옵션을 사용하며, 생성된 EC2 인스턴스들의 공인IP 정보를 조회할 수 있습니다.  

```
$ terraform init
```

```
$ terraform apply -auto-approve
data.aws_ami.amazon-linux-2: Refreshing state...
data.aws_vpc.tf_vpc: Refreshing state...
data.aws_ami.rhel-8: Refreshing state...
data.aws_ami.ubuntu-20: Refreshing state...
null_resource.previous: Creating...
null_resource.previous: Creation complete after 0s [id=4074780709492097283]
time_sleep.wait_10_seconds: Creating...
aws_iam_role.tf_dms_service_role: Creating...
aws_iam_role.dms-vpc-role: Creating...
aws_iam_role.tf_ec2_service_role: Creating...
aws_key_pair.tf_key: Creating...
aws_security_group.tf_sg_pub: Creating...
aws_key_pair.tf_key: Creation complete after 0s [id=tf_key]
aws_security_group.tf_sg_pub: Creation complete after 1s [id=sg-00b4cc290e2517add]
aws_instance.tf_postgres_11xe: Creating...
aws_instance.tf_oracle_11xe: Creating...
aws_instance.tf_postgres_19c: Creating...
aws_instance.tf_oracle_19c: Creating...
aws_iam_role.tf_dms_service_role: Creation complete after 1s [id=tf_dms_service_role]
aws_iam_role_policy.tf_dms_service_role_policy: Creating...
aws_iam_role.dms-vpc-role: Creation complete after 1s [id=dms-vpc-role]
aws_iam_role.tf_ec2_service_role: Creation complete after 1s [id=tf_ec2_service_role]
aws_iam_role_policy.tf_dms_policy: Creating...
aws_iam_role_policy.tf_ec2_policy: Creating...
aws_iam_instance_profile.tf_ec2_profile: Creating...
aws_iam_role_policy.tf_dms_service_role_policy: Creation complete after 2s [id=tf_dms_service_role:tf_dms_service_role_policy]
aws_iam_role_policy.tf_ec2_policy: Creation complete after 2s [id=tf_ec2_service_role:tf_ec2_policy]
aws_iam_role_policy.tf_dms_policy: Creation complete after 2s [id=dms-vpc-role:tf_dms_policy]
aws_iam_instance_profile.tf_ec2_profile: Creation complete after 3s [id=tf_ec2_profile]
aws_instance.tf_loadgen: Creating...
time_sleep.wait_10_seconds: Still creating... [10s elapsed]
aws_instance.tf_oracle_19c: Still creating... [10s elapsed]
aws_instance.tf_postgres_11xe: Still creating... [10s elapsed]
aws_instance.tf_postgres_19c: Still creating... [10s elapsed]
aws_instance.tf_oracle_11xe: Still creating... [10s elapsed]
aws_instance.tf_oracle_11xe: Creation complete after 13s [id=i-066a13ebb400f9a02]
aws_dms_endpoint.tf_dms_11xe_ep_oracle: Creating...
aws_instance.tf_postgres_19c: Creation complete after 13s [id=i-06786c6c99bdb6152]
aws_dms_endpoint.tf_dms_19c_ep_postgres: Creating...
aws_instance.tf_postgres_11xe: Creation complete after 13s [id=i-0cbe48f0ecca16702]
aws_instance.tf_oracle_19c: Creation complete after 13s [id=i-0e0bbefaf5e28fd33]
aws_dms_endpoint.tf_dms_19c_ep_oracle: Creating...
aws_dms_endpoint.tf_dms_11xe_ep_postgres: Creating...
aws_instance.tf_loadgen: Still creating... [10s elapsed]
aws_dms_endpoint.tf_dms_19c_ep_postgres: Creation complete after 0s [id=tf-dms-19c-ep-postgres]
aws_dms_endpoint.tf_dms_11xe_ep_oracle: Creation complete after 0s [id=tf-dms-11xe-ep-oracle]
aws_dms_endpoint.tf_dms_11xe_ep_postgres: Creation complete after 0s [id=tf-dms-11xe-ep-postgres]
aws_dms_endpoint.tf_dms_19c_ep_oracle: Creation complete after 0s [id=tf-dms-19c-ep-oracle]
time_sleep.wait_10_seconds: Still creating... [20s elapsed]
aws_instance.tf_loadgen: Still creating... [20s elapsed]
time_sleep.wait_10_seconds: Still creating... [30s elapsed]
time_sleep.wait_10_seconds: Creation complete after 30s [id=2021-02-02T11:42:27Z]
aws_dms_replication_instance.tf_dms_11xe: Creating...
aws_dms_replication_instance.tf_dms_19c: Creating...
aws_instance.tf_loadgen: Creation complete after 25s [id=i-01414c88106f3bc9f]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [10s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [10s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [20s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [20s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [30s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [30s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [40s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [40s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [50s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [50s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [1m0s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [1m0s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [1m10s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [1m10s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [1m20s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [1m20s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [1m30s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [1m30s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [1m40s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [1m40s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [1m50s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [1m50s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [2m0s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [2m0s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [2m10s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [2m10s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [2m20s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [2m20s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [2m30s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [2m30s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [2m40s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [2m40s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [2m50s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [2m50s elapsed]
aws_dms_replication_instance.tf_dms_19c: Still creating... [3m0s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [3m0s elapsed]
aws_dms_replication_instance.tf_dms_19c: Creation complete after 3m4s [id=tf-dms-19c]
aws_dms_replication_instance.tf_dms_11xe: Still creating... [3m10s elapsed]
aws_dms_replication_instance.tf_dms_11xe: Creation complete after 3m14s [id=tf-dms-11xe]

Apply complete! Resources: 22 added, 0 changed, 0 destroyed.

Outputs:

key_pairs = tf_key
load_gen_public_ip = 3.35.37.2
oracle_11xe_public_ip = 13.124.141.251
oracle_19c_public_ip = 3.35.170.8
postgres_11xe_public_ip = 3.34.255.215
postgres_19c_public_ip = 3.36.11.115
```

```
$ terraform output
key_pairs = tf_key
load_gen_public_ip = 3.35.37.2
oracle_11xe_public_ip = 13.124.141.251
oracle_19c_public_ip = 3.35.170.8
postgres_11xe_public_ip = 3.34.255.215
postgres_19c_public_ip = 3.36.11.115
```

워크샵을 진행하는데 있어 테라폼에 대한 사전 지식을 불필요하나, 좀 더 자세한 내용이 궁금한 경우 [aws-get-started](https://learn.hashicorp.com/collections/terraform/aws-get-started) 을 통해 확인하실 수 있습니다. 

### 빌드 완료 여부 확인하기 ###

tf_oracle_19c 서버로 로그인 한 후 아래와 같이 파일의 내용이 제대로 출력되는지 확인합니다. 인프라 구성은 보통 30분 정도 소요되오니, 아래와 같이 결과 메시지를 확인한 후 이후 과정을 진행하시기 바랍니다.  
```
$ ssh -i ~/.ssh/tf_key ec2-user@3.35.170.8
The authenticity of host '3.35.170.8 (3.35.170.8)' can't be established.
ECDSA key fingerprint is SHA256:IojRVON+zk53PHmb2C6b1fHCtybJ4Q4UhE7sBG6B8OY.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '3.35.170.8' (ECDSA) to the list of known hosts.

[ec2-user@ip-172-31-1-144 ~]$ sudo su - oracle
Last login: Tue Feb  2 12:13:16 UTC 2021

[oracle@ip-172-31-1-144 ~]$ ls -la
total 28
drwx------. 4 oracle oinstall  173 Feb  2 12:13 .
drwxr-xr-x. 4 root   root       36 Feb  2 11:45 ..
-rw-r--r--. 1 oracle oinstall   18 Jun 23  2020 .bash_logout
-rw-r--r--. 1 oracle oinstall  652 Feb  2 11:46 .bash_profile
-rw-r--r--. 1 oracle oinstall  376 Jun 23  2020 .bashrc
-rw-r--r--. 1 root   root       37 Feb  2 12:13 build.result
-rw-r--r--. 1 root   root     1553 Feb  2 12:13 dbca.out
-rw-r--r--. 1 oracle oinstall  172 Feb  6  2020 .kshrc
drwxr-x---. 2 oracle oinstall   40 Feb  2 11:56 .oracle_jre_usage
-rw-r--r--. 1 root   root     1209 Feb  2 11:54 runInstaller.out
drwx------. 2 oracle oinstall    6 Feb  2 11:53 .ssh

[oracle@ip-172-31-1-144 ~]$ cat build.result 
oracle 19c installation completed...
[oracle@ip-172-31-1-144 ~]$ 
```

### 트러블 슈팅 ###

인프라 빌드시 아래와 같은 에러 메시지가 발생하는 경우 
```
aws_dms_replication_instance.tf_dms_19c: Creation complete after 3m15s [id=tf-dms-19c]

Error: Error creating IAM Role dms-vpc-role: EntityAlreadyExists: Role with name dms-vpc-role already exists.
	status code: 409, request id: 5a0635ef-981f-44cd-9fc9-80643ba1e882

  on security.tf line 23, in resource "aws_iam_role" "dms-vpc-role":
  23: resource "aws_iam_role" "dms-vpc-role" {



Error: Error creating IAM Role tf_dms_service_role: EntityAlreadyExists: Role with name tf_dms_service_role already exists.
	status code: 409, request id: 6c924d1c-1c7d-4f10-87de-b9597c21a7e0

  on security.tf line 73, in resource "aws_iam_role" "tf_dms_service_role":
  73: resource "aws_iam_role" "tf_dms_service_role" {



Error: Error creating IAM Role tf_ec2_service_role: EntityAlreadyExists: Role with name tf_ec2_service_role already exists.
	status code: 409, request id: 12cf703c-1ea3-4e80-9170-bed811149948

  on security.tf line 113, in resource "aws_iam_role" "tf_ec2_service_role":
 113: resource "aws_iam_role" "tf_ec2_service_role" {
```

```
$ aws iam delte-policy --policy-name tf_dms_policy
$ aws iam delete-role --role-name dms-vpc-role
```


