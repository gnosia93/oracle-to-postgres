## 데이터 생성하기 ##

오라클 데이터베이스를 초기화하기 위해 init_11xe.sh 과 init_19c.sh 프로그램을 실행한다. 

상품 정보를 저장하는 tb_product 테이블에는 1000건을 저장하게되고, 주문 데이터를 생성하기 위해 50개의 클라이언트가 만들어지고, 클라이언트당 최대 100만개의 주문 정보를 생성하게 된다. 

[샘플 데이터 생성 예제]
```
[ec2-user@ip-172-31-37-6 pyoracle]$ pwd
/home/ec2-user/pyoracle
[ec2-user@ip-172-31-37-6 pyoracle]$ sh init_11xe.sh
ORACLE_DB_URL: shop/shop@172.31.32.20:1521/xe
DATA_PATH" /home/ec2-user/pyoracle/images
PRODUCT_DESCRIPTION_HTML_PATH: /home/ec2-user/pyoracle/images/product_body.html
DEFAULT_PRODUCT_COUNT: 1000
DEFAULT_ORDER_COUNT: 1000000
loading product table... 
```

오라클 서버로 로그인해서 데이터가 제대로 생성되는 지 확인한다 . 

[데이터 생성 확인]
```
SQL> select count(1) from shop.tb_product;
SQL> select count(1) from shop.tb_order;
```

