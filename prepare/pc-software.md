
## PC 환경설정 ##

튜토리얼을 원할하게 진행하기 위해서는 여러분들의 PC에 아래에 나열된 소프트웨어가 사전에 설치되어져 있어야 합니다. 설치가 필요한 소프트웨어 목록 중 오라클사에서 제공하는 JDK, sqldeveoper 는 오라클 계정 등록이 필요합니다. 

개별 사이트로 접속하여 필요한 소프트웨어를 다운로드 받을 것을 권장하나, 여의치 않은 경우 http://ec2-3-37-255-59.ap-northeast-2.compute.amazonaws.com 에서 한꺼번에 다운로드 받으실 수 있습니다. 


### homebrew ###

homebrew 는 mac 용 소프트웨어 패키지 매니저로 테라폼, git 설치에 사용됩니다.
```
$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

### terraform ###

```
$ brew install terraform
$ terraform -version
Terraform v0.14.5
```

### git ###

```
$ brew install git
$ git --version
git version 2.29.1
```

### 오라클 JDK 설치(버전 11) ###

오라클 JDK 를 다운로드 받기위해서 https://www.oracle.com/kr/java/technologies/javase-jdk11-downloads.html 로 방문합니다.  
아래 리스트에서 macOS Installer 를 다운받아서 설치합니다. 이때 인스톨러를 로컬 PC 로 다운로드 받기 위해서는 오라클 로그인 계정이 필요합니다. 

![oracle-jdk](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/images/oracle-jdk11.png)

macOS Installer 를 설치한 이후, JDK Home 의 대한 변경이 필요합니다. 우선 java_home 명령어를 이용하여 현재 PC 에 설치된 오라클 JDK 버전을 조회한 후, bash profile 에 새롭게 설치된 JDK 11 에 대한 환경 변수를 등록합니다. 

```
$ /usr/libexec/java_home -V
Matching Java Virtual Machines (2):
    11.0.10, x86_64:	"Java SE 11.0.10"	/Library/Java/JavaVirtualMachines/jdk-11.0.10.jdk/Contents/Home
    1.8.0_231, x86_64:	"Java SE 8"	/Library/Java/JavaVirtualMachines/jdk1.8.0_231.jdk/Contents/Home


$ cd 
$ vi .bash_profile

export ORACLE_HOME=/Users/soonbeom/oracle
export TNS_ADMIN=$ORACLE_HOME

export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.10.jdk/Contents/Home               <--- JAVA_HOME 환경변수 추가
export PATH=$PATH:/usr/local/Cellar/maven/3.6.3_1/bin

...
```

JAVA_HOME 환경 변수를 bash 프로파일에 등록한 후, 터미널 환경에서 환경변수 값과 java 의 버전을 아래와 같이 확인합니다. 
```
$ . .bash_profile
$ env | grep JAVA_HOME
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-11.0.10.jdk/Contents/Home

$ java -version
java version "11.0.10" 2021-01-19 LTS
Java(TM) SE Runtime Environment 18.9 (build 11.0.10+8-LTS-162)
Java HotSpot(TM) 64-Bit Server VM 18.9 (build 11.0.10+8-LTS-162, mixed mode)
```

### apache jmeter ###

apache jmeter 는 웹 및 JDBC 성능 테스트용으로 사용되는 오픈 소스 소프트웨어입니다.
https://jmeter.apache.org/download_jmeter.cgi 로 방문하여 아파치 jmeter 최신 바이너리를 다운로드 받아 설치합니다. (현재 기준 apache-jmeter-5.4.1.zip 이 최신버전입니다.)

![jmeter](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/images/apache-jmeter.png)


jmeter 를 실행하기 전에 bin 디렉토리 밑에 있는 jmeter.sh 파일에 다음 항목 추가하여 JVM 에 할당되는 메모리 사이즈를 1GB 로 증가시키고, 출력되는 언어를 영어로 수정합니다. (jmeter.sh 파일의 33번째 라인에 추가) 
```
export JVM_ARGS="-Duser.language=en -Duser.region=EN -Xms1g -Xmx1g"
```

터미널 상에서 아래와 같이 다운로드 받아 설치된 아파치 jmeter 를 실행해 봅니다. 
```
$ cd apache-jmeter-5.4.1
$ bin/jmeter.sh 
================================================================================
Don't use GUI mode for load testing !, only for Test creation and Test debugging.
For load testing, use CLI Mode (was NON GUI):
   jmeter -n -t [jmx file] -l [results file] -e -o [Path to web report folder]
& increase Java Heap to meet your test requirements:
   Modify current env variable HEAP="-Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m" in the jmeter batch file
Check : https://jmeter.apache.org/usermanual/best-practices.html
================================================================================
```

![jmeter-exec](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/images/apache-jmeter-exec.png)


### Pgadmin4 ###

pgadmin4 는 웹기반의 postgresql 용 SQL 클라이언트 입니다. 
https://www.pgadmin.org/download/pgadmin-4-macos/ 로 이동하여 mac 용 pgadmin4 를 다운로드 받은 후, 로컬 PC 에 설치합니다. 

![pgadmin4](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/images/pgadmin4.png)


### SQLDeveloper ###

sqldeveloper는 오라클사에서 개발된 개발자용 SQL 클라이언트 입니다. 
https://www.oracle.com/tools/downloads/sqldev-downloads.html 로 이동하여 mas 용 sqldeveoper를 다운로드 받은 후, 로컬 PC 에 설치합니다. 

![sqldeveloper](https://github.com/gnosia93/postgres-terraform/blob/main/prepare/images/sqldeveloper.png)



