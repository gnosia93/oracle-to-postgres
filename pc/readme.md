# PC 환경설정 #

튜토리얼을 원할하게 진행하기 위해서는 여러분들이 사용하는 PC 에 아래 소트트웨어의 설치되어야 합니다.  
homebrew 는 mac 용 패키지 매니저로 테라폼, git 설치에 사용되고, JDK, apache jmeter, pgadmin 4 및 sqldeveoper 는 별도로 설치가 필요합니다.  
apache jmeter 는 웹 및 JDBC 성능 테스트용으로 사용되는 오픈 소스 소프트웨어 이며, pgadmin 4 는 웹기반의 postgresql 클라이언트 툴 그리고, sqldeveloper는 오라클용 클라이언트 통합 환경입니다.

## homebrew ##

```
$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

## 테라폼 ##

```
$ brew install terraform
$ terraform -version
Terraform v0.14.5
```

## git ##

```
$ brew install git
$ git --version
git version 2.29.1
```

## 오라클 JDK 설치(버전 11) ##

오라클 JDK 를 다운로드 받기위해서 https://www.oracle.com/kr/java/technologies/javase-jdk11-downloads.html 로 방문합니다.  
아래 리스트에서 macOS Installer 를 다운받아서 설치합니다. 이때 인스톨러를 로컬 PC 로 다운로드 받기 위해서는 오라클 로그인 계정이 필요합니다. 

![oracle-jdk](https://github.com/gnosia93/postgres-terraform/blob/main/pc/images/oracle-jdk11.png)

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
# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

export SPARK_HOME=/Users/soonbeom/bigdata/spark
export ZEPPELIN_HOME=/Users/soonbeom/bigdata/zeppelin
export PATH=$PATH:$SPARK_HOME/sbin:$SPARK_HOME/bin
export PATH=$PATH:$ZEPPELIN_HOME/bin

complete -C /usr/local/bin/terraform terraform
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

## apache jmeter ##

https://jmeter.apache.org/download_jmeter.cgi 로 방문하여 아파치 jmeter 최신 바이너리를 다운로드 받아 설치합니다. (현재 기준 apache-jmeter-5.4.1.zip 이 최신버전입니다.)

![jmeter](https://github.com/gnosia93/postgres-terraform/blob/main/pc/images/apache-jmeter.png)

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

![jmeter-exec](https://github.com/gnosia93/postgres-terraform/blob/main/pc/images/apache-jmeter-exec.png)


## Pgadmin4 (옵션) ##



## SQLDeveloper (옵션) ##
