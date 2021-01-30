## 테라폼으로 인프라 빌드하기 ##

워크샵에 필요한 인프라를 빌드하기 위해서 git 허브로 부터 아래와 같이 clone 받은 다음 default 부분의 IP 주소를 여러분들의 주소로 변경합니다. 
해당 정보는 테라폼에 의해 생성되는 EC2 인스턴스들의 시큐리티 그룹(tf_sg_pub) 설정시 사용되는 정보로, 모든 IP 에 대한 허용이 필요한 경우 0.0.0.0/0 으로 설정합니다. 

```
$ git clone https://github.com/gnosia93/postgres-terraform.git
$ cd postgres-terraform/
$ vi var.tf
variable "your_ip_addr" {
    type = string
    default = "218.238.107.0/24"       ## 네이버 검색창에 "내아이피" 로 검색한 후, 결과값을 CIDR 형태로 입력.
}
```
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

테라폼 init 명령어를 이용하여 플러그인 모듈을 다운로드 받은 후, apply 명령어를 이용하여 타켓 인프라를 빌드합니다.  
[실습 아키텍처]에 표시된 항목중 마이그레이션 태스크에 해당하는 tf-task-19c를 제외한 모든 리소스가 자동으로 빌드되며, 인프라 구축 완료시 까지 약 30분이 소요됩니다.    
빌드가 완료된 경우, 아래와 같이 output 옵션을 사용하며, 생성된 EC2 인스턴스들의 공인IP 정보를 조회할 수 있습니다.  

```
$ terraform init

$ terraform apply -auto-approve

$ terraform output
```

워크샵을 진행하는데 있어 테라폼에 대한 사전 지식을 불필요하나, 좀 더 자세한 내용이 궁금한 경우 [aws-get-started](https://learn.hashicorp.com/collections/terraform/aws-get-started) 을 통해 확인하실 수 있습니다. 
