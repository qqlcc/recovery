---
title: logrotate 使用
date: 2022-04-15 17:37:41
categories:
tags:
---

## 前言  

在使用envoy过程中 access log 越来越多，想从文档中找到答案，但没有发现相关的配置。从 github 中找到了相关的 issues：[13962](https://github.com/envoyproxy/envoy/issues/13962)、[1109](https://github.com/envoyproxy/envoy/issues/1109)，从里面内容来看，用的是 logrotate 来做日志切分。众所周知，logratate是linux下做日志切割的工具。网络上比较多介绍它的文章，这里不做过多的介绍。  

## 简介  

logratate 是根据配置的规则进行日志文件切割，想要持续的的对日志文件进行切割，那么需要crond来配合。即使用crond来定时运行logratate  

### crond  

用于定时运行 logratate，CentOS的配置在`/etc/cron.daily/`目录下
```bash
[root@localhost ~]# ls /etc/cron.daily/logrotate
/etc/cron.daily/logrotate

[root@localhost ~]# cat /etc/cron.daily/logrotate
#!/bin/sh

/usr/sbin/logrotate /etc/logrotate.conf
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
fi
exit $EXITVALUE
```

### logratate  

默认配置文件位于`/etc/logrotate.conf`，配置文件最后引用了`/etc/logrotate.d`，一般来讲，用户可将自定义配置放到该目录内  

## 测试使用  
这里在使用docker来运行centos进行测试
### 安装
首先我们安装logrotate
```bash
[root@localhost ~]# docker run --rm --name centos -it centos:centos7 bash
[root@0c4a0d0885e8 /]#  yum install logrotate -y # 安装logrotate
[root@0c4a0d0885e8 ~]# ls -la /etc/ | grep -E 'cron|logrotate'
drwxr-xr-x   2 root root     23 Apr 15 13:36 cron.daily
-rw-r--r--   1 root root    662 Jul 31  2013 logrotate.conf
drwxr-xr-x.  1 root root      6 Apr  1  2020 logrotate.d
```

安装完logrotate，可以看到创建了一个cron.daily的目录，和logrotate相关的配置及目录，这里还需要安装crond  
```bash
[root@0c4a0d0885e8 ~]# yum install cronie -y
[root@0c4a0d0885e8 ~]# ls -la /etc/ | grep cron # 安装完成可以看到cron相关的目录
-rw-------   1 root root    541 Jan 13 16:52 anacrontab
drwxr-xr-x   2 root root     21 Apr 15 13:43 cron.d
drwxr-xr-x   2 root root     23 Jun  9  2014 cron.daily
-rw-------   1 root root      0 Jan 13 16:52 cron.deny
drwxr-xr-x   2 root root     22 Apr 15 13:43 cron.hourly
drwxr-xr-x   2 root root      6 Jun  9  2014 cron.monthly
drwxr-xr-x   2 root root      6 Jun  9  2014 cron.weekly
-rw-r--r--   1 root root    451 Jun  9  2014 crontab
```

### 配置  

配置如下所示，最多3个文件，大小超过100K进行切割，保留3天前的日志  

```bash
[root@0c4a0d0885e8 ~]# cat << EOF > /etc/logrotate.d/test.conf
nomail
dateformat %s
start 0
compress
/var/log/test.log {
    rotate 3
    missingok
    copytruncate
    size 100K
    maxage 3
}
EOF
[root@0c4a0d0885e8 ~]# cp -r /etc/cron.daily/ /etc/cron.min/
[root@0c4a0d0885e8 ~]# cat << EOF > /etc/cron.d/min
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
* * * * * root run-parts /etc/cron.min
EOF
```

### 模拟日志生成  

这里简单的无限循环进行日志打印
```bash
[root@0c4a0d0885e8 ~]# while true;do echo "$(date)" >> /var/log/test.log;done
```  

### 查看日志切割状态  
```bash
[root@0c4a0d0885e8 ~]# ls -lth /var/log/
total 248K
-rw-r--r--  1 root root 101K Apr 15 14:05 test.log
-rw-r--r--  1 root root 1.2K Apr 15 14:05 test.log1650031501.gz
-rw-r--r--  1 root root 1.2K Apr 15 14:04 test.log1650031441.gz
-rw-r--r--  1 root root 6.6K Apr 15 14:03 test.log1650031381.gz
[root@0c4a0d0885e8 ~]# ls -lth /var/log/
total 180K
-rw-r--r--  1 root root  75K Apr 15 14:06 test.log
-rw-r--r--  1 root root  865 Apr 15 14:06 test.log1650031561.gz
-rw-r--r--  1 root root 1.2K Apr 15 14:05 test.log1650031501.gz
-rw-r--r--  1 root root 1.2K Apr 15 14:04 test.log1650031441.gz
```  
从日志切割记录来看，保留了3个，符合配置规则  

## 容器化实践  

可参考 [docker-logrotate](https://github.com/qqlcc/docker-logrotate) 

### 配置
![](https://limpair.nos-eastchina1.126.net/images/logrotate/logrotate-conf-1.png)

### 效果  
![](https://limpair.nos-eastchina1.126.net/images/logrotate/logrotate-sample-1.png)


## 参考文档  

[1] [cron-in-docker](https://blog.thesparktree.com/cron-in-docker)
[2] [logrotate](https://linux.die.net/man/8/logrotate)