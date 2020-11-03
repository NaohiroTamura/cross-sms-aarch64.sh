# Cross Platform Cluster Example using QEMU for OpenHPC 2.0 CentOS 8.2 (with Warewulf + Slurm)

## 0. Preparation

| Node              | IP             | MAC               |
|-------------------|----------------|-------------------|
|sms-ohpc20-centos8 | 10.124.196.100 | 00:16:3e:e9:f1:33 |
|c1  (aarch64 qemu) | 10.124.196.61  | 52:54:00:12:34:56 |
|c2  (aarch64 qemu) | 10.124.196.62  | 52:54:00:12:34:57 |
|n1  (x86_64  qemu) | 10.124.196.71  | 52:54:00:12:34:66 |
|n2  (x86_64  qemu) | 10.124.196.72  | 52:54:00:12:34:67 |

### 0.1 OpenSSH setup

```sh
[root@sms-ohpc20-centos8 ~]# dnf install -y openssh openssh-server openssh-clients openssl-libs

[root@sms-ohpc20-centos8 ~]# systemctl start sshd.service

[root@sms-ohpc20-centos8 ~]# systemctl status sshd.service
```

### 0.2 NFS setup

```sh
[root@sms-ohpc20-centos8 ~]# dnf -y install nfs-utils
```

### 0.3 Docker-ce setup

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

### 0.4 Bridge setup

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

# check br0 IP address
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
```

### 0.5 OVMF

```sh
[root@sms-ohpc20-centos8 ~]# yum config-manager --add-repo https://www.kraxel.org/repos/jenkins/

[root@sms-ohpc20-centos8 ~]# yum -y --nogpg install edk2.git-ovmf-x64 edk2.git-aarch64

[root@sms-ohpc20-centos8 ~]# yum-config-manager --disable kraxel.org_repos_jenkins_
```

### QEMU 5.1.0

```sh
[root@sms-ohpc20-centos8 ~]# wget https://download.qemu.org/qemu-5.1.0.tar.xz

[root@sms-ohpc20-centos8 ~]# tar xvf ../qemu-5.1.0.tar.xz

[root@sms-ohpc20-centos8 ~]# cd qemu-5.1.0

[root@sms-ohpc20-centos8 qemu-5.1.0]# yum -y groupinstall 'Development tools'

[root@sms-ohpc20-centos8 qemu-5.1.0]# yum -y install hostname python3 zlib-devel glib2-devel pixman-devel libcap-ng-devel libattr-devel

# disable kvm so as to be able to run on vm guest or public cloud which doesn't allow nested vm.
[root@sms-ohpc20-centos8 qemu-5.1.0]# ./configure --target-list=x86_64-softmmu,aarch64-softmmu --prefix=/opt/qemu-5.1.0 --disable-kvm --enable-virtfs

[root@sms-ohpc20-centos8 qemu-5.1.0]# make -j4

[root@sms-ohpc20-centos8 qemu-5.1.0]# make check

[root@sms-ohpc20-centos8 qemu-5.1.0]# make install

[root@sms-ohpc20-centos8 qemu-5.1.0]# mkdir -p /opt/qemu-5.1.0/etc/qemu

[root@sms-ohpc20-centos8 qemu-5.1.0]# echo "allow br0" > /opt/qemu-5.1.0/etc/qemu/bridge.conf
```

----------------------------------------------------------------------

## 1 Introduction (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# sms_ip=10.124.196.100

# 'sms_name' has to be the name 'hostname' command returns.
# slurmctrld doesn't start if 'sms_name' is an alias name defined for
# 'sms_ip' in /etc/host.
[root@sms-ohpc20-centos8 ~]# sms_name=sms-ohpc20-centos8

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

[root@sms-ohpc20-centos8 ~]# yum config-manager --set-enabled PowerTools
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

# 'sms_name' has to be the name 'hostname' command returns.
# slurmctrld doesn't start if 'sms_name' is an alias name defined for
# 'sms_ip' in /etc/host.
[root@sms-ohpc20-centos8 ~]# perl -pi -e "s/ControlMachine=\S+/ControlMachine=${sms_name}/" /etc/slurm/slurm.conf
```

### 3.5 Optionally add InﬁniBand support services on master node (x86_64)

No operation.

### 3.6 Optionally add Omni-Path support services on master node (x86_64)

No operation.

### 3.7 Complete basic Warewulf setup for master node (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# perl -pi -e "s/device = eth1/device = ${sms_eth_internal}/" /etc/warewulf/provision.conf

[root@sms-ohpc20-centos8 ~]# systemctl enable httpd.service

[root@sms-ohpc20-centos8 ~]# systemctl restart httpd

[root@sms-ohpc20-centos8 ~]# systemctl enable dhcpd.service

[root@sms-ohpc20-centos8 ~]# systemctl enable tftp

[root@sms-ohpc20-centos8 ~]# systemctl restart tftp
```

### 3.8 Deﬁne compute image for provisioning (x86_64), 3.6 Deﬁne compute image for provisioning (aarch64)

#### 3.6.1 Build initial BOS image (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# git clone https://github.com/NaohiroTamura/cross-sms-aarch64.sh

[root@sms-ohpc20-centos8 ~]# cd cross-sms-aarch64.sh

[root@sms-ohpc20-centos8 cross-sms-aarch64.sh]# make base_os=centos8

[root@sms-ohpc20-centos8 cross-sms-aarch64.sh]# make install sms_ip=$sms_ip

[root@sms-ohpc20-centos8 cross-sms-aarch64.sh]# cd ..

[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh

# Notice that bash prompt is changed. Now we are in the container.
[root@aarch64 /]# export CHROOT=/var/chroots/centos8.2

[root@aarch64 /]# mkdir -p $CHROOT/usr/bin

[root@aarch64 /]# cp -p /usr/bin/qemu-aarch64-static $CHROOT/usr/bin

[root@aarch64 /]# wwmkchroot -d centos-8 $CHROOT

[root@aarch64 /]# dnf -y --installroot $CHROOT install epel-release

[root@aarch64 /]# cp -p /etc/yum.repos.d/OpenHPC*.repo $CHROOT/etc/yum.repos.d
```

#### 3.6.2 Add OpenHPC components (aarch64)

```sh
[root@aarch64 /]# yum -y --installroot=$CHROOT install ohpc-base-compute

[root@aarch64 /]# cp -p /etc/resolv.conf $CHROOT/etc/resolv.conf

[root@aarch64 /]# yum -y --installroot=$CHROOT install ohpc-slurm-client

[root@aarch64 /]# chroot $CHROOT systemctl enable munge

# 'sms_ip' is set again because shell variable in the container host
# is not inherited into the container guest.
[root@aarch64 /]# sms_ip=10.124.196.100

[root@aarch64 /]# echo SLURMD_OPTIONS="--conf-server ${sms_ip}" > $CHROOT/etc/sysconfig/slurmd

[root@aarch64 /]# yum -y --installroot=$CHROOT install chrony

[root@aarch64 /]# echo "server ${sms_ip}" >> $CHROOT/etc/chrony.conf

[root@aarch64 /]# yum -y --installroot=$CHROOT install kernel

[root@aarch64 /]# yum -y --installroot=$CHROOT install lmod-ohpc

# glibc-headers glibc-devel are necessary to compile user's application
# program on aarch64 Conpute Node
[root@aarch64 /]# yum -y --installroot=$CHROOT install glibc-headers glibc-devel

[root@aarch64 /]# exit
```

#### 3.6.3 Customize system conﬁguration (aarch64)

```sh
# aarch64 BOS (Base Operating System) image in x86_64 host, which path
# is mapped to /var/chroots/centos8.2 in sms-aarch64.sh container.
[root@sms-ohpc20-centos8 ~]# export AARCH64_CHROOT=/opt/ohpc-aarch64/var/chroots/centos8.2

# $AARCH64_CHROOT/root/.ssh/authorized_keys has /root/.ssh/cluster.pub
# of sms-aarch64.sh container. So it has to be overwitten by
# /root/.ssh/cluster.pub of x86_64 host 'sms-ohpc20-centos8'.
[root@sms-ohpc20-centos8 ~]# cat ~/.ssh/cluster.pub > $AARCH64_CHROOT/root/.ssh/authorized_keys

[root@sms-ohpc20-centos8 ~]# chmod 0600 $AARCH64_CHROOT/root/.ssh/authorized_keys

[root@sms-ohpc20-centos8 ~]# echo "${sms_ip}:/home /home nfs nfsvers=3,nodev,nosuid 0 0" >> $AARCH64_CHROOT/etc/fstab

[root@sms-ohpc20-centos8 ~]# echo "${sms_ip}:/opt/ohpc-aarch64/opt/ohpc/pub /opt/ohpc/pub nfs nfsvers=3,nodev 0 0" >> $AARCH64_CHROOT/etc/fstab
```

```sh
[root@sms-ohpc20-centos8 ~]# echo "/opt/ohpc-aarch64/opt/ohpc/pub *(ro,no_subtree_check,fsid=12)" >> /etc/exports
```

#### 3.8.1 Build initial BOS image (x86_64)

```sh
# x86_64 BOS(Base Operating System) image
[root@sms-ohpc20-centos8 ~]# export X86_64_CHROOT=/opt/ohpc/admin/images/centos8.2

[root@sms-ohpc20-centos8 ~]# mkdir -p $X86_64_CHROOT

[root@sms-ohpc20-centos8 ~]# wwmkchroot -v centos-8 $X86_64_CHROOT

[root@sms-ohpc20-centos8 ~]# dnf -y --installroot $X86_64_CHROOT install epel-release

[root@sms-ohpc20-centos8 ~]# cp -p /etc/yum.repos.d/OpenHPC*.repo $X86_64_CHROOT/etc/yum.repos.d
```

#### 3.8.2 Add OpenHPC components (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# yum -y --installroot=$X86_64_CHROOT install ohpc-base-compute

[root@sms-ohpc20-centos8 ~]# cp -p /etc/resolv.conf $X86_64_CHROOT/etc/resolv.conf

[root@sms-ohpc20-centos8 ~]# yum -y --installroot=$X86_64_CHROOT install ohpc-slurm-client

[root@sms-ohpc20-centos8 ~]# chroot $X86_64_CHROOT systemctl enable munge

[root@sms-ohpc20-centos8 ~]# echo SLURMD_OPTIONS="--conf-server ${sms_ip}" > $X86_64_CHROOT/etc/sysconfig/slurmd

[root@sms-ohpc20-centos8 ~]# yum -y --installroot=$X86_64_CHROOT install chrony

[root@sms-ohpc20-centos8 ~]# echo "server ${sms_ip}" >> $X86_64_CHROOT/etc/chrony.conf

[root@sms-ohpc20-centos8 ~]# yum -y --installroot=$X86_64_CHROOT install kernel

[root@sms-ohpc20-centos8 ~]# yum -y --installroot=$X86_64_CHROOT install lmod-ohpc

[root@sms-ohpc20-centos8 ~]# yum -y --installroot=$X86_64_CHROOT install glibc-headers glibc-devel
```

#### 3.8.3 Customize system conﬁguration (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# wwinit database

[root@sms-ohpc20-centos8 ~]# wwinit ssh_keys

[root@sms-ohpc20-centos8 ~]# echo "${sms_ip}:/home /home nfs nfsvers=3,nodev,nosuid 0 0" >> $X86_64_CHROOT/etc/fstab

[root@sms-ohpc20-centos8 ~]# echo "${sms_ip}:/opt/ohpc/pub /opt/ohpc/pub nfs nfsvers=3,nodev 0 0" >> $X86_64_CHROOT/etc/fstab
```

```sh
[root@sms-ohpc20-centos8 ~]# echo "/home *(rw,no_subtree_check,fsid=10,no_root_squash)" >> /etc/exports

[root@sms-ohpc20-centos8 ~]# echo "/opt/ohpc/pub *(ro,no_subtree_check,fsid=11)" >> /etc/exports

[root@sms-ohpc20-centos8 ~]# exportfs -ra

[root@sms-ohpc20-centos8 ~]# systemctl restart nfs-server

[root@sms-ohpc20-centos8 ~]# systemctl enable nfs-server
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

#### 3.7.1 Assemble bootstrap image (aarch64)

```sh
# These two packages are necessary to assemble aarch64 bootstrap on
# x86_64 host.
[root@sms-ohpc20-centos8 ~]# yum install -y warewulf-provision-ohpc-initramfs-aarch64 warewulf-provision-ohpc-server-ipxe-aarch64

[root@sms-ohpc20-centos8 ~]# export WW_CONF=/etc/warewulf/bootstrap.conf

[root@sms-ohpc20-centos8 ~]# echo "drivers += updates/kernel/" >> $WW_CONF

# These kernel modules are necessary to boot OS in QEMU environment
[root@sms-ohpc20-centos8 ~]# echo "modprobe += virtio, virtio_ring, virtio_blk, virtio_net, virtio_pci" >> $WW_CONF
```

```sh
[root@sms-ohpc20-centos8 ~]# ls $AARCH64_CHROOT/boot/vmlinuz*
/opt/ohpc-aarch64/var/chroots/centos8.2/boot/vmlinuz-4.18.0-193.19.1.el8_2.aarch64

[root@sms-ohpc20-centos8 ~]# wwbootstrap --chroot $AARCH64_CHROOT 4.18.0-193.19.1.el8_2.aarch64

# Notice ARCH is x86_64
[root@sms-ohpc20-centos8 ~]# wwsh bootstrap list
BOOTSTRAP NAME            SIZE (M)      ARCH
4.18.0-193.19.1.el8_2.aarch64 38.7          x86_64

# Change ARCH to aarch64
[root@sms-ohpc20-centos8 ~]# wwsh bootstrap set -y -a aarch64 4.18.0-193.19.1.el8_2.aarch64

# Confirm ARCH is changed to aarch64
[root@sms-ohpc20-centos8 ~]# wwsh bootstrap list
BOOTSTRAP NAME            SIZE (M)      ARCH
4.18.0-193.19.1.el8_2.aarch64 38.7          aarch64
```

#### 3.7.2 Assemble Virtual Node File System (VNFS) image (aarch64)

```sh
# munge uid/gid is different between SMS and CN, therefor munge owned
# directories have to be updated to SMS's munge uid/gid.
[root@sms-ohpc20-centos8 ~]# chown -R munge.munge $AARCH64_CHROOT/etc/munge $AARCH64_CHROOT/var/lib/munge $AARCH64_CHROOT/var/log/munge $AARCH64_CHROOT/run/munge

# VNFS image has to include "/usr/include" headers to compile user's
# application program on Compute Node.
[root@sms-ohpc20-centos8 ~]# perl -pi -e "s/^hybridize \+= \/usr\/include/\#hybridize \+= \/usr\/include/" /etc/warewulf/vnfs.conf

[root@sms-ohpc20-centos8 ~]# wwvnfs --chroot $AARCH64_CHROOT centos8.2-aarch64

# Notice ARCH is x86_64
[root@sms-ohpc20-centos8 ~]# wwsh vnfs list
VNFS NAME            SIZE (M)   ARCH       CHROOT LOCATION
centos8.2-aarch64    359.3      x86_64     /opt/ohpc-aarch64/var/chroots/centos8.2

# Change ARCH to aarch64
[root@sms-ohpc20-centos8 ~]# wwsh vnfs set -y -a aarch64 centos8.2-aarch64

# Confirm ARCH is changed to aarch64
[root@sms-ohpc20-centos8 ~]# wwsh vnfs list
VNFS NAME            SIZE (M)   ARCH       CHROOT LOCATION
centos8.2-aarch64    359.3      aarch64    /opt/ohpc-aarch64/var/chroots/centos8.2
```

#### 3.7.3 Register nodes for provisioning (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# echo "GATEWAYDEV=eth0" > /tmp/network.$$

[root@sms-ohpc20-centos8 ~]# wwsh -y file import /tmp/network.$$ --name network

[root@sms-ohpc20-centos8 ~]# wwsh -y file set network --path /etc/sysconfig/network --mode=0644 --uid=0
```

```sh
[root@sms-ohpc20-centos8 ~]# wwsh -y node new c1 --arch=aarch64 --ipaddr=10.124.196.61 --hwaddr=52:54:00:12:34:56 -D eth0

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set c1 --vnfs=centos8.2-aarch64 --bootstrap=4.18.0-193.19.1.el8_2.aarch64 \
--files=dynamic_hosts,passwd,group,shadow,munge.key,network

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set c1 --kargs="net.ifnames=0 biosdevname=0 console=ttyAMA0,115200 rd.debug"

[root@sms-ohpc20-centos8 ~]# wwsh -y node new c2 --arch=aarch64 --ipaddr=10.124.196.62 --hwaddr=52:54:00:12:34:57 -D eth0

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set c2 --vnfs=centos8.2-aarch64 --bootstrap=4.18.0-193.19.1.el8_2.aarch64 \
--files=dynamic_hosts,passwd,group,shadow,munge.key,network

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set c2 --kargs="net.ifnames=0 biosdevname=0 console=ttyAMA0,115200 rd.debug"

[root@sms-ohpc20-centos8 ~]# wwsh node list
NAME                GROUPS              IPADDR              HWADDR
================================================================================
c1                  UNDEF               10.124.196.61       52:54:00:12:34:56
c2                  UNDEF               10.124.196.62       52:54:00:12:34:57
```

#### 3.9.1 Assemble bootstrap image (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# ls $X86_64_CHROOT/boot/vmlinuz*
/opt/ohpc/admin/images/centos8.2/boot/vmlinuz-4.18.0-193.19.1.el8_2.x86_64

[root@sms-ohpc20-centos8 ~]# wwbootstrap --chroot $X86_64_CHROOT 4.18.0-193.19.1.el8_2.x86_64

[root@sms-ohpc20-centos8 ~]# wwsh bootstrap list
BOOTSTRAP NAME            SIZE (M)      ARCH
4.18.0-193.19.1.el8_2.aarch64 38.7          aarch64
4.18.0-193.19.1.el8_2.x86_64 42.6          x86_64
```

#### 3.9.2 Assemble Virtual Node File System (VNFS) image (x86_64)

```sh
# munge uid/gid is different between SMS and CN, therefor munge owned
# directories have to be updated to SMS's munge uid/gid.
[root@sms-ohpc20-centos8 ~]# chown -R munge.munge $X86_64_CHROOT/etc/munge $X86_64_CHROOT/var/lib/munge $X86_64_CHROOT/var/log/munge $X86_64_CHROOT/run/munge

[root@sms-ohpc20-centos8 ~]# wwvnfs --chroot $X86_64_CHROOT centos8.2-x86_64

[root@sms-ohpc20-centos8 ~]# wwsh vnfs list
VNFS NAME            SIZE (M)   ARCH       CHROOT LOCATION
centos8.2-aarch64    359.3      aarch64    /opt/ohpc-aarch64/var/chroots/centos8.2
centos8.2-x86_64     374.9      x86_64     /opt/ohpc/admin/images/centos8.2
```

#### 3.9.3 Register nodes for provisioning (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# wwsh -y node new n1 --arch=x86_64 --ipaddr=10.124.196.71 --hwaddr=52:54:00:12:34:66 -D eth0

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set n1 --vnfs=centos8.2-x86_64 --bootstrap=4.18.0-193.19.1.el8_2.x86_64 \
--files=dynamic_hosts,passwd,group,shadow,munge.key,network

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set n1 --kargs="net.ifnames=0 biosdevname=0 console=ttyS0,115200 rd.debug"

[root@sms-ohpc20-centos8 ~]# wwsh -y node new n2 --arch=x86_64 --ipaddr=10.124.196.72 --hwaddr=52:54:00:12:34:67 -D eth0

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set n2 --vnfs=centos8.2-x86_64 --bootstrap=4.18.0-193.19.1.el8_2.x86_64 \
--files=dynamic_hosts,passwd,group,shadow,munge.key,network

[root@sms-ohpc20-centos8 ~]# wwsh -y provision set n2 --kargs="net.ifnames=0 biosdevname=0 console=ttyS0,115200 rd.debug"

[root@sms-ohpc20-centos8 ~]# wwsh node list
NAME                GROUPS              IPADDR              HWADDR
================================================================================
c1                  UNDEF               10.124.196.61       52:54:00:12:34:56
c2                  UNDEF               10.124.196.62       52:54:00:12:34:57
n1                  UNDEF               10.124.196.71       52:54:00:12:34:66
n2                  UNDEF               10.124.196.72       52:54:00:12:34:67
```

```sh
[root@sms-ohpc20-centos8 ~]# systemctl restart dhcpd

[root@sms-ohpc20-centos8 ~]# wwsh pxe update
```

#### 3.8 Boot compute nodes (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# cp /usr/share/edk2.git/aarch64/vars-template-pflash.raw c1-pflash.raw
[root@sms-ohpc20-centos8 ~]# cp /usr/share/edk2.git/aarch64/vars-template-pflash.raw c2-pflash.raw

# open new terminal
[root@sms-ohpc20-centos8 ~]# /opt/qemu-5.1.0/bin/qemu-system-aarch64 -m 8192 \
-drive if=pflash,format=raw,readonly,file=/usr/share/edk2.git/aarch64/QEMU_EFI-pflash.raw \
-drive if=pflash,format=raw,file=c1-pflash.raw \
-netdev bridge,id=net0,br=br0 -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:56 \
-serial mon:stdio -nographic -machine virt,accel=tcg -cpu cortex-a72 -smp 4 \
-device virtio-rng-pci

# open new terminal
[root@sms-ohpc20-centos8 ~]# /opt/qemu-5.1.0/bin/qemu-system-aarch64 -m 8192 \
-drive if=pflash,format=raw,readonly,file=/usr/share/edk2.git/aarch64/QEMU_EFI-pflash.raw \
-drive if=pflash,format=raw,file=c2-pflash.raw \
-netdev bridge,id=net0,br=br0 -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:57 \
-serial mon:stdio -nographic -machine virt,accel=tcg -cpu cortex-a72 -smp 4 \
-device virtio-rng-pci
```

#### 3.10 Boot compute nodesStart (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# cp /usr/share/edk2.git/ovmf-x64/OVMF_VARS-pure-efi.fd n1-pure-efi.fd
[root@sms-ohpc20-centos8 ~]# cp /usr/share/edk2.git/ovmf-x64/OVMF_VARS-pure-efi.fd n2-pure-efi.fd

# open new terminal
[root@sms-ohpc20-centos8 ~]# /opt/qemu-5.1.0/bin/qemu-system-x86_64 -m 8192 \
-drive if=pflash,format=raw,readonly,file=/usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd \
-drive if=pflash,format=raw,file=n1-pure-efi.fd \
-netdev bridge,id=net0,br=br0 -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:66 \
-serial mon:stdio -nographic -machine q35,accel=tcg -smp 4 \
-device virtio-rng-pci

# open new terminal
[root@sms-ohpc20-centos8 ~]# /opt/qemu-5.1.0/bin/qemu-system-x86_64 -m 8192 \
-drive if=pflash,format=raw,readonly,file=/usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd \
-drive if=pflash,format=raw,file=n2-pure-efi.fd \
-netdev bridge,id=net0,br=br0 -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:67 \
-serial mon:stdio -nographic -machine q35,accel=tcg -smp 4 \
-device virtio-rng-pci

```

```sh
[root@sms-ohpc20-centos8 ~]# ln -s /root/.ssh/cluster /root/.ssh/id_rsa

[root@sms-ohpc20-centos8 ~]# ln -s /root/.ssh/cluster.pub /root/.ssh/id_rsa.pub

[root@sms-ohpc20-centos8 ~]# pdsh -w c[1-2],n[1-2] uptime
n1:  05:18:12 up 15 min,  1 user,  load average: 0.08, 0.02, 0.03
n2:  05:18:13 up 9 min,  1 user,  load average: 0.09, 0.02, 0.08
c2:  05:18:14 up 27 min,  1 user,  load average: 0.31, 0.87, 0.54
c1:  05:18:15 up 34 min,  1 user,  load average: 0.27, 0.32, 0.38
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
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install ohpc-autotools
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install EasyBuild-ohpc
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install hwloc-ohpc
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install spack-ohpc
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install valgrind-ohpc
```
### 4.2 Compilers (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install gnu9-compilers-ohpc
```

### 4.3 MPI Stacks (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install openmpi4-gnu9-ohpc mpich-ofi-gnu9-ohpc
```

### 4.4 Performance Tools (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-perf-tools
```

### 4.5 Setup default development environment (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install lmod-defaults-gnu9-openmpi4-ohpc
```

### 4.6 3rd Party Libraries and Tools (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-serial-libs
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-io-libs
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-python-libs
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-runtimes

[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-mpich-parallel-libs
[root@sms-ohpc20-centos8 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-openmpi4-parallel-libs
```

## 5 Resource Manager Startup (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# vi /etc/slurm/slurm.conf
[root@sms-ohpc20-centos8 ~]# diff /etc/slurm/slurm.conf.ohpc /etc/slurm/slurm.conf
12c12
< ControlMachine=linux0
---
> ControlMachine=sms-ohpc20-centos8
96,97c96,99
< NodeName=c[1-4] Sockets=2 CoresPerSocket=8 ThreadsPerCore=2 State=UNKNOWN
< PartitionName=normal Nodes=c[1-4] Default=YES MaxTime=24:00:00 State=UP Oversubscribe=EXCLUSIVE
---
> NodeName=n[1-2] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 State=UNKNOWN
> NodeName=c[1-2] Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 State=UNKNOWN
> PartitionName=x86_64 Nodes=n[1-2] Default=YES MaxTime=24:00:00 State=UP
> PartitionName=aarch64 Nodes=c[1-2] MaxTime=24:00:00 State=UP
```

```sh
[root@sms-ohpc20-centos8 ~]# systemctl enable munge
[root@sms-ohpc20-centos8 ~]# systemctl enable slurmctld
[root@sms-ohpc20-centos8 ~]# systemctl start munge
[root@sms-ohpc20-centos8 ~]# systemctl start slurmctld

[root@sms-ohpc20-centos8 ~]# pdsh -w c[1-2],n[1-2] systemctl start munge
[root@sms-ohpc20-centos8 ~]# pdsh -w c[1-2],n[1-2] systemctl start slurmd

```

## 7 Run a Test Job (x86_64), 6 Run a Test Job (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# useradd -m test

[root@sms-ohpc20-centos8 ~]# pdsh -w c[1-2],n[1-2] /warewulf/bin/wwgetfiles
```

### 6.1 Interactive execution (aarch64)

```sh
[root@sms-ohpc20-centos8 ~]# su - test

[test@sms-ohpc20-centos8 ~]$ ssh c1

[test@sms-ohpc20-centos8 ~]$ ssh c1

[test@c1 ~]$ mkdir aarch64/

[test@c1 ~]$ cd aarch64/

[test@c1 aarch64]$ mpicc -O3 /opt/ohpc/pub/examples/mpi/hello.c

[test@c1 aarch64]$ exit

[test@sms-ohpc20-centos8 ~]$ cd aarch64

[test@sms-ohpc20-centos8 aarch64]$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
x86_64*      up 1-00:00:00      2   idle n[1-2]
aarch64      up 1-00:00:00      2   idle c[1-2]

[test@sms-ohpc20-centos8 aarch64]$ srun -n 8 -N 2 --partition=aarch64 --pty /bin/bash

[test@c1 aarch64]$ prun ./a.out
[prun] Master compute host = c1
[prun] Resource manager = slurm
[prun] Launch cmd = mpirun ./a.out (family=openmpi4)

    --> Process #   3 of   8 is alive. -> c1
 Hello, world (8 procs total)
    --> Process #   0 of   8 is alive. -> c1
    --> Process #   1 of   8 is alive. -> c1
    --> Process #   2 of   8 is alive. -> c1
    --> Process #   4 of   8 is alive. -> c2
    --> Process #   7 of   8 is alive. -> c2
    --> Process #   5 of   8 is alive. -> c2
    --> Process #   6 of   8 is alive. -> c2

[test@c1 aarch64]$ exit
```

6.2 Batch execution (aarch64)

```
[test@sms-ohpc20-centos8 aarch64]$ cp /opt/ohpc/pub/examples/slurm/job.mpi .

[test@sms-ohpc20-centos8 aarch64]$ vi job.mpi

[test@sms-ohpc20-centos8 aarch64]$ diff /opt/ohpc/pub/examples/slurm/job.mpi job.mpi
6c6
< #SBATCH -n 16                 # Total number of mpi tasks requested
---
> #SBATCH -n 8                  # Total number of mpi tasks requested

[test@sms-ohpc20-centos8 aarch64]$ cat job.mpi
#!/bin/bash

#SBATCH -J test               # Job name
#SBATCH -o job.%j.out         # Name of stdout output file (%j expands to jobId)
#SBATCH -N 2                  # Total number of nodes requested
#SBATCH -n 8                  # Total number of mpi tasks requested
#SBATCH -t 01:30:00           # Run time (hh:mm:ss) - 1.5 hours

# Launch MPI-based executable

prun ./a.out

[test@sms-ohpc20-centos8 aarch64]$ sbatch --partition=aarch64 job.mpi
Submitted batch job 11

[test@sms-ohpc20-centos8 aarch64]$ scontrol show job 11
JobId=11 JobName=test
   UserId=test(1002) GroupId=test(1002) MCS_label=N/A
   Priority=4294901758 Nice=0 Account=(null) QOS=(null)
   JobState=COMPLETED Reason=None Dependency=(null)
   Requeue=1 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   RunTime=00:00:16 TimeLimit=01:30:00 TimeMin=N/A
   SubmitTime=2020-10-30T12:59:38 EligibleTime=2020-10-30T12:59:38
   AccrueTime=2020-10-30T12:59:38
   StartTime=2020-10-30T12:59:39 EndTime=2020-10-30T12:59:55 Deadline=N/A
   SuspendTime=None SecsPreSuspend=0 LastSchedEval=2020-10-30T12:59:39
   Partition=aarch64 AllocNode:Sid=sms-ohpc20-centos8:204
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=c[1-2]
   BatchHost=c1
   NumNodes=2 NumCPUs=8 NumTasks=8 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   TRES=cpu=8,node=2,billing=8
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
   MinCPUsNode=1 MinMemoryNode=0 MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=/home/test/aarch64/job.mpi
   WorkDir=/home/test/aarch64
   StdErr=/home/test/aarch64/job.11.out
   StdIn=/dev/null
   StdOut=/home/test/aarch64/job.11.out
   Power=
   MailUser=(null) MailType=NONE

[test@sms-ohpc20-centos8 aarch64]$ cat job.11.out
[prun] Master compute host = c1
[prun] Resource manager = slurm
[prun] Launch cmd = mpirun ./a.out (family=openmpi4)

 Hello, world (8 procs total)
    --> Process #   0 of   8 is alive. -> c1
    --> Process #   2 of   8 is alive. -> c1
    --> Process #   4 of   8 is alive. -> c2
    --> Process #   6 of   8 is alive. -> c2
    --> Process #   1 of   8 is alive. -> c1
    --> Process #   5 of   8 is alive. -> c2
    --> Process #   3 of   8 is alive. -> c1
    --> Process #   7 of   8 is alive. -> c2

```

### 7.1 Interactive execution (x86_64)

```sh
[root@sms-ohpc20-centos8 ~]# su - test

[test@sms-ohpc20-centos8 ~]$ mkdir x86_64

[test@sms-ohpc20-centos8 ~]$ cd x86_64

[test@sms-ohpc20-centos8 x86_64]$ mpicc -O3 /opt/ohpc/pub/examples/mpi/hello.c

[test@sms-ohpc20-centos8 x86_64]$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
x86_64*      up 1-00:00:00      2   idle n[1-2]
aarch64      up 1-00:00:00      2   idle c[1-2]

[test@sms-ohpc20-centos8 x86_64]$ srun -n 8 -N 2 --pty /bin/bash
[test@n1 x86_64]$ prun ./a.out
[prun] Master compute host = n1
[prun] Resource manager = slurm
[prun] Launch cmd = mpirun ./a.out (family=openmpi4)

 Hello, world (8 procs total)
    --> Process #   0 of   8 is alive. -> n1
    --> Process #   2 of   8 is alive. -> n1
    --> Process #   3 of   8 is alive. -> n1
    --> Process #   1 of   8 is alive. -> n1
    --> Process #   4 of   8 is alive. -> n2
    --> Process #   5 of   8 is alive. -> n2
    --> Process #   6 of   8 is alive. -> n2
    --> Process #   7 of   8 is alive. -> n2
```

### 7.2 Batch execution (x86_64)

```sh
[test@sms-ohpc20-centos8 x86_64]$ cp /opt/ohpc/pub/examples/slurm/job.mpi .

[test@sms-ohpc20-centos8 x86_64]$ vi job.mpi

[test@sms-ohpc20-centos8 x86_64]$ diff /opt/ohpc/pub/examples/slurm/job.mpi job.mpi
6c6
< #SBATCH -n 16                 # Total number of mpi tasks requested
---
> #SBATCH -n 8                  # Total number of mpi tasks requested

[test@sms-ohpc20-centos8 x86_64]$ cat job.mpi
#!/bin/bash

#SBATCH -J test               # Job name
#SBATCH -o job.%j.out         # Name of stdout output file (%j expands to jobId)
#SBATCH -N 2                  # Total number of nodes requested
#SBATCH -n 8                  # Total number of mpi tasks requested
#SBATCH -t 01:30:00           # Run time (hh:mm:ss) - 1.5 hours

# Launch MPI-based executable

prun ./a.out

[test@sms-ohpc20-centos8 x86_64]$ sbatch job.mpi
Submitted batch job 16

[test@sms-ohpc20-centos8 x86_64]$ scontrol show job 16
JobId=16 JobName=test
   UserId=test(1002) GroupId=test(1002) MCS_label=N/A
   Priority=4294901755 Nice=0 Account=(null) QOS=(null)
   JobState=COMPLETED Reason=None Dependency=(null)
   Requeue=1 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   RunTime=00:00:12 TimeLimit=01:30:00 TimeMin=N/A
   SubmitTime=2020-10-31T05:42:14 EligibleTime=2020-10-31T05:42:14
   AccrueTime=2020-10-31T05:42:14
   StartTime=2020-10-31T05:42:14 EndTime=2020-10-31T05:42:26 Deadline=N/A
   SuspendTime=None SecsPreSuspend=0 LastSchedEval=2020-10-31T05:42:14
   Partition=x86_64 AllocNode:Sid=sms-ohpc20-centos8:204
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=n[1-2]
   BatchHost=n1
   NumNodes=2 NumCPUs=8 NumTasks=8 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   TRES=cpu=8,node=2,billing=8
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
   MinCPUsNode=1 MinMemoryNode=0 MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=/home/test/x86_64/job.mpi
   WorkDir=/home/test/x86_64
   StdErr=/home/test/x86_64/job.16.out
   StdIn=/dev/null
   StdOut=/home/test/x86_64/job.16.out
   Power=
   MailUser=(null) MailType=NONE

[test@sms-ohpc20-centos8 x86_64]$ cat job.16.out
[prun] Master compute host = n1
[prun] Resource manager = slurm
[prun] Launch cmd = mpirun ./a.out (family=openmpi4)

 Hello, world (8 procs total)
    --> Process #   1 of   8 is alive. -> n1
    --> Process #   0 of   8 is alive. -> n1
    --> Process #   2 of   8 is alive. -> n1
    --> Process #   3 of   8 is alive. -> n1
    --> Process #   5 of   8 is alive. -> n2
    --> Process #   4 of   8 is alive. -> n2
    --> Process #   7 of   8 is alive. -> n2
    --> Process #   6 of   8 is alive. -> n2
```
