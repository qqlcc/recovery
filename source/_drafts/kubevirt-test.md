---
title: kubevirt-test
categories:
tags:
---

检查GRUB配置
```bash
cat /proc/cmdline
```
确保GRUB配置中包括intel_iommu=on和iommu=pt。


yum install libvirt-client -y
virt-host-validate qemu

efi
```
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
```