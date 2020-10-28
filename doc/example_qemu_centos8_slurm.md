# Example on QEMU for OpenHPC 2.0 CentOS 8.2 (with Warewulf + Slurm)

## 0. Preparation

### 0.1 OpenSSH setup

```sh
[root@sms-ohpc20-centos8 ~]# dnf install -y openssh openssh-server openssh-clients openssl-libs

[root@sms-ohpc20-centos8 ~]# systemctl start sshd.service

[root@sms-ohpc20-centos8 ~]# systemctl status sshd.service
```

### 0.2 NFS setup

```sh
[root@sms-ohpc20-centos8 ~]# dnf -y install nfs-utils

[root@sms-ohpc20-centos8 ~]# systemctl enable nfs-server

[root@sms-ohpc20-centos8 ~]# systemctl start nfs-server

[root@sms-ohpc20-centos8 ~]# systemctl status nfs-server
```

### 0.3 Bridge setup

```sh
[root@sms-ohpc20-centos8 ~]# nmcli con show
NAME         UUID                                  TYPE      DEVICE
System eth0  5fb06bd0-0bb0-7ffb-45f1-d6edd65f3e03  ethernet  --

[root@sms-ohpc20-centos8 ~]# nmcli con add type bridge con-name br0 ifname br0

[root@sms-ohpc20-centos8 ~]# nmcli con modify br0 ipv4.method manual ipv4.addresses 10.124.196.100/24

[root@sms-ohpc20-centos8 ~]# nmcli con add type bridge-slave con-name eth1 ifname eth1 master br0

[root@sms-ohpc20-centos8 ~]# nmcli con show
NAME         UUID                                  TYPE      DEVICE
br0          a1a11a9c-785d-4c49-a1a9-9c2dbd2881d0  bridge    br0
System eth0  5fb06bd0-0bb0-7ffb-45f1-d6edd65f3e03  ethernet  --
eth1         97845e67-6548-4977-bd51-d625fe8973a1  ethernet  --

[root@sms-ohpc20-centos8 ~]# nmcli con up br0

[root@sms-ohpc20-centos8 ~]# nmcli con up eth1

[root@sms-ohpc20-centos8 ~]# nmcli con show
NAME         UUID                                  TYPE      DEVICE
br0          a1a11a9c-785d-4c49-a1a9-9c2dbd2881d0  bridge    br0
eth1         97845e67-6548-4977-bd51-d625fe8973a1  ethernet  eth1
System eth0  5fb06bd0-0bb0-7ffb-45f1-d6edd65f3e03  ethernet  --

[root@sms-ohpc20-centos8 ~]# systemctl restart NetworkManager
```

### 0.4 Docker-ce setup


```sh
[root@sms-ohpc20-centos8 ~]# dnf -y install 'dnf-command(config-manager)'

[root@sms-ohpc20-centos8 ~]# dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

[root@sms-ohpc20-centos8 ~]# dnf -y install docker-ce docker-ce-cli

[root@sms-ohpc20-centos8 ~]# systemctl is-enabled docker.service

[root@sms-ohpc20-centos8 ~]# systemctl enable docker.service

[root@sms-ohpc20-centos8 ~]# systemctl start docker.service

[root@sms-ohpc20-centos8 ~]# systemctl status docker.service

[root@sms-ohpc20-centos8 ~]# docker -v
Docker version 19.03.13, build 4484c46d9d

[root@sms-ohpc20-centos8 ~]# docker run -it --rm busybox
```

----------------------------------------------------------------------

## 1 Introduction (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# sms_ip=10.124.196.100

[root@sms-ohpc20-centos8 ~]# sms_name=sms

[root@sms-ohpc20-centos8 ~]# ntp_server=10.134.61.180

[root@sms-ohpc20-centos8 ~]# sms_eth_internal=br0
```

## 2 Install Base Operating System (BOS) (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# systemctl disable firewalld

[root@sms-ohpc20-centos8 ~]# systemctl stop firewalld

[root@sms-ohpc20-centos8 ~]# echo ${sms_ip} ${sms_name} >> /etc/hosts
```

## 3 Install OpenHPC Components (x86_64)

### 3.1 Enable OpenHPC repository for local use (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum install http://repos.openhpc.community/OpenHPC/2/CentOS_8/x86_64/ohpc-release-2-1.el8.x86_64.rpm

[root@sms-ohpc20-centos8 ~]# yum install dnf-plugins-core

[root@sms-ohpc20-centos8 ~]# dnf config-manager --set-enabled PowerTools
```

### 3.2 Installation template (x86_64)

### 3.3 Add provisioning services on master node (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-base

[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-warewulf

[root@sms-ohpc20-centos8 ~]# systemctl enable chronyd.service

[root@sms-ohpc20-centos8 ~]# echo "server ${ntp_server}" >> /etc/chrony.conf

[root@sms-ohpc20-centos8 ~]# echo "allow all" >> /etc/chrony.conf

[root@sms-ohpc20-centos8 ~]# systemctl restart chronyd
```

### 3.4 Add resource management services on master node (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-slurm-server

[root@sms-ohpc20-centos8 ~]# cp /etc/slurm/slurm.conf.ohpc /etc/slurm/slurm.conf

[root@sms-ohpc20-centos8 ~]# perl -pi -e "s/ControlMachine=\S+/ControlMachine=${sms_name}/" /etc/slurm/slurm.conf
```

### 3.5 Optionally add InﬁniBand support services on master node (x86_64)

### 3.6 Optionally add Omni-Path support services on master node (x86_64)

### 3.7 Complete basic Warewulf setup for master node (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# perl -pi -e "s/device = eth1/device = ${sms_eth_internal}/" /etc/warewulf/provision.conf

[root@sms-ohpc20-centos8 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
3: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 00:16:3e:e9:f1:33 brd ff:ff:ff:ff:ff:ff
    inet 10.124.196.100/24 brd 10.124.196.255 scope global noprefixroute br0
       valid_lft forever preferred_lft forever
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:e9:1f:b4:52 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:e9ff:fe1f:b452/64 scope link
       valid_lft forever preferred_lft forever
75: eth0@if76: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 00:16:3e:b6:cb:56 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.62.192.75/24 brd 10.62.192.255 scope global dynamic eth0
       valid_lft 3083sec preferred_lft 3083sec
    inet6 fe80::216:3eff:feb6:cb56/64 scope link
       valid_lft forever preferred_lft forever
77: eth1@if78: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br0 state UP group default qlen 1000
    link/ether 00:16:3e:e9:f1:33 brd ff:ff:ff:ff:ff:ff link-netnsid 0

[root@sms-ohpc20-centos8 ~]# systemctl enable httpd.service

[root@sms-ohpc20-centos8 ~]# systemctl restart httpd

[root@sms-ohpc20-centos8 ~]# systemctl enable dhcpd.service

[root@sms-ohpc20-centos8 ~]# systemctl enable tftp

[root@sms-ohpc20-centos8 ~]# systemctl restart tftp
```

### 3.8 Deﬁne compute image for provisioning (x86_64), 3.6 Deﬁne compute image for provisioning (aarch64)

#### 3.8.1 Build initial BOS image (x86_64), 3.6.1 Build initial BOS image (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# git clone https://github.com/NaohiroTamura/cross-sms-aarch64.sh

[root@sms-ohpc20-centos8 ~]# cd cross-sms-aarch64.sh

[root@sms-ohpc20-centos8 cross-sms-aarch64.sh]# make base_os=centos8

[root@sms-ohpc20-centos8 cross-sms-aarch64.sh]# make install sms_ip=$sms_ip

[root@sms-ohpc20-centos8 cross-sms-aarch64.sh]# cd ..

[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh

[root@aarch64 /]# export CHROOT=/var/chroots/centos8.2

[root@aarch64 /]# mkdir -p $CHROOT/usr/bin

[root@aarch64 /]# cp -p /usr/bin/qemu-aarch64-static $CHROOT/usr/bin

[root@aarch64 /]# wwmkchroot -d centos-8 $CHROOT

[root@aarch64 /]# dnf -y --installroot $CHROOT install epel-release

[root@aarch64 /]# cp -p /etc/yum.repos.d/OpenHPC*.repo $CHROOT/etc/yum.repos.d
```

#### 3.8.2 Add OpenHPC components (x86_64), 3.6.2 Add OpenHPC components (aarch64)

```sh
[root@aarch64 /]# dnf -y --installroot=$CHROOT install ohpc-base-compute

[root@aarch64 /]# cp -p /etc/resolv.conf $CHROOT/etc/resolv.conf

[root@aarch64 /]# dnf -y --installroot=$CHROOT install ohpc-slurm-client

[root@aarch64 /]# chroot $CHROOT systemctl enable munge

[root@aarch64 /]# sms_ip=10.124.196.100

[root@aarch64 /]# echo SLURMD_OPTIONS="--conf-server ${sms_ip}" > $CHROOT/etc/sysconfig/slurmd

[root@aarch64 /]# dnf -y --installroot=$CHROOT install chrony

[root@aarch64 /]# echo "server ${sms_ip}" >> $CHROOT/etc/chrony.conf

[root@aarch64 /]# dnf -y --installroot=$CHROOT install kernel

[root@aarch64 /]# dnf -y --installroot=$CHROOT install lmod-ohpc

[root@aarch64 /]# exit
```

#### 3.8.3 Customize system conﬁguration (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# wwinit database

[root@sms-ohpc20-centos8 ~]# wwinit ssh_keys

[root@sms-ohpc20-centos8 ~]# echo "/home *(rw,no_subtree_check,fsid=10,no_root_squash)" >> /etc/exports

[root@sms-ohpc20-centos8 ~]# echo "/opt/ohpc/pub *(ro,no_subtree_check,fsid=11)" >> /etc/exports
```

#### 3.6.3 Customize system conﬁguration (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# export AARCH64_CHROOT=/opt/ohpc-aarch64/var/chroots/centos8.2

[root@sms-ohpc20-centos8 ~]# cat ~/.ssh/cluster.pub >> $AARCH64_CHROOT/root/.ssh/authorized_keys

[root@sms-ohpc20-centos8 ~]# chmod 0600 $AARCH64_CHROOT/root/.ssh/authorized_keys

[root@sms-ohpc20-centos8 ~]# echo "${sms_ip}:/home /home nfs nfsvers=3,nodev,nosuid 0 0" >> $AARCH64_CHROOT/etc/fstab

[root@sms-ohpc20-centos8 ~]# echo "${sms_ip}:/opt/ohpc-aarch64/opt/ohpc/pub /opt/ohpc/pub nfs nfsvers=3,nodev 0 0" >> $AARCH64_CHROOT/etc/fstab


[root@sms-ohpc20-centos8 ~]# echo "/opt/ohpc-aarch64/opt/ohpc/pub *(ro,no_subtree_check,fsid=12)" >> /etc/exports

[root@sms-ohpc20-centos8 ~]# exportfs -ra
```

#### 3.8.4 Additional Customization (optional) (x86_64)

#### 3.8.5 Import ﬁles (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# wwsh file import /etc/passwd

[root@sms-ohpc20-centos8 ~]# wwsh file import /etc/group

[root@sms-ohpc20-centos8 ~]# wwsh file import /etc/shadow

[root@sms-ohpc20-centos8 ~]# wwsh file import /etc/munge/munge.key
```

### 3.9 Finalizing provisioning conﬁguration (x86_64), 3.7 Finalizing provisioning conﬁguration (aarch64)

#### 3.9.1 Assemble bootstrap image (x86_64), 3.7.1 Assemble bootstrap image (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# dnf install -y warewulf-provision-ohpc-initramfs-aarch64 warewulf-provision-ohpc-server-ipxe-aarch64

[root@sms-ohpc20-centos8 ~]# export WW_CONF=/etc/warewulf/bootstrap.conf

[root@sms-ohpc20-centos8 ~]# echo "drivers += updates/kernel/" >> $WW_CONF

[root@sms-ohpc20-centos8 ~]# echo "modprobe += virtio, virtio_ring, virtio_blk, virtio_net, virtio_pci" >> $WW_CONF

[root@sms-ohpc20-centos8 ~]# ls $AARCH64_CHROOT/boot/vmlinuz*
/opt/ohpc-aarch64/var/chroots/centos8.2/boot/vmlinuz-4.18.0-193.19.1.el8_2.aarch64

[root@sms-ohpc20-centos8 ~]# wwbootstrap --chroot $AARCH64_CHROOT 4.18.0-193.19.1.el8_2.aarch64

[root@sms-ohpc20-centos8 ~]# wwsh bootstrap list
BOOTSTRAP NAME            SIZE (M)      ARCH
4.18.0-193.19.1.el8_2.aarch64 38.7          x86_64

[root@sms-ohpc20-centos8 ~]# wwsh bootstrap set -y -a aarch64 4.18.0-193.19.1.el8_2.aarch64

[root@sms-ohpc20-centos8 ~]# wwsh bootstrap list
BOOTSTRAP NAME            SIZE (M)      ARCH
4.18.0-193.19.1.el8_2.aarch64 38.7          aarch64
```

#### 3.9.2 Assemble Virtual Node File System (VNFS) image (x86_64), 3.7.2 Assemble Virtual Node File System (VNFS) image (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# cp -p /etc/munge/munge.key $AARCH64_CHROOT/etc/munge/

[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh chroot /var/chroots/centos8.2 ls -l /etc/munge/munge.key
-r-------- 1 995 989 1024 Oct 27 11:52 /etc/munge/munge.key

[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh chroot /var/chroots/centos8.2 chown munge.munge /etc/munge/munge.key

[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh chroot /var/chroots/centos8.2 ls -l /etc/munge/munge.key
-r-------- 1 munge munge 1024 Oct 27 11:52 /etc/munge/munge.key

[root@sms-ohpc20-centos8 ~]# grep centos /etc/passwd >> $AARCH64_CHROOT/etc/passwd

[root@sms-ohpc20-centos8 ~]# grep centos /etc/group >> $AARCH64_CHROOT/etc/group

[root@sms-ohpc20-centos8 ~]# wwvnfs --chroot $AARCH64_CHROOT centos8.2-aarch64

[root@sms-ohpc20-centos8 ~]# wwsh vnfs list
VNFS NAME            SIZE (M)   ARCH       CHROOT LOCATION
centos8.2-aarch64    353.6      x86_64     /opt/ohpc-aarch64/var/chroots/centos8.2

[root@sms-ohpc20-centos8 ~]# wwsh vnfs set -y centos8.2-aarch64 -a aarch64

[root@sms-ohpc20-centos8 ~]# wwsh vnfs list
VNFS NAME            SIZE (M)   ARCH       CHROOT LOCATION
centos8.2-aarch64    353.6      aarch64    /opt/ohpc-aarch64/var/chroots/centos8.2
```

#### 3.9.3 Register nodes for provisioning (x86_64), 3.7.3 Register nodes for provisioning (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# wwsh node new c1 --arch=aarch64 --ipaddr=10.124.196.61 --hwaddr=52:54:00:12:34:56 -D eth0

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set c1 --vnfs=centos8.2-aarch64 --bootstrap=4.18.0-193.19.1.el8_2.aarch64 --files=dynamic_hosts,shadow

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set c1 --kargs="net.ifnames=0 biosdevname=0 console=ttyAMA0,115200 rd.debug"

[root@sms-ohpc20-centos8 ~]# systemctl restart dhcpd

[root@sms-ohpc20-centos8 ~]# wwsh pxe update
```

## 4 Install OpenHPC Development Components (x86_64)

### 4.1 Development Tools (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-autotools
[root@sms-ohpc20-centos8 ~]# yum -y install EasyBuild-ohpc
[root@sms-ohpc20-centos8 ~]# yum -y install hwloc-ohpc
[root@sms-ohpc20-centos8 ~]# yum -y install spack-ohpc
[root@sms-ohpc20-centos8 ~]# yum -y install valgrind-ohpc
```

### 4.2 Compilers (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum -y install gnu9-compilers-ohpc
```

### 4.3 MPI Stacks (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum -y install openmpi4-gnu9-ohpc mpich-ofi-gnu9-ohpc
```

### 4.4 Performance Tools (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-gnu9-perf-tools
```

### 4.5 Setup default development environment (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum -y install lmod-defaults-gnu9-openmpi4-ohpc
```

### 4.6 3rd Party Libraries and Tools  (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-gnu9-serial-libs
[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-gnu9-io-libs
[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-gnu9-python-libs
[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-gnu9-runtimes

[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-gnu9-mpich-parallel-libs
[root@sms-ohpc20-centos8 ~]# yum -y install ohpc-gnu9-openmpi4-parallel-libs
```

## 4 Install OpenHPC Development Components (aarch64)

### 4.1 Development Tools (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install ohpc-autotools
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install EasyBuild-ohpc
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install hwloc-ohpc
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install spack-ohpc
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install valgrind-ohpc
```
### 4.2 Compilers (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install gnu9-compilers-ohpc
```

### 4.3 MPI Stacks (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install openmpi4-gnu9-ohpc mpich-ofi-gnu9-ohpc
```

### 4.4 Performance Tools (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install ohpc-gnu9-perf-tools
```

### 4.5 Setup default development environment (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install lmod-defaults-gnu9-openmpi4-ohpc
```

### 4.6 3rd Party Libraries and Tools (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install ohpc-gnu9-serial-libs
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install ohpc-gnu9-io-libs
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install ohpc-gnu9-python-libs
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install ohpc-gnu9-runtimes

[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install ohpc-gnu9-mpich-parallel-libs
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh dnf -y install ohpc-gnu9-openmpi3-parallel-libs
```

----------------------------------------------------------------------

## Start AArch64 Compute Node


```sh
ubuntu@bionic:~$ ip a
...
3: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether fe:2a:84:8c:ca:f3 brd ff:ff:ff:ff:ff:ff
    inet 10.124.196.156/24 brd 10.124.196.255 scope global br0
       valid_lft forever preferred_lft forever
    inet6 fe80::fc5f:5ff:fed2:b998/64 scope link
       valid_lft forever preferred_lft forever
...

ubuntu@bionic:~$ sudo /opt/qemu-5.0.0/bin/qemu-system-aarch64 -m 8192 \
-drive if=pflash,format=raw,readonly,file=/usr/share/edk2.git/aarch64/QEMU_EFI-pflash.raw \
-drive if=pflash,format=raw,file=c1-pflash.raw \
-netdev bridge,id=net0,br=br0 -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:56 \
-serial mon:stdio -vga std -nographic -machine virt,accel=tcg -cpu cortex-a72 -smp 4 \
-device virtio-rng-pci

```


## SMS x86_64 Operation

```sh
[root@sms-ohpc20-centos8 ~]# ln -s /root/.ssh/cluster /root/.ssh/id_rsa

[root@sms-ohpc20-centos8 ~]# ln -s /root/.ssh/cluster.pub /root/.ssh/id_rsa.pub

[root@sms-ohpc20-centos8 ~]# pdsh -w c1 uptime
c1:  05:02:23 up 11 min,  1 user,  load average: 0.11, 0.56, 0.49
```
