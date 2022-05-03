---
title: Podman on MacOS
date: 2022-05-02 12:00:00
sitemap: true
categories:
- Linux
- Containers
tags:
- podman
- ubuntu
- fedora
- docker
---

MacOS 下均是使用remote来连接vm来使用podman。我们可以使用vm管理软件来创建vm，这里介绍使用multipass和podman machine。

## 使用 Podman machine
 
配置前需要准备一些依赖
* [fedora qemu](https://getfedora.org/en/coreos/download?tab=metal_virtualized&stream=next&arch=x86_64) 镜像
* [podman](https://github.com/containers/podman/releases)  
* [gvproxy](https://github.com/containers/gvisor-tap-vsock/releases)
* [qemu](https://github.com/qemu/qemu)  

### 安装依赖  
fedora qemu 镜像，可提前准备，也可以在安装时让其自动下载  
```bash
mkdir fedora-coreos
cd fedora-coreos
curl -L 'https://builds.coreos.fedoraproject.org/prod/streams/next/builds/36.20220426.1.0/x86_64/fedora-coreos-36.20220426.1.0-qemu.x86_64.qcow2.xz' -o fedora-coreos-36.20220426.1.0-qemu.x86_64.qcow2.xz
```

获取podman二进制文件  
```bash
curl -L 'https://github.com/containers/podman/releases/download/v4.0.3/podman-remote-release-darwin_amd64.zip' -o podman-remote-release-darwin_amd64.zip
unzip podman-remote-release-darwin_amd64.zip
sudo cp podman-4.0.3/usr/bin/podman /usr/local/bin/podman
```

获取gvproxy二进制文件  
```bash
curl -L 'https://github.com/containers/gvisor-tap-vsock/releases/download/v0.3.0/gvproxy-darwin' -o gvproxy
sudo cp gvproxy /usr/local/bin/gvproxy
```

安装qemu  
```bash
brew install qemu
```

### 创建machine  
使用`podman machine init`进行初始化，可以使用`podman machine init --help`查看可用的参数  
`podman machine`只能同时运行一个vm  
```bash  
podman machine init --cpus 3 --disk-size 50 --memory 3072 --image-path ~/fedora-coreos/fedora-coreos-36.20220426.1.0-qemu.x86_64.qcow2.xz  
podman machine start # 启动默认vm
podman machine ls # 查看已有vm
```

初始化完成后，可以看看podman的配置是否正常  
```bash
podman system connection ls
podman version
```

## 使用 Multipass  
>Multipass 是一种在 Linux、macOS 和 Windows 上快速生成云式 Ubuntu VM 的工具。  

下载[multipass](https://github.com/canonical/multipass/releases/download/v1.9.0-rc/multipass-1.9.0-rc.557+gc2561306.mac-Darwin.pkg)  


### 配置vm 
初始化vm  
```bash
multipass launch -n podman -c 3 -m 3G -d 50G 22.04
```

如果vm不能访问互联网，尝试修改一下DNS，参考[using-a-custom-dns](https://multipass.run/docs/using-a-custom-dns)
其他问题参考[troubleshooting-networking-on-macos](https://multipass.run/docs/troubleshooting-networking-on-macos)
```bash
multipass shell podman
vim /etc/netplan/50-cloud-init.yaml
# 修改完成后，运行一下，然后敲一下回车
sudo netplan try
```

Ubuntu 22.04需要为sshd添加支持的`PubkeyAcceptedKeyTypes`的算法  
```bash  
echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >>/etc/ssh/sshd_config
systemctl restart sshd
```

### 配置podman  
已经记录podman3、podman4的安装方式，可根据喜好安装配置  

#### podman3  
ubuntu 22.04默认支持Podman v3 LTS版本，安装参考以下命令
```bash
sudo su
sed -i 's?archive.ubuntu.com?mirrors.aliyun.com?g'  /etc/apt/sources.list
sed -i 's?security.ubuntu.com?mirrors.aliyun.com?g'  /etc/apt/sources.list
apt-get update
apt-get -y upgrade
apt-get -y install podman
```

#### podman4
ubuntu 22.04 没有podman4的软件包，可以通过debain的[Experimental 源](https://wiki.debian.org/DebianExperimental)获取  
```bash
sed -i 's?archive.ubuntu.com?mirrors.aliyun.com?g'  /etc/apt/sources.list
sed -i 's?security.ubuntu.com?mirrors.aliyun.com?g'  /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138 0E98404D386FA1D9
echo 'deb http://deb.debian.org/debian experimental main' >> /etc/apt/sources.list.d/debian-experimental.list
apt-get update
apt-get -y upgrade
apt-get -t experimental -y install podman
```

#### 通过socket连接到podman  
给vm添加ssh公钥
```bash
echo 'macos本地的公钥' >> /root/.ssh/authorized_keys
```

podman3的API版本较低，客户端版本也需要降低，需要下载podman3的客户端  
```bash
curl -L https://github.com/containers/podman/releases/download/v3.4.4/podman-remote-release-darwin.zip -o podman-remote-release-darwin.zip
unzip podman-remote-release-darwin.zip
cp podman-3.4.4/podman /usr/local/bin/podman3  
```

然后添加远端连接
**以下命令用的IP记得改成你VM实际的IP**
```bash
podman system connection add podman3 --identity ~/.ssh/id_rsa ssh://root@192.168.64.2/run/podman/podman.sock
podman system connection default podman3
podman3 version
```

**podman4**  
```bash
podman system connection add podman4 --identity ~/.ssh/id_rsa ssh://root@192.168.64.4/run/podman/podman.sock
podman system connection default podman4
podman version
```

## 使用podman  
用以上方式安装好podman后，可以进行一些配置，如本地镜像仓库，镜像加速等  

### 信任镜像仓库  
本地镜像仓库一般使用自签证书，信任本地仓库配置如下  
```bash
cat << EOF >> /etc/containers/registries.conf.d/001-192.168.110.35-insecure.conf
[[registry]]
location="192.168.110.35"
prefix="192.168.110.35"
insecure=true
EOF
```

### 镜像加速  
国内下载比较慢，我们一般会配置加速，参考如下  
```bash
cat << EOF >> /etc/containers/registries.conf.d/002-mirrors.conf
[[registry]]
prefix="docker.io"
location="docker.m.daocloud.io"

[[registry]]
prefix="cr.l5d.io"
location="l5d.m.daocloud.io"

[[registry]]
prefix="docker.elastic.co"
location="elastic.m.daocloud.io"

[[registry]]
prefix="gcr.io"
location="gcr.m.daocloud.io"

[[registry]]
prefix="k8s.gcr.io"
location="k8s-gcr.m.daocloud.io"

[[registry]]
prefix="mcr.microsoft.com"
location="mcr.m.daocloud.io"

[[registry]]
prefix="nvcr.io"
location="nvcr.m.daocloud.io"

[[registry]]
prefix="quay.io"
location="quay.m.daocloud.io"

[[registry]]
prefix="registry.jujucharms.com"
location="jujucharms.m.daocloud.io"

[[registry]]
prefix="rocks.canonical.com"
location="rocks-canonical.m.daocloud.io"
EOF
```

### 测试镜像拉取  
```bash
➜  ~ podman pull 192.168.110.35/library/nginx:1.19.4
Trying to pull 192.168.110.35/library/nginx:1.19.4...
Getting image source signatures
Copying blob sha256:232bf38931fc8c7f00f73e6d2be46776bd5b0999eb4c190c810a74cf203b1474
Copying blob sha256:c5df295936d31cee0907f9652ff1b0518482ea87102f4cd2a872ed720e72314b
Copying blob sha256:a29b129f410924b8ca6289b0e958f3d5ac159e29b54e4d9ab33e51eb87857474
Copying blob sha256:b3ddf1fa5595a82768da495f49d416bae8806d06ffe705935b4573035d8cfbad
Copying blob sha256:852e50cd189dfeb54d97680d9fa6bed21a6d7d18cfb56d6abfe2de9d7f173795
Copying config sha256:daee903b4e436178418e41d8dc223b73632144847e5fe81d061296e667f16ef2
Writing manifest to image destination
Storing signatures
daee903b4e436178418e41d8dc223b73632144847e5fe81d061296e667f16ef2

➜  ~ podman pull k8s.gcr.io/kube-apiserver:v1.20.1
Trying to pull k8s.gcr.io/kube-apiserver:v1.20.1...
Getting image source signatures
Copying blob sha256:f398b465657ed53ee83af22197ef61be9daec6af791c559ee5220dee5f3d94fe
Copying blob sha256:d7d21f5bdd8303a60bac834f99867a58e6f3e1abcb6d486158a1ccb67dbf85bf
Copying blob sha256:cbcdf8ef32b41cd954f25c9d85dee61b05acc3b20ffa8620596ed66ee6f1ae1d
Copying blob sha256:f398b465657ed53ee83af22197ef61be9daec6af791c559ee5220dee5f3d94fe
Copying blob sha256:cbcdf8ef32b41cd954f25c9d85dee61b05acc3b20ffa8620596ed66ee6f1ae1d
Copying blob sha256:d7d21f5bdd8303a60bac834f99867a58e6f3e1abcb6d486158a1ccb67dbf85bf
Copying config sha256:e1822562bf942868d700a2f08eb368f2c88987e473aae12997cc07cc83e789d1
Writing manifest to image destination
Storing signatures
e1822562bf942868d700a2f08eb368f2c88987e473aae12997cc07cc83e789d1
```

### 运行容器  
```bash
➜  ~ podman run -d --name adminer --hostname adminer -p 8080:8080 --network bridge 192.168.110.35/library/adminer:4.8.1-standalone
➜  ~ podman ps
CONTAINER ID  IMAGE                                            COMMAND               CREATED        STATUS            PORTS                   NAMES
99b21f9f723b  192.168.110.35/library/adminer:4.8.1-standalone  php -S [::]:8080 ...  7 seconds ago  Up 7 seconds ago  0.0.0.0:8080->8080/tcp  adminer
```

### 访问容器   
用以上方式运行后，已有的podman配置如下所示
```bash
➜  ~ podman system connection ls
Name         URI                                                         Identity                  Default
podman       ssh://core@localhost:63215/run/user/501/podman/podman.sock  /Users/lucas/.ssh/podman  true
podman-root  ssh://root@localhost:63215/run/podman/podman.sock           /Users/lucas/.ssh/podman  false
podman3      ssh://root@192.168.64.2:22/run/podman/podman.sock           /Users/lucas/.ssh/id_rsa  false
podman4      ssh://root@192.168.64.4:22/run/podman/podman.sock           /Users/lucas/.ssh/id_rsa  false
➜  ~ podman system connection default podman3
➜  ~ podman3 ps
CONTAINER ID  IMAGE                                            COMMAND               CREATED         STATUS             PORTS                   NAMES
99b21f9f723b  192.168.110.35/library/adminer:4.8.1-standalone  php -S [::]:8080 ...  30 minutes ago  Up 30 minutes ago  0.0.0.0:8080->8080/tcp  adminer
➜  ~ podman system connection default podman4
➜  ~ podman ps
CONTAINER ID  IMAGE                                            COMMAND               CREATED         STATUS             PORTS                   NAMES
72b3ad0ac98d  192.168.110.35/library/adminer:4.8.1-standalone  php -S [::]:8080 ...  38 seconds ago  Up 38 seconds ago  0.0.0.0:8080->8080/tcp  adminer
➜  ~ podman system connection default podman
➜  ~ podman ps
CONTAINER ID  IMAGE                                            COMMAND               CREATED        STATUS            PORTS                   NAMES
a38dc8af9a8c  192.168.110.35/library/adminer:4.8.1-standalone  php -S [::]:8080 ...  3 seconds ago  Up 4 seconds ago  0.0.0.0:8080->8080/tcp  adminer
```

对于使用podman machine的可以直接使用127.0.0.1进行访问
```bash
curl 127.0.0.1:8080
```
也可以与podman-desktop一起使用
![](https://limpair.nos-eastchina1.126.net/images/podman/podman-desktop.png)

对于使用multipass的，可以使用vm ip进行访问
```bash
curl 192.168.64.2:8080
curl 192.168.64.4:8080
```

podman的命令大部分与docker类似，可以配置一个`alias`
```bash
echo 'alias docker="podman"' >> .zshrc
source .zshrc
docker version
```

## 参考链接

[1] [multipass using a custom dns](https://multipass.run/docs/using-a-custom-dns)
[2] [multipass troubleshooting networking on macos](https://multipass.run/docs/troubleshooting-networking-on-macos)
[3] [podman containers registries.conf.d](https://github.com/containers/image/blob/main/docs/containers-registries.conf.d.5.md)
[4] [podman mac experimental](https://github.com/containers/podman/blob/main/docs/tutorials/mac_experimental.md)
[5] [podman tutorial](https://github.com/containers/podman/blob/main/docs/tutorials/podman_tutorial.md)
[6] [debian experimental](https://wiki.debian.org/DebianExperimental)
