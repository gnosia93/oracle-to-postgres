## CPU/Memory/FileIO 성능 테스트 ##

- https://github.com/akopytov/sysbench
- https://wiki.gentoo.org/wiki/Sysbench#cite_note-1


### sysbench 설치 ###

- https://zenliu.medium.com/sysbench-1-1-installation-for-aws-ec2-instance-running-amazon-linux-a330b1cce7a7

```
[ec2-user@ip-172-31-28-94 ~]$ sudo yum -y install git gcc make automake libtool openssl-devel ncurses-compat-libs

[ec2-user@ip-172-31-28-94 ~]$ git clone https://github.com/akopytov/sysbench

[ec2-user@ip-172-31-28-94 ~]$ cd sysbench
[ec2-user@ip-172-31-28-94 sysbench]$ ./autogen.sh
[ec2-user@ip-172-31-28-94 sysbench]$ ./configure --without-mysql
[ec2-user@ip-172-31-28-94 sysbench]$ make; sudo make install

[ec2-user@ip-172-31-28-94 sysbench]$ sysbench --version
sysbench 1.1.0-bbee5d5
```

### 성능 테스트 ###

- cpu 테스트 

10만개의 소수를 계산하는 로직을 1만회 수행하는데 소요되는 시간을 계산한다. 즉 한번 실행시 10만개의 소수를 계산하는 함수를 1만번 호출하다는 의미로, elapsed time 값이 작으면 작을 수록 빠른 CPU 연산이 수행된다는 의미이다.  

https://github.com/akopytov/sysbench/issues/140
```
[ec2-user@ip-172-31-28-94 ~]$ sysbench cpu --cpu-max-prime=100000 --threads=1 --time=0 --events=10000 run
```

* graviton2

```
Prime numbers limit: 100000

Initializing worker threads...

Threads started!

CPU speed:
    events per second:   114.02

Throughput:
    events/s (eps):                      114.0161
    time elapsed:                        87.7069s
    total number of events:              10000

Latency (ms):
         min:                                    8.76
         avg:                                    8.77
         max:                                    8.79
         95th percentile:                        8.74
         sum:                                87705.26

Threads fairness:
    events (avg/stddev):           10000.0000/0.00
    execution time (avg/stddev):   87.7053/0.00
```

- X64
```

```

- fileIO
https://imcreator.tistory.com/89 
```
[ec2-user@ip-172-31-15-22]$ sysbench fileio --file-total-size=256G prepare

[ec2-user@ip-172-31-15-22]$ sysbench fileio --file-total-size=256G --file-test-mode=rndrw --time=300 run

[ec2-user@ip-172-31-15-22]$ sysbench fileio --file-total-size=256G cleanup
```

