# Copyright 2019 FUJITSU LIMITED
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
SHELL:=/bin/bash
.ONESHELL:

# set default value
export docker_image_tag ?= latest
base_os ?= centos7
install_path ?= /usr/local/bin

all: build


install:
	@echo "setting up prerequisites"
	if [ -v $(sms_ip) ]
	then
		echo "please set shell variable 'sms_ip'. ex. make install sms_ip=XX.XX.XX.XX" && \
		exit 1
	fi
	if [ ! -e /proc/sys/fs/binfmt_misc/aarch64 ]
	then \
		cp -p etc/binfmt.d/aarch64.conf /etc/binfmt.d && \
		systemctl restart systemd-binfmt
	fi
	if [ ! -e /proc/sys/fs/binfmt_misc/aarch64 ]
	then
		echo "failed binfmt_misc setup"
		exit 1
	fi
	if [ ! -d /opt/ohpc-aarch64/opt/ohpc ]
	then
		mkdir -p /opt/ohpc-aarch64/opt/ohpc
	fi
	if [ -e /var/lib/docker ]
	then
		nfs_network="172.17.0.0/16"
	else
		nfs_network="10.88.0.0/16"
	fi
	if ! grep -qe "^/opt/ohpc-aarch64/opt/ohpc\s*$${nfs_network}" /etc/exports
	then
		echo "/opt/ohpc-aarch64/opt/ohpc $${nfs_network}(rw,no_subtree_check,no_root_squash) $(sms_ip)/32(rw,no_subtree_check,no_root_squash)" >> /etc/exports && \
		exportfs -ra
	fi
	if docker volume ls | grep -qe "^local\s*ohpc-aarch64$$"
	then
		echo "Docker NFS Volume 'ohpc-aarch64' already exits. Please remove the contents so that the container can initialize the volume at the first invocation, otherwise it causes inconsistency"
	else
		docker volume create --driver local \
			--opt type=nfs \
			--opt o=addr=$(sms_ip),rw,nfsvers=3 \
			--opt device=:/opt/ohpc-aarch64/opt/ohpc ohpc-aarch64
	fi
	if docker volume ls | grep -qe "^local\s*yum-aarch64$$"
	then
		echo "Docker Local Volume 'yum-aarch64' already exits. Please remove the contents so that the container can initialize the volume at the first invocation, otherwise it causes inconsistency"
	else
		docker volume create yum-aarch64
	fi
	if [ ! -d /opt/ohpc-aarch64/var/chroots ]
	then
		mkdir -p /opt/ohpc-aarch64/var/chroots
	fi
	install -o root -g root  sms-aarch64.sh $(install_path)


build:
	@echo "building docker container"
	if [ ! -e /proc/sys/fs/binfmt_misc/aarch64 ]
	then
		cp -p etc/binfmt.d/aarch64.conf /etc/binfmt.d && \
		systemctl restart systemd-binfmt
	fi
	if [ ! -e /proc/sys/fs/binfmt_misc/aarch64 ]
	then
		echo "failed binfmt_misc setup"
		exit 1
	fi
	if [ ! -e usr/bin/qemu-aarch64-static ]
	then
		wget http://security.ubuntu.com/ubuntu/pool/universe/q/qemu/qemu-user-static_3.1+dfsg-2ubuntu3.6_amd64.deb && \
		( ar p qemu-user-static_3.1+dfsg-2ubuntu3.6_amd64.deb data.tar.xz | tar Jxvf - ./usr/bin/qemu-aarch64-static )
	fi
	if [ ! -e usr/bin/qemu-aarch64-static ]
	then
		echo "failed to download qemu-aarch64-static" && \
		exit 1
	fi
	if [ -v $(HTTP_PROXY) -a -v $(HTTPS_PROXY) ]
	then
		docker build -f Dockerfile.$(base_os) \
			-t sms-aarch64.sh:$(docker_image_tag) .
	else
		docker build -f Dockerfile.$(base_os) \
			-t sms-aarch64.sh:$(docker_image_tag) . \
			--build-arg HTTP_PROXY=$(HTTP_PROXY) \
			--build-arg http_proxy=$(HTTP_PROXY) \
			--build-arg HTTPS_PROXY=$(HTTPS_PROXY) \
			--build-arg https_proxy=$(HTTPS_PROXY)
	fi

clean:
	rm -rf usr *.deb*
