
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



- cpu 테스트

```
[ec2-user@ip-172-31-28-94 sysbench]$ sysbench cpu --cpu-max-prime=100000 --threads=1 run
sysbench 1.1.0-bbee5d5 (using bundled LuaJIT 2.1.0-beta3)

Running the test with following options:
Number of threads: 1
Initializing random number generator from current time


Prime numbers limit: 100000

Initializing worker threads...

Threads started!

CPU speed:
    events per second:   114.08

Throughput:
    events/s (eps):                      114.0750
    time elapsed:                        10.0022s
    total number of events:              1141

Latency (ms):
         min:                                    8.76
         avg:                                    8.77
         max:                                    8.78
         95th percentile:                        8.74
         sum:                                10001.78

Threads fairness:
    events (avg/stddev):           1141.0000/0.00
    execution time (avg/stddev):   10.0018/0.00
```

- fileIO
https://imcreator.tistory.com/89 
```
[ec2-user@ip-172-31-15-22 sysbench]$ sysbench fileio --file-total-size=8G prepare

[ec2-user@ip-172-31-15-22 sysbench]$ sysbench fileio --file-total-size=8G --file-test-mode=rndrw --time=300 run


```

