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

## 오라클 JDK 설치(버전 10 이상) ##

오라클 JDK 를 다운로드 받기위해서 https://www.oracle.com/kr/java/technologies/javase-jdk11-downloads.html 로 방문합니다.  
아래 리스트에서 macOS Installer 를 다운받아서 설치합니다. 이때 인스톨러를 로컬 PC 로 다운로드 받기 위해서는 오라클 로그인 계정이 필요합니다. 

![oracle-jdk](https://github.com/gnosia93/postgres-terraform/blob/main/pc/images/oracle-jdk11.png)

macOS Installer 를 설치한 이후, JDK Home 의 대한 변경이 필요합니다. 우선 아래의 명령어를 수행하여 현재 PC 에 설치된 오라클 JDK 버전을 조회한 후, bash profile 에 새롭게 설치된 JDK 11 에 대한 환경 변수를 등록합니다. 

```
$ /usr/libexec/java_home -V
Matching Java Virtual Machines (2):
    11.0.10, x86_64:	"Java SE 11.0.10"	/Library/Java/JavaVirtualMachines/jdk-11.0.10.jdk/Contents/Home
    1.8.0_231, x86_64:	"Java SE 8"	/Library/Java/JavaVirtualMachines/jdk1.8.0_231.jdk/Contents/Home


$ cd 
$ vi .bash_profile
```



## apache jmeter ##




## Pgadmin4 (옵션) ##



## SQLDeveloper (옵션) ##
