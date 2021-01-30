## 샘플 데이터 빌드하기 ##

오라클 데이터베이스에 샘플 데이터를 생성하기 위해서 tf_load_gen 서버로 로그인 한 후 init_11xe.sh 또는 init_19c.sh 쉘스크립트를 이용하여 데이터를 빌드합니다. 
상품을 저장하는 tb_product 테이블에는 기본적으로 1000건을 생성하게 되고, 주문의 경우 30개의 클라이언트가 각각 1000만개의 주문을 지연없이 생성합니다. 
이번 튜토리얼에서는 저장공간 제한이 있는 11xe 보다는 해당 제한이 없는 19c 데이터베이스 위주로 테스트 할 예정입니다. 
아래와 같이 init-19c.sh 을 이용하여 테스트 데이터를 생성합니다. 


### 데이터 생성하기 ###
```
$ ssh -i ~/.ssh/tf_key ec2-user@<tf_loadgen IP>
Last login: Fri Jan 29 10:50:02 2021 from 218.238.107.63

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/

[ec2-user@ip-172-31-34-59 ~]$ cd pyoracle
[ec2-user@ip-172-31-34-59 pyoracle]$ ls -la
합계 52
drwxr-xr-x 4 ec2-user ec2-user  270  1월 30 14:13 .
drwx------ 6 ec2-user ec2-user  202  1월 29 10:53 ..
drwxr-xr-x 8 ec2-user ec2-user  163  1월 27 12:22 .git
-rw-r--r-- 1 ec2-user ec2-user   12  1월 27 12:22 .gitignore
-rw-r--r-- 1 ec2-user ec2-user   21  1월 27 12:22 README.md
-rw-rw-r-- 1 ec2-user ec2-user  238  1월 30 14:13 config.ini
-rw-r--r-- 1 ec2-user ec2-user  262  1월 27 12:22 config.ini.ec2
-rw-r--r-- 1 ec2-user ec2-user  275  1월 27 12:22 config.ini.mac
-rw-r--r-- 1 ec2-user ec2-user 1091  1월 27 15:15 create-schema.sh
drwxr-xr-x 2 ec2-user ec2-user 4096  1월 27 12:22 images
-rw-r--r-- 1 ec2-user ec2-user   35  1월 27 12:22 init-11xe.sh
-rw-r--r-- 1 ec2-user ec2-user   34  1월 27 12:22 init-19c.sh
-rw-r--r-- 1 ec2-user ec2-user 3360  1월 27 12:22 oracle-schema-11xe.sql
-rw-r--r-- 1 ec2-user ec2-user 3401  1월 27 12:22 oracle-schema-19c.sql
-rw-r--r-- 1 ec2-user ec2-user 7470  1월 27 12:22 pyoracle.py

[ec2-user@ip-172-31-34-59 pyoracle]$ sh init-19c.sh 
ORACLE_DB_URL: shop/shop@172.31.3.180:1521/pdb1
DATA_PATH /home/ec2-user/pyoracle/images
PRODUCT_DESCRIPTION_HTML_PATH: /home/ec2-user/pyoracle/images/product_body.html
DEFAULT_PRODUCT_COUNT: 1000
DEFAULT_ORDER_COUNT: 10000000
NUMBER_OF_ORDER_CLIENT: 30
initilize product table... 
******
```


### Sqldeveloper로 생성 데이터 확인하기 ###

Sqldeveloper 를 실행한 후, 좌측 메뉴의 [Oracle 접속] 아이콘을 클릭한 후, 우클릭하여 나온 팝업 메뉴에서 [+ 새 접속(A)] 을 클릭합니다. 

![new](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/sqldevel-new-connection.png)

[새로 만들기/데이터베이스 접속 선택] 창에서 다음과 같이 설정하고, 아래 테스트 버튼을 눌러 접속 여부를 확인 한 후, [저장] 버튼을 클릭 합니다.  

       Name : tf_oracle-19c 
       사용자 이름 : system 
       비밀번호는 : manager 
       호스트이름 : <tf-oracle-19c EC2 인스턴스 퍼블릭 IP>
       포트 : 1521
       서비스 이름(E) : pdb1

저장이 완료 된 후, [접속] 버튼을 눌러 오라클 데이터베이스에 로그인 합니다. 

![result](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/sqldevel-new-connection-result.png)

![count](https://github.com/gnosia93/postgres-terraform/blob/main/dms/images/sqldevel-table-cnt.png)

