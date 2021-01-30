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


### 생성 데이터 확인하기 ###

sqldeveloper 를 이용하여 현재 데이터가 제대로 입력되는지 확인하는 과정입니다. 

```
SQL> select count(1) from shop.tb_product;
SQL> select count(1) from shop.tb_order;
```

