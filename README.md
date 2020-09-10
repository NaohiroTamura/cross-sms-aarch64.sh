# Cross SMS aarch64 Shell

This software is [OpenHPC][1] utility which enables without physical
aarch64 machine to create aarch64 initial build image, Base Operating
System (BOS), and to install aarch64 OpenHPC Development Components on
System Management Server (SMS) x86_64.
As the result, it achieves effective machine resources usage, and
facilitates to deploy and manage Compute Nodes both x86_64 and
aarch64.

Typically SMS x86_64 exports x86_64 OpenHPC Development Components as
/opt/ohpc/pub, and CN x86_64 mounts it on /opt/ohpc/pub.

And SMS aarch64 exports aarch64 OpenHPC Development Components as
/opt/ohpc/pub, and CN aarch64 mounts it on /opt/ohpc/pub as well.


In case of crossing the architecture which means that SMS x86_64
serves not only CN x86_64 but also CN aarch64, this software helps to
install aarch64 OpenHPC Development Components into
/opt/ohpc-aarch64/opt/ohpc/pub so that CN aarch64 can mounts it on
/opt/ohpc/pub.

[1]: https://github.com/openhpc/ohpc "OpenHPC"


## Prerequisites

SMS x86_64 requires the following softwares have been installed.

* [OpenHPC 1.3.9 (12 November 2019)][2] or [OpenHPC 2.0 (2020/3Q)][3]
* Docker/Docker-ce 1.13.1 later, or Podman 1.7.0 later (1.6.4 doesn't support NFS volume)

Type the following commands to verify the software versions:

```sh
[root@x86_64 ~]# rpm -qa | grep ohpc-base
ohpc-base-1.3.8-3.1.ohpc.1.3.8.x86_64

[root@x86_64 ~]# docker -v
Docker version 1.13.1, build cccb291/1.13.1

[root@x86_64 ~]# podman -v
podman version 1.7.0
```

If you choose podman, please install podman-docker package or creat symlink to docker.

```sh
[root@x86_64 ~]# ln -s /usr/bin/podman /usr/bin/docker
```


[2]: https://github.com/openhpc/ohpc/releases/download/v1.3.9.GA/Install_guide-CentOS7-Warewulf-SLURM-1.3.9-x86_64.pdf "CentOS 7.7 x86_64 Install guide with Warewulf + Slurm"
[3]: https://github.com/openhpc/ohpc/releases/download/v2.0RC1/Install_guide-Centos8-Warewulf-SLURM-2.0RC1-x86_64.pdf "OpenHPC 2.0 is RC1 as of June 05th 2020"


## Build and Install

Type the following four commands, *sms_ip* is your SMS x86_64 IP
address.

If you are behind organization's firewall, set HTTP_PROXY and
HTTPS_PROXY environment variables.

```sh
1. clone
[root@x86_64 ~]# git clone https://github.com/NaohiroTamura/cross-sms-aarch64.sh

2. change directory
[root@x86_64 ~]# cd cross-sms-aarch64.sh

3. make depends on OS and OpenHPC version
[root@x86_64 cross-sms-aarch64.sh]# make                  # CentOS 7.7 for OpenHPC 1.3.9
[root@x86_64 cross-sms-aarch64.sh]# make base_os=centos8  # CentOS 8.1 for OpenHPC 2.0
[root@x86_64 cross-sms-aarch64.sh]# make base_os=leap15   # Leap 15.1  for OpenHPC 2.0

4. install
[root@x86_64 cross-sms-aarch64.sh]# make install sms_ip=XX.XX.XX.XX
```

## Usage

*sms-aarch64.sh* is mainly used for two purposes:

1. build aarch64 initial BOS image onto SMS x86_64 file system
2. install aarch64 OpenHPC Development Components into SMS x86_64 file
   system

Heading title hereinafter refers to the section of OpenHPC 1.3.9
(12 November 2019) [CentOS 7.7 aarch64 Install guide with Warewulf +
Slurm][4].
It also matches section of OpenHPC 2.0 (2020 3Q) [CentOS 8.1 aarch64 
install guide with Warewulf + Slurm][5].

Please notice that the section number of [CentOS 7.7 aarch64 Install
guide with Warewulf + Slurm][4] is slightly different from [CentOS
7.7 x86_64 Install guide with Warewulf + Slurm][2].
The same applies to CentOS 8.1 Install guide.

[4]: https://github.com/openhpc/ohpc/releases/download/v1.3.9.GA/Install_guide-CentOS7-Warewulf-SLURM-1.3.9-aarch64.pdf "CentOS 7.7 aarch64 Install guide with Warewulf + Slurm"
[5]: https://github.com/openhpc/ohpc/releases/download/v2.0RC1/Install_guide-Centos8-Warewulf-SLURM-2.0RC1-x86_64.pdf "CentOS 8.1 aarch64 Install guide with Warewulf + Slurm"

### 3.1 Enable OpenHPC repository for local use

The ohpc-release package has been already installed onto CentOS
7.7.1910 container. Please take a look at Dockerfile.centos7.

### 3.2 Installation template

You can install the OpenHPC documentation package (docs-ohpc) into SMS
x86_64 instead of SMS aarch64 container.

### 3.3 Add provisioning services on master node

The base meta-packages have been already installed into the
container. Please take a look at Dockerfile.centos7.

### 3.4 Add resource management services on master node

The slurm server running on SMS x86_64 is used to serve to CN
aarch64. So you don't have to install the slurm server meta-package
into the container.

### 3.5 Complete basic Warewulf setup for master node

The warewulf should have been already set up on SMS x86_64. So you
don't have to set it up in the container.

### 3.6 Deﬁne compute image for provisioning

In order to build aarch64 initial BOS Image, you need to interact with
*sms-aarch64.sh* container. Be careful about the difference of the
prompts between *[root@x86_64 ~]#* and *[root@aarch64 /]#*

Note that the step **"cp -p /usr/bin/qemu-aarch64-static
$CHROOT/usr/bin"** before invoking *wwmkchroot*". This step is
essential to build the aarch64 initial BOS Image on SMS x86_64.

The environment variable *CHROOT* is set to */var/chroots/centos7.7*
of the container host local file system rather than
*/opt/ohpc/admin/images/centos7.7* on NFS volume, since NFS doesn't
support Linux Capabilities which *iputils* package requires.

```sh
# start interactive shell. it takes time to start for the first time
# due to volume initialization
[root@x86_64 ~]# sms-aarch64.sh

# create the image on host file system, but not on NFS
[root@aarch64 /]# export CHROOT=/var/chroots/centos7.7

# the essential step
[root@aarch64 /]# mkdir -p $CHROOT/usr/bin
[root@aarch64 /]# cp -p /usr/bin/qemu-aarch64-static $CHROOT/usr/bin

# make sure wwmkchroot is returned with no error
[root@aarch64 /]# wwmkchroot -d centos-7 $CHROOT
...
+ echo 'Running: cleanup'
Running: cleanup
+ cleanup
+ '[' -n '' ']'
+ return 0

[root@aarch64 /]# yum -y --installroot $CHROOT install epel-release
[root@aarch64 /]# cp -p /etc/yum.repos.d/OpenHPC*.repo $CHROOT/etc/yum.repos.d
[root@aarch64 /]# yum -y --installroot=$CHROOT install ohpc-base-compute
[root@aarch64 /]# cp -p /etc/resolv.conf $CHROOT/etc/resolv.conf
[root@aarch64 /]# yum -y --installroot=$CHROOT install ohpc-slurm-client
[root@aarch64 /]# yum -y --installroot=$CHROOT install ntp (in case of CentOS 7)
[root@aarch64 /]# yum -y --installroot=$CHROOT install chrony (in case of CentOS 8)
[root@aarch64 /]# yum -y --installroot=$CHROOT install kernel
[root@aarch64 /]# yum -y --installroot=$CHROOT install lmod-ohpc
[root@aarch64 /]# exit
```

The warewulf database is running on SMS x86_64, and all interactions
with the database must occur on the parent x86_64 host.  The
containerized aarch64 environment is now used to create a customized
chrooted VNFS environment in a path that is accessible by the parent
x86_64 host.

Please note that the path */var/chroots/images/centos7.7*
in the container is equivalent to the path
*/opt/ohpc-aarch64/var/chroots/centos7.7* on SMS x86_64.

The environment variable *AARCH64_CHROOT* is chosen to prevent us from
mixing up *CHROOT* inside the container with *CHROOT* outside the
container.

```sh
[root@x86_64 ~]# export AARCH64_CHROOT=/opt/ohpc-aarch64/var/chroots/centos7.7

# Add NFS client mounts of /home and /opt/ohpc/pub to base image
[root@x86_64 ~]# echo "${sms_ip}:/home /home nfs nfsvers=3,nodev,nosuid 0 0" >> $AARCH64_CHROOT/etc/fstab
[root@x86_64 ~]# echo "${sms_ip}:/opt/ohpc-aarch64/opt/ohpc/pub /opt/ohpc/pub nfs nfsvers=3,nodev 0 0" >> $AARCH64_CHROOT/etc/fstab

# Export /home and OpenHPC public packages from master server
[root@x86_64 ~]# echo "/opt/ohpc-aarch64/opt/ohpc/pub *(ro,no_subtree_check,fsid=12)" >> /etc/exports
[root@x86_64 ~]# exportfs -ra

# Enable NTP time service on computes and identify master host as local NTP server (in case of CentOS7)
[root@x86_64 ~]# chroot $AARCH64_CHROOT systemctl enable ntpd
[root@x86_64 ~]# echo "server ${sms_ip}" >> $AARCH64_CHROOT/etc/ntp.conf

# Identify master host as local NTP server (in case of CentOS 8)
[root@x86_64 ~]# echo "server ${sms_ip}" >> $AARCH64_CHROOT/etc/chrony.conf
```

### 3.7 Finalizing provisioning conﬁguration

In order to create aarch64 bootstrap, please make sure to install
*warewulf-provision-initramfs-aarch64-ohpc* package and
*warewulf-provision-server-ipxe-aarch64-ohpc* package into SMS
x86_64. OHPC 2.0 changed those package names to
*warewulf-provision-ohpc-initramfs-aarch64* and
* warewulf-provision-ohpc-server-ipxe-aarch64* respectively.

The kernel version of the aarch64 initial OBS image is different from
the kernel version of SMS x86_64. So please check the version as
follows.

The bootstrap image and Virtual Node File System (VNFS) image created
on x86_64 has *ARCH* attribute *x86_64* respectively. So please update
the ARCH attribute as follows.

```sh
# In case of OHPC 2.0, replace the package names in the command line to
# warewulf-provision-ohpc-initramfs-aarch64 and warewulf-provision-ohpc-server-ipxe-aarch64
[root@x86_64 ~]# yum install -y warewulf-provision-initramfs-aarch64-ohpc warewulf-provision-server-ipxe-aarch64-ohpc

[root@x86_64 ~]# export WW_CONF=/etc/warewulf/bootstrap.conf
[root@x86_64 ~]# echo "drivers += updates/kernel/" >> $WW_CONF
[root@x86_64 ~]# echo "drivers += overlay" >> $WW_CONF

# check the kernel version of the aarch64 OBS image
[root@x86_64 ~]# chroot $AARCH64_CHROOT rpm -qa | grep kernel
kernel-4.14.0-115.10.1.el7a.aarch64
kernel-headers-4.14.0-115.10.1.el7a.aarch64

# specifty the kernel version
[root@x86_64 ~]# wwbootstrap --chroot $AARCH64_CHROOT 4.14.0-115.10.1.el7a.aarch64

# Notice that ARCH is x86_64
[root@x86_64 ~]# wwsh bootstrap list
BOOTSTRAP NAME            SIZE (M)      ARCH
4.14.0-115.10.1.el7a.aarch64 23.0          x86_64

# Update the ARCH
[root@x86_64 ~]# wwsh bootstrap set -y 4.14.0-115.10.1.el7a.aarch64 -a aarch64

# make sure that ARCH is updated to aarch64
[root@x86_64 ~]# wwsh bootstrap list
BOOTSTRAP NAME            SIZE (M)      ARCH
4.14.0-115.10.1.el7a.aarch64 23.0         aarch64

# Assemble Virtual Node File System (VNFS) image
[root@x86_64 ~]# wwvnfs --chroot $AARCH64_CHROOT centos7.7-aarch64

# Notice that ARCH is x86_64
[root@x86_64 ~]# wwsh vnfs list
VNFS NAME            SIZE (M)   ARCH       CHROOT LOCATION
centos7.7-aarch64    277.7      x86_64     /opt/ohpc-aarch64/var/chroots/centos7.7

# Update the ARCH
[root@x86_64 ~]# wwsh vnfs set -y centos7.7-aarch64 -a aarch64

# make sure that ARCH is updated to aarch64
[root@x86_64 ~]# wwsh vnfs list
VNFS NAME            SIZE (M)   ARCH       CHROOT LOCATION
centos7.7-aarch64    277.7      aarch64    /opt/ohpc-aarch64/var/chroots/centos7.7

# Add nodes to Warewulf data store as aarch64
[root@x86_64 /]# wwsh node new ${c_name} --arch=aarch64 --ipaddr=${c_ip} --hwaddr=${c_mac} -D ${eth_provision}

# Define provisioning image for hosts
[root@x86_64 /]# wwsh provision set "${compute_regex}" --vnfs=centos7.7-aarch64 --bootstrap=4.14.0-115.10.1.el7a.aarch64 \
--files=dynamic_hosts,passwd,group,shadow,slurm.conf,munge.key,network

# Define provisioning image for hosts
[root@x86_64 /]# wwsh -y provision set ${c_name} --kargs="net.ifnames=0 biosdevname=0 console=ttyAMA0,115200 rd.debug"

# Restart dhcp / update PXE
[root@x86_64 /]# systemctl restart dhcpd
[root@x86_64 /]# wwsh pxe update
```

### 3.8 Boot compute nodes

Boot the CN aarch64 via IPMI as CN x86_64.

### 4.1 Development Tools

*sms-aarch64.sh* can be used not only interactive shell but also batch
shell as follows.

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-autotools
[root@x86_64 ~]# sms-aarch64.sh yum -y install EasyBuild-ohpc
[root@x86_64 ~]# sms-aarch64.sh yum -y install hwloc-ohpc
[root@x86_64 ~]# sms-aarch64.sh yum -y install spack-ohpc
[root@x86_64 ~]# sms-aarch64.sh yum -y install valgrind-ohpc
```
### 4.2 Compilers

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install gnu8-compilers-ohpc
[root@x86_64 ~]# sms-aarch64.sh yum -y install llvm5-compilers-ohpc
```

### 4.3 MPI Stacks

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install openmpi3-gnu8-ohpc mpich-gnu8-ohpc
```

### 4.4 Performance Tools

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu8-perf-tools
[root@x86_64 ~]# sms-aarch64.sh yum -y install lmod-defaults-gnu8-openmpi3-ohpc
```

### 4.5 Setup default development environment

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install lmod-defaults-gnu8-openmpi3-ohpc
```

### 4.6 3rd Party Libraries and Tools

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu8-serial-libs
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu8-io-libs
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu8-python-libs
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu8-runtimes

[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu8-mpich-parallel-libs
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu8-openmpi3-parallel-libs
```

## Tips

### Local Repository

If OHPC cluster is isolated from Internet, a local copy of OHPC,
RHEL/CentOS EPEL and other repositories can be used by specifying the
two environment variables, **YUM_REPOS_D** and **LOCAL_REPO**.

1. make and backup in Internet accessible host

    ```sh
    [root@x86_64 cross-sms-aarch64.sh]# make

    [root@x86_64 cross-sms-aarch64.sh]# docker save docker.io/arm64v8/centos:7 | gzip > arm64v8_centos_7.tar.gz

    [root@x86_64 cross-sms-aarch64.sh]# docker save sms-aarch64.sh:latest | gzip > sms-aarch64.sh.tar.gz

    [root@x86_64 cross-sms-aarch64.sh]# cd ..

    [root@x86_64 ~]# tar zcvf cross-sms-aarch64.sh.tar.gz cross-sms-aarch64.sh
    ```

2. restore and make install in Internet isolated host

    ```sh
    [root@x86_64 ~]# tar zxvf cross-sms-aarch64.sh.tar.gz

    [root@x86_64 cross-sms-aarch64.sh]# docker load < arm64v8_centos_7.tar.gz

    [root@x86_64 cross-sms-aarch64.sh]# docker load < sms-aarch64.sh.tar.gz

    [root@x86_64 cross-sms-aarch64.sh]# make install sms_ip=XX.XX.XX.XX
    ```

3. set environment variables and run sms-aarch64.sh

    * Set yum repo files path of the container host to the environment
      variable **YUM_REPOS_D** which is mapped to */etc/yum.repos.d*
      in the container.
    * Set the local repository path of the container host to the
      environment variable **LOCAL_REPO** which is mapped to
      */{repo_name}* in the container if **LOCAL_REPO** is created in
      */opt/ohpc-aarch64* such as */opt/ohpc-aarch64/{repo_name}*

    ```sh
    [root@x86_64 ~]# export YUM_REPOS_D=/opt/ohpc-aarch64/etc/yum.repos.d

    [root@x86_64 ~]# ls $YUM_REPOS_D
    centos-7.7.repo epel-7.repo OpenHPC.local.repo

    [root@x86_64 ~]# export LOCAL_REPO=/opt/ohpc-aarch64/repos

    [root@x86_64 ~]# ls $LOCAL_REPO
    CentOS_7 centos-7.7 epel-7

    [root@x86_64 ~]# sms-aarch64.sh

    [root@aarch64 /]# ls /etc/yum.repos.d
    centos-7.7  epel-7  OpenHPC.local.repo

    [root@aarch64 /]# ls /repos
    centos-7.7.repo epel-7.repo OpenHPC.local.repo
    ```

    * if **LOCAL_REPO** path is **NOT** in */opt/ohpc-aarch64* of the
      container host such as */repos*, it is mapped to the same path
      in the container such as */repos* in this case as below.

    ```sh
    [root@x86_64 ~]# export LOCAL_REPO=/repos

    [root@x86_64 ~]# ls $LOCAL_REPO
    CentOS_7  centos-7.7  epel-7

    [root@x86_64 ~]# sms-aarch64.sh

    [root@aarch64 /]# ls /repos
    CentOS_7  centos-7.7  epel-7
    ```

## Develeopment Information

### make

What *make* does is to build docker container named *sms-aarch64.sh*.

*qemu-aarch64-static* binary is retrieved from Ubuntu package, since
it's static binary which can run on any Linux.

If you prefer to compile *qemu-aarch64-static* from QEMU source code,
put your compiled *qemu-aarch64-static* under *usr/bin* directory so
as not to download from Ubuntu.

```sh
# setup binfmt_misc for aarch64
[root@x86_64 cross-sms-aarch64.sh]# cp -p etc/binfmt.d/aarch64.conf /etc/binfmt.d
[root@x86_64 cross-sms-aarch64.sh]# systemctl restart systemd-binfmt

# make sure that /proc/sys/fs/binfmt_misc/aarch64 is created
[root@x86_64 cross-sms-aarch64.sh]# ll /proc/sys/fs/binfmt_misc/aarch64

# download qemu-aarch64-static
[root@x86_64 cross-sms-aarch64.sh]# wget http://security.ubuntu.com/ubuntu/pool/universe/q/qemu/qemu-user-static_3.1+dfsg-2ubuntu3.1_amd64.deb
[root@x86_64 cross-sms-aarch64.sh]# ar p qemu-user-static_3.1+dfsg-2ubuntu3.1_amd64.deb data.tar.xz | tar Jxvf - ./usr/bin/qemu-aarch64-static

# build container in case of CentOS 7.7 for OpenHPC 1.3.9
[root@x86_64 cross-sms-aarch64.sh]# docker build -f Dockerfile.centos7 -t sms-aarch64.sh .
```

### make install

What *make install* does is the following four steps:

1. set up binfmt_misc for aarch64 if it doesn't exist
2. export /opt/ohpc-aarch64/opt/ohpc from master server to docker
   container
3. create Docker NFS volume and local volume
   * Docker volume has to be empty. If not, docker doesn't initialize
     the volume at the first time invocation. Otherwise it causes
     inconsistency.
4. Install docker client shell, sms-aarch64.sh

```sh
# 1. set up binfmt_misc if /proc/sys/fs/binfmt_misc/aarch64 doesn't exist
[root@x86_64 cross-sms-aarch64.sh]# if [ ! -e /proc/sys/fs/binfmt_misc/aarch64 ]; then \
> cp -p etc/binfmt.d/aarch64.conf /etc/binfmt.d; \
> systemctl restart systemd-binfmt; \
> fi

# 2. export /opt/ohpc-aarch64/opt/ohpc from master server to docker container in case of CentOS 7.7 for OpenHPC 1.3.9
[root@x86_64 cross-sms-aarch64.sh]# mkdir -p /opt/ohpc-aarch64/opt/ohpc
[root@x86_64 cross-sms-aarch64.sh]# echo "/opt/ohpc-aarch64/opt/ohpc 172.17.0.0/16(rw,no_subtree_check,no_root_squash) ${sms_ip}/32(rw,no_subtree_check,no_root_squash)" >> /etc/exports
[root@x86_64 cross-sms-aarch64.sh]# exportfs -ra

# 3. create Docker NFS volume and local volume
[root@x86_64 cross-sms-aarch64.sh]# docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=${sms_ip},rw,nfsvers=3 \
  --opt device=:/opt/ohpc-aarch64/opt/ohpc ohpc-aarch64
[root@x86_64 cross-sms-aarch64.sh]# docker volume create yum-aarch64
[root@x86_64 cross-sms-aarch64.sh]# docker volume ls
DRIVER              VOLUME NAME
local               ohpc-aarch64
local               yum-aarch64
[root@x86_64 cross-sms-aarch64.sh]# mkdir -p /opt/ohpc-aarch64/var/chroots
[root@x86_64 cross-sms-aarch64.sh]# tree /opt/ohpc-aarch64/
/opt/ohpc-aarch64/
├── opt
│   └── ohpc
└── var
    └── chroots

# 4. Install docker client shell
[root@x86_64 cross-sms-aarch64.sh]# install -o root -g root sms-aarch64.sh /usr/local/bin
```
