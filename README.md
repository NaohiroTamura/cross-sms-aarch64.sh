# Cross SMS aarch64 Shell

This software is [OpenHPC][1] utility which enables without physical
aarch64 machine to assemble aarch64 bootstrap image and Virtual Node
File System (VNFS) image, and to install aarch64 OpenHPC Development
Components on System Management Server (SMS) x86_64.
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

* [OpenHPC 1.3.9 x86_64 (CentOS 7.7)][2] or [OpenHPC 2.0 x86_64
  (CentOS 8.2, Leap 15.2)][3]
* docker/docker-ce 1.13.1 later

Type the following commands to verify the software versions:

```sh
[root@x86_64 ~]# rpm -qa | grep ohpc-base
ohpc-base-1.3.8-3.1.ohpc.1.3.8.x86_64

[root@x86_64 ~]# docker -v
Docker version 1.13.1, build cccb291/1.13.1
```

[2]: https://github.com/openhpc/ohpc/wiki/1.3.X "Community building blocks for HPC systems (v1.3.9)"
[3]: https://github.com/openhpc/ohpc/wiki/2.X "Community building blocks for HPC systems (2.0)"

Instead of docker, podman will be supported if [NFS volume issue][4]
is fixed.
As of Oct. 27 2020, both podman 1.6.2 on CentOS 8.2 and podman 2.0.6
on OpenSUSE Leap 15.2 have the issue.

[4]: https://github.com/containers/podman/issues/4304


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
[root@x86_64 cross-sms-aarch64.sh]# make base_os=centos8  # CentOS 8.2 for OpenHPC 2.0
[root@x86_64 cross-sms-aarch64.sh]# make base_os=leap15   # Leap 15.2  for OpenHPC 2.0

4. install
[root@x86_64 cross-sms-aarch64.sh]# make install sms_ip=XX.XX.XX.XX
```

## Usage

*sms-aarch64.sh* is mainly used for two purposes:

1. assemble aarch64 bootstrap image and Virtual Node File System
   (VNFS) image onto SMS x86_64 file system
2. install aarch64 OpenHPC Development Components into SMS x86_64 file
   system


- [OpenHPC 1.3.9 CentOS 7.7 (with Warewulf + Slurm)](doc/usage_centos7_slurm.md)
- [OpenHPC 2.0 CentOS 8.2 (with Warewulf + Slurm)](doc/usage_centos8_slurm.md)
- [OpenHPC 2.0 CentOS 8.2 (with Warewulf + OpenPBS)](doc/usage_centos8_openpbs.md)
- [OpenHPC 2.0 Leap 15.2 (with Warewulf + Slurm)](doc/usage_leap15_slurm.md)


## Cross Platform Cluster Example using QEMU

- [OpenHPC 2.0 CentOS 8.2 (with Warewulf + Slurm)](doc/example_qemu_centos8_slurm.md)

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
    centos-<version>.<release>.repo epel-<version>.repo OpenHPC.local.repo

    [root@x86_64 ~]# export LOCAL_REPO=/opt/ohpc-aarch64/repos

    [root@x86_64 ~]# ls $LOCAL_REPO
    CentOS_<version> centos-<version>.<release> epel-<version>

    [root@x86_64 ~]# sms-aarch64.sh

    [root@aarch64 /]# ls /etc/yum.repos.d
    centos-<version>.<release>  epel-<version>  OpenHPC.local.repo

    [root@aarch64 /]# ls /repos
    centos-<version>.<release>.repo epel-<version>.repo OpenHPC.local.repo
    ```

    * if **LOCAL_REPO** path is **NOT** in */opt/ohpc-aarch64* of the
      container host such as */repos*, it is mapped to the same path
      in the container such as */repos* in this case as below.

    ```sh
    [root@x86_64 ~]# export LOCAL_REPO=/repos

    [root@x86_64 ~]# ls $LOCAL_REPO
    CentOS_<version>  centos-<version>.<release>  epel-<version>

    [root@x86_64 ~]# sms-aarch64.sh

    [root@aarch64 /]# ls /repos
    CentOS_<version>  centos-<version>.<release>  epel-<version>
    ```
And also need to change $YUM_MIRROR to the local repository.
Corresponds to wwmkchroot written in "3.6 Define compute image for 
provisioning" of each Usage.
    ```sh
    [root@aarch64 /]# export YUM_MIRROR=""/repos/centos-<version>.<release>/BaseOS", "/repos/centos-<version>.<release>/AppStream", "/repos/centos-<version>.<release>-aarch64/PowerTools""
    [root@aarch64 /]# wwmkchroot -d centos-<version> $CHROOT

    OS Yum configuration files installed with the wwmkchroot command 
    must be disabled.
    ```sh
    [root@aarch64 /]# perl -pi -e "s/enabled=1/enabled=0/" $CHROOT/etc/yum.repos.d/CentOS-*.repo
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
