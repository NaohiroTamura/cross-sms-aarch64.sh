## Usage for OpenHPC 2.0 CentOS 8.2 (with Warewulf + OpenPBS)

Heading title hereinafter refers OpenHPC 2.0 (6 October 2020) [CentOS
8.2 aarch64 Install guide with Warewulf + OpenPBS][1].

Please notice that the section numbers of [CentOS 8.2 aarch64 Install
Guide (with Warewulf + OpenPBS)][1] are slightly different from [CentOS
8.2 x86_64 Install Guide (with Warewulf + OpenPBS)][2].

[1]: https://github.com/openhpc/ohpc/releases/download/v2.0.GA/Install_guide-CentOS8-Warewulf-OpenPBS-2.0-aarch64.pdf "CentOS 8.2 aarch64 Install Guide (with Warewulf + OpenPBS)"
[2]: https://github.com/openhpc/ohpc/releases/download/v2.0.GA/Install_guide-CentOS8-Warewulf-OpenPBS-2.0-x86_64.pdf "CentOS 8.2 x86_64 Install Guide (with Warewulf + OpenPBS)"

### 3.1 Enable OpenHPC repository for local use

The ohpc-release package has been already installed onto CentOS
8.2.2004 container. Please take a look at Dockerfile.centos8.

### 3.2 Installation template

You can install the OpenHPC documentation package (docs-ohpc) into SMS
x86_64 instead of SMS aarch64 container.

### 3.3 Add provisioning services on master node

The base meta-packages have been already installed into the
container. Please take a look at Dockerfile.centos8.

### 3.4 Add resource management services on master node

The openpbs server running on SMS x86_64 is used to serve to CN
aarch64. So you don't have to install the openpbs server meta-package
into the container.

### 3.5 Complete basic Warewulf setup for master node

The warewulf should have been already set up on SMS x86_64. So you
don't have to set it up in the container.

### 3.6 Deﬁne compute image for provisioning

#### 3.6.1 Build initial BOS image

In order to build aarch64 initial BOS(Base Operating System) Image,
you need to interact with *sms-aarch64.sh* container. Be careful about
the difference of the prompts between *[root@x86_64 ~]#* and
*[root@aarch64 /]#*

Note that the step **"cp -p /usr/bin/qemu-aarch64-static
$CHROOT/usr/bin"** before invoking *wwmkchroot*". This step is
essential to build the aarch64 initial BOS Image on SMS x86_64.

The environment variable *CHROOT* is set to */var/chroots/centos8.2*
of the container host local file system rather than
*/opt/ohpc/admin/images/centos8.2* on NFS volume, since NFS doesn't
support Linux Capabilities which *iputils* package requires.

```sh
# start interactive shell. it takes time to start for the first time
# due to volume initialization
[root@x86_64 ~]# sms-aarch64.sh

# create the image on host file system, but not on NFS
[root@aarch64 /]# export CHROOT=/var/chroots/centos8.2

# the essential step
[root@aarch64 /]# mkdir -p $CHROOT/usr/bin
[root@aarch64 /]# cp -p /usr/bin/qemu-aarch64-static $CHROOT/usr/bin

# If OHPC cluster is isolated from Internet, need to change 
# $YUM_MIRROR to the local repository.
[root@aarch64 /]# vi /usr/libexec/warewulf/wwmkchroot/centos-8.tmpl
YUM_MIRROR="/repos/centos-8.2-aarch64/BaseOS", "/repos/centos-8.2-aarch64/AppStream", "/repos/centos-8.2-aarch64/PowerTools"

# make sure wwmkchroot is returned with no error
[root@aarch64 /]# wwmkchroot -d centos-8 $CHROOT
...
+ echo 'Running: cleanup'
Running: cleanup
+ cleanup
+ '[' -n '' ']'
+ return 0

# If OHPC cluster is isolated from Internet, need to disable the 
# yum configuration file installed by the OS.
[root@aarch64 /]# perl -pi -e "s/enabled=1/enabled=0/" /var/chroots/fx700/etc/yum.repos.d/CentOS-*.repo

[root@aarch64 /]# yum -y --installroot $CHROOT install epel-release
[root@aarch64 /]# cp -p /etc/yum.repos.d/OpenHPC*.repo $CHROOT/etc/yum.repos.d
```

#### 3.6.2 Add OpenHPC components

```sh
[root@aarch64 /]# yum -y --installroot=$CHROOT install ohpc-base-compute
[root@aarch64 /]# cp -p /etc/resolv.conf $CHROOT/etc/resolv.conf
[root@aarch64 /]# yum -y --installroot=$CHROOT install openpbs-execution-ohpc
[root@aarch64 /]# perl -pi -e "s/PBS_SERVER=\S+/PBS_SERVER=${sms_name}/" $CHROOT/etc/pbs.conf
[root@aarch64 /]# echo "PBS_LEAF_NAME=${sms_name}" >> /etc/pbs.conf
[root@aarch64 /]# chroot $CHROOT opt/pbs/libexec/pbs_habitat
[root@aarch64 /]# perl -pi -e "s/\$clienthost \S+/\$clienthost ${sms_name}/" $CHROOT/var/spool/pbs/mom_priv/config
[root@aarch64 /]# echo "\$usecp *:/home /home" >> $CHROOT/var/spool/pbs/mom_priv/config
[root@aarch64 /]# chroot $CHROOT systemctl enable pbs
[root@aarch64 /]# yum -y --installroot=$CHROOT install chrony
[root@aarch64 /]# echo "server ${sms_ip}" >> $CHROOT/etc/chrony.conf
[root@aarch64 /]# yum -y --installroot=$CHROOT install kernel
[root@aarch64 /]# yum -y --installroot=$CHROOT install lmod-ohpc
# optional: in case of compile on Compute Node
[root@aarch64 /]# yum -y --installroot=$CHROOT install glibc-headers glibc-devel
[root@aarch64 /]# exit
```

#### 3.6.3 Customize system conﬁguration

The warewulf database is running on SMS x86_64, and all interactions
with the database must occur on the parent x86_64 host.  The
containerized aarch64 environment is now used to create a customized
chrooted VNFS environment in a path that is accessible by the parent
x86_64 host.

Please note that the path */var/chroots/images/centos8.2*
in the container is equivalent to the path
*/opt/ohpc-aarch64/var/chroots/centos8.2* on SMS x86_64.

The environment variable *AARCH64_CHROOT* is chosen to prevent us from
mixing up *CHROOT* inside the container with *CHROOT* outside the
container.

```sh
[root@x86_64 ~]# export AARCH64_CHROOT=/opt/ohpc-aarch64/var/chroots/centos8.2

# copy ssh public key
[root@x86_64 ~]# cat ~/.ssh/cluster.pub >> $AARCH64_CHROOT/root/.ssh/authorized_keys
[root@x86_64 ~]# chmod 0600 $AARCH64_CHROOT/root/.ssh/authorized_keys

# Add NFS client mounts of /home and /opt/ohpc/pub to base image
[root@x86_64 ~]# echo "${sms_ip}:/home /home nfs nfsvers=3,nodev,nosuid 0 0" >> $AARCH64_CHROOT/etc/fstab
[root@x86_64 ~]# echo "${sms_ip}:/opt/ohpc-aarch64/opt/ohpc/pub /opt/ohpc/pub nfs nfsvers=3,nodev 0 0" >> $AARCH64_CHROOT/etc/fstab

# Export /home and OpenHPC public packages from master server
[root@x86_64 ~]# echo "/opt/ohpc-aarch64/opt/ohpc/pub *(ro,no_subtree_check,fsid=12)" >> /etc/exports
[root@x86_64 ~]# exportfs -ra
```

### 3.7 Finalizing provisioning conﬁguration

#### 3.7.1 Assemble bootstrap image

In order to create aarch64 bootstrap, please make sure to install
*warewulf-provision-ohpc-initramfs-aarch64* package and
*warewulf-provision-ohpc-server-ipxe-aarch64* package into SMS
x86_64. 

The kernel version of the aarch64 initial BOS image is different from
the kernel version of SMS x86_64. So please check the version as
follows.

The bootstrap image created on x86_64 have *ARCH* attribute
*x86_64*. So please update the ARCH attribute as follows.

```sh
[root@x86_64 ~]# yum install -y warewulf-provision-ohpc-initramfs-aarch64 warewulf-provision-ohpc-server-ipxe-aarch64

[root@x86_64 ~]# export WW_CONF=/etc/warewulf/bootstrap.conf
[root@x86_64 ~]# echo "drivers += updates/kernel/" >> $WW_CONF

# check the kernel version of the aarch64 BOS image
[root@x86_64 ~]# ls $AARCH64_CHROOT/boot/vmlinuz*
/opt/ohpc-aarch64/var/chroots/centos8.2/boot/vmlinuz-4.18.0-193.19.1.el8_2.aarch64

# specifty the kernel version
[root@x86_64 ~]# wwbootstrap --chroot $AARCH64_CHROOT 4.18.0-193.19.1.el8_2.aarch64

# Notice that ARCH is x86_64
[root@x86_64 ~]# wwsh bootstrap list
BOOTSTRAP NAME            SIZE (M)      ARCH
4.18.0-193.19.1.el8_2.aarch64 38.7          x86_64

# Update the ARCH
[root@x86_64 ~]# wwsh bootstrap set -y -a aarch64 4.18.0-193.19.1.el8_2.aarch64

# make sure that ARCH is updated to aarch64
[root@x86_64 ~]# wwsh bootstrap list
BOOTSTRAP NAME            SIZE (M)      ARCH
4.18.0-193.19.1.el8_2.aarch64 38.7         aarch64
```

#### 3.7.2 Assemble Virtual Node File System (VNFS) image


The Virtual Node File System (VNFS) image created on x86_64 have
*ARCH* attribute *x86_64*. So please update the ARCH attribute as
follows.


```sh
# optional: in case of compile on Compute Node
[root@x86_64 ~]# perl -pi -e "s/^hybridize \+= \/usr\/include/\#hybridize \+= \/usr\/include/" /etc/warewulf/vnfs.conf
# Assemble Virtual Node File System (VNFS) image
[root@x86_64 ~]# wwvnfs --chroot $AARCH64_CHROOT centos8.2-aarch64

# Notice that ARCH is x86_64
[root@x86_64 ~]# wwsh vnfs list
VNFS NAME            SIZE (M)   ARCH       CHROOT LOCATION
centos8.2-aarch64    354.0      x86_64     /opt/ohpc-aarch64/var/chroots/centos8.2

# Update the ARCH
[root@x86_64 ~]# wwsh vnfs set -y centos8.2-aarch64 -a aarch64

# make sure that ARCH is updated to aarch64
[root@x86_64 ~]# wwsh vnfs list
VNFS NAME            SIZE (M)   ARCH       CHROOT LOCATION
centos8.2-aarch64    354.0      aarch64    /opt/ohpc-aarch64/var/chroots/centos8.2
```

#### 3.7.3 Register nodes for provisioning

```sh
# Add nodes to Warewulf data store as aarch64
[root@x86_64 /]# wwsh node new ${c_name} --arch=aarch64 --ipaddr=${c_ip} --hwaddr=${c_mac} -D ${eth_provision}

# Additional step required if desiring to use predictable network interface
# naming schemes (e.g. en4s0f0). Skip if using eth# style names.
[root@x86_64 /]# export kargs="${kargs} net.ifnames=1,biosdevname=1 earlycon=p1011,0x1c050000 console=ttyAMA0"
[root@x86_64 /]# wwsh provision set --postnetdown=1 "${compute_regex}"

# Define provisioning image for hosts
[root@x86_64 /]# wwsh provision set ${c_name} --vnfs=centos8.2-aarch64 --bootstrap=4.18.0-193.19.1.el8_2.aarch64 \
--files=dynamic_hosts,passwd,group,shadow,network

# Restart dhcp / update PXE
[root@x86_64 /]# systemctl restart dhcpd
[root@x86_64 /]# wwsh pxe update
```

#### 3.7.4 Optional kernel arguments

```sh
# Set optional compute node kernel command line arguments.
[root@x86_64 /]# wwsh -y provision set "${compute_regex}" --kargs="${kargs}"
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
[root@x86_64 ~]# sms-aarch64.sh yum -y install gnu9-compilers-ohpc
```

### 4.3 MPI Stacks

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install openmpi4-gnu9-ohpc mpich-ofi-gnu9-ohpc
```

### 4.4 Performance Tools

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-perf-tools
```

### 4.5 Setup default development environment

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install lmod-defaults-gnu9-openmpi4-ohpc
```

### 4.6 3rd Party Libraries and Tools

```sh
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-serial-libs
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-io-libs
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-python-libs
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-runtimes

[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-mpich-parallel-libs
[root@x86_64 ~]# sms-aarch64.sh yum -y install ohpc-gnu9-openmpi3-parallel-libs
```
