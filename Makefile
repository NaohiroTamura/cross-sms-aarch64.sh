# Copyright 2019-2020 FUJITSU LIMITED
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

# GNU Make 3.82 centos7 and later

# debug
#.SHELLFLAGS += -x

# set default values
docker_image_tag ?= latest
base_os ?= centos7
install_path ?= /usr/local/bin
nfs_network ?= $(if $(wildcard /var/lib/docker),172.17.0.0/16,10.88.0.0/16)

# check command installations
HAVE_WGET := $(shell which wget)
ifndef HAVE_WGET
$(error wget is missing)
endif

HAVE_AR := $(shell which ar)
ifndef HAVE_AR
$(error ar is missing, please install binutils package)
endif

HAVE_DOCKER := $(shell which docker)
ifndef HAVE_DOCKER
$(error docker is missing)
endif
docker_volume_inspect = $(shell docker volume inspect -f '{{.Scope}} {{.Name}}' $(1) 2>/dev/null)

ifdef HTTP_PROXY
ifdef HTTPS_PROXY
DOCKER_BUILD_ARGS := --build-arg HTTP_PROXY=$(HTTP_PROXY) \
		     --build-arg http_proxy=$(HTTP_PROXY) \
		     --build-arg HTTPS_PROXY=$(HTTPS_PROXY) \
		     --build-arg https_proxy=$(HTTPS_PROXY)
endif
endif

# define variables
QEMU_USER_STATIC_DEB_FILE := qemu-user-static_4.0+dfsg-0ubuntu9.8_amd64.deb

QEMU_USER_STATIC_DEB_URL := http://security.ubuntu.com/ubuntu/pool/universe/q/qemu/$(QEMU_USER_STATIC_DEB_FILE)

CURRENT_QEMU_USER_STATIC := usr/bin/qemu-aarch64-static

PROC_BINFMT_MISC_AARCH64 := /proc/sys/fs/binfmt_misc/aarch64

BINFMT_MISC_AARCH64_CONF := /etc/binfmt.d/aarch64.conf
CURRENT_BINFMT_MISC_AARCH64_CONF := $(patsubst /%,%,$(BINFMT_MISC_AARCH64_CONF))

# define targets
all: build

build: $(PROC_BINFMT_MISC_AARCH64) $(CURRENT_QEMU_USER_STATIC)
	docker build -f Dockerfile.$(base_os) $(DOCKER_BUILD_ARGS) \
		-t sms-aarch64.sh:$(docker_image_tag) .

$(CURRENT_QEMU_USER_STATIC):
	$(if $(wildcard $(QEMU_USER_STATIC_DEB_FILE)),,\
		wget $(QEMU_USER_STATIC_DEB_URL))
	ar p $(QEMU_USER_STATIC_DEB_FILE) data.tar.xz | \
		tar Jxvf - ./$@

$(PROC_BINFMT_MISC_AARCH64): $(BINFMT_MISC_AARCH64_CONF)
	systemctl restart systemd-binfmt

$(BINFMT_MISC_AARCH64_CONF): $(CURRENT_BINFMT_MISC_AARCH64_CONF)
	cp -p $< $(@D)

install: $(install_path)/sms-aarch64.sh

$(install_path)/sms-aarch64.sh: sms-aarch64.sh docker_volume
	install -o root -g root $< $(install_path)

docker_volume: $(PROC_BINFMT_MISC_AARCH64)
	$(if $(sms_ip),,$(error please set shell variable 'sms_ip'. \
		ex. make install sms_ip=XX.XX.XX.XX))
	mkdir -p /opt/ohpc-aarch64/opt/ohpc
	if ! grep -qe "^/opt/ohpc-aarch64/opt/ohpc\s*$${nfs_network}" /etc/exports; then\
		echo "/opt/ohpc-aarch64/opt/ohpc $(nfs_network)(rw,no_subtree_check,no_root_squash) $(sms_ip)/32(rw,no_subtree_check,no_root_squash)" >> /etc/exports;\
		exportfs -ra;\
	fi
	$(if $(filter local ohpc-aarch64,$(call docker_volume_inspect,ohpc-aarch64)),\
		$(error Docker NFS Volume 'ohpc-aarch64' already exits. \
			Please remove or rename the volume so that the container \
			can initialize the contents at the first invocation, \
			otherwise it causes inconsistency),\
		docker volume create --driver local \
			--opt type=nfs \
			--opt o=addr=$(sms_ip),rw,nfsvers=3 \
			--opt device=:/opt/ohpc-aarch64/opt/ohpc ohpc-aarch64)
	$(if $(filter local yum-aarch64,$(call docker_volume_inspect,yum-aarch64)),\
		$(error Docker Local Volume 'yum-aarch64' already exits. \
			Please remove or rename the volume so that the container \
			can initialize the contents at the first invocation, \
			otherwise it causes inconsistency),\
		docker volume create yum-aarch64)
	mkdir -p /opt/ohpc-aarch64/var/chroots

remove-docker-vol:
	docker volume rm ohpc-aarch64 yum-aarch64

clean:
	rm -rf usr *.deb*
