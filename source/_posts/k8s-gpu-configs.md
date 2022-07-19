---
title: K8S GPU 配置
categories:
  - kubernetes
tags:
  - kubernetes
  - k8s
  - gpu
  - docker
  - containerd
date: 2022-07-19 13:58:09
---


# NVIDIA驱动安装
以下操作在Redhat 7.6上进行，已安装好k8s并使用docker作为`contianer runtime`  

## 查看服务器的GPU信息
```bash
yum install pciutils
lspci | grep "NVIDIA"
```
## 下载对应的驱动文件
到[官网](https://www.nvidia.cn/Download/index.aspx?lang=cn)下载驱动  

## 安装驱动
redhat/centos rpm离线包安装时，需要epel提供一些必要软件  
```bash
yum install -y epel-release  
curl -OL https://cn.download.nvidia.cn/tesla/515.48.07/nvidia-driver-local-repo-rhel7-515.48.07-1.0-1.x86_64.rpm
rpm -ivh nvidia-driver-local-repo-rhel7-515.48.07-1.0-1.x86_64.rpm
yum install cuda-drivers
reboot
nvidia-smi
```

# 安装nvidia-docker  

```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
yum install -y nvidia-docker2
# 安装完成后，会把原有的配置备份，可以在原有的配置上修改添加default-runtime，然后覆盖/etc/docker/daemon.json
# 编辑 daemon.json，如果没有 default-runtime 则加入，并且添加上之前原有的配置内容。
vim /etc/docker/daemon.json
"default-runtime": "nvidia",

systemctl restart docker

docker run --rm -e NVIDIA_VISIBLE_DEVICES=all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi  
```

# 安装k8s-device-plugin  
## 部署说明  
[官方文档](https://docs.nvidia.com/datacenter/cloud-native/kubernetes/mig-k8s.html#using-mig-strategies-in-kubernetes)  
[gpu-feature-discovery](https://github.com/NVIDIA/gpu-feature-discovery)  
[k8s-device-plugin](https://github.com/NVIDIA/k8s-device-plugin)  

## 部署文件  
* 部署使用[helm chart](https://github.com/NVIDIA/k8s-device-plugin/tree/master/deployments/helm/nvidia-device-plugin)  
   ```bash
   #templates/_helpers.tpl上可能有问题，部署前可以helm template .试试看
   # 或者helm install ndp nvidia-device-plugin --dry-run
   allowPrivilegeEscalation: false
   capabilities:
     drop: ["ALL"]
   ```
* 需要最新版本[helm](https://github.com/helm/helm/releases/tag/v3.9.1)
* 所需镜像  
   ```bash 
   k8s.gcr.io/nfd/node-feature-discovery:v0.11.0
   nvcr.io/nvidia/gpu-feature-discovery:v0.6.1
   k8s.gcr.io/nfd/node-feature-discovery:v0.11.0
   nvcr.io/nvidia/k8s-device-plugin:v0.12.2
   ```
## 开始安装  
MIG_STRATEGY类型可查阅官网文档
```bash
MIG_STRATEGY=none
./helm -n nvidia-device-plugin install \
   ndp \
   --set migStrategy=${MIG_STRATEGY} \
   --set gfd.enabled=true \
   nvidia-device-plugin
```  
