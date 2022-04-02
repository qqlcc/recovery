---
title: etcdctl 使用记录
date: 2022-03-28 12:40:51
categories:
- Linux
- etcd
tags:  
- etcdctl
---

## API 2
默认情况下`etcdctl`使用的是`v3`版本的`API`，如果需要使用`v2`版本的API，那么就需要指定环境变量`ETCDCTL_API=2`，如下所示
```bash
export ETCDCTL_API=2
etcdctl ls /
# or
ETCDCTL_API=2 etcdctl ls /
```
### 查看集群状态  
```bash
ETCDCTL_API=2 etcdctl member list
```

## API 3
在使用`APIv3`时，只获取key需要指定参数，如下所示
```bash
export prefix_keys='--prefix --keys-only'
etcdctl get / $prefix_keys
# or
etcdctl get / --prefix --keys-only
```
### 查看集群状态
```
export ETCDCTL_ENDPOINTS=https://10.95.35.76:12379,https://10.95.35.77:12379,https://10.95.35.78:12379
export ETCDCTL_CA_FILE=/etc/ssl/private/ca.crt
export ETCDCTL_CERT_FILE=/etc/ssl/private/etcd/peer.crt
export ETCDCTL_KEY_FILE=/etc/ssl/private/etcd/peer.key
etcdctl endpoint status --write-out=table
etcdctl endpoint health
```