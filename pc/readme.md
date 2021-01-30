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
아래 리스트에서 macOS Installer 를 다운받아서 설치합니다. 인스톨로러르 다운로드 받기 위해서는 오라클 로그인 계정이 필요합니다. 

![oracle-jdk](https://github.com/gnosia93/postgres-terraform/blob/main/pc/images/oracle-jdk11.png)


## apache jmeter ##




## Pgadmin4 (옵션) ##



## SQLDeveloper (옵션) ##
