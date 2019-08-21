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

# set default value
export docker_image_tag ?= latest
base_os ?= centos7

all: build

build:
	@echo "building docker container"
	if [ -v $(HTTP_PROXY) -a -v $(HTTPS_PROXY) ]; \
	then \
		docker build -f Dockerfile.$(base_os) \
			-t sms-aarch64.sh:$(docker_image_tag) . ; \
	else \
		docker build -f Dockerfile.$(base_os) \
			-t sms-aarch64.sh:$(docker_image_tag) . \
			--build-arg HTTP_PROXY=$(HTTP_PROXY) \
			--build-arg http_proxy=$(HTTP_PROXY) \
			--build-arg HTTPS_PROXY=$(HTTPS_PROXY) \
			--build-arg https_proxy=$(HTTPS_PROXY) ; \
	fi
