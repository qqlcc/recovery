---
title: etcdctl 使用记录
date: 2022-03-28 12:40:51
sitemap: true
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

## 备份恢复  
在v2、v3数据混用的情况下，v2数据导出kv，v3使用etcd命令进行备份  
```bash
## v2数据导出
for k in $(etcdctl $param ls --recursive -p | grep -v "/$")
do
  v=$(etcdctl $param get $k)
  if [ $? -eq 0 ]; then
    value=${v//\'/\'\\\'\'}
    num=$((num+1))
    echo "ETCDCTL_API=2 etcdctl $param set $k '$value'" >> /backup_v2_.sh
  else
    rm -rf /backup_v2_.sh
    exit 1
  fi
done
## v3数据备份
etcdctl $param snapshot save /backup_v3.db 
etcdctl $param --write-out=table snapshot status /backup_v3_.db
```  

恢复数据时，先使用快照恢复v3数据，然后再将v2数据导入
```bash
etcdctl $param snapshot restore /backup_v3.db
```

