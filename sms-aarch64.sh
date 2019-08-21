#!/bin/bash

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

if [ -v $HTTP_PROXY -a -v $HTTPS_PROXY ]; then 
    docker run -it --rm --hostname aarch64 \
           -v ohpc-aarch64:/opt/ohpc \
           -v yum-aarch64:/var/lib/yum \
           sms-aarch64.sh $@
else
    docker run -it --rm --hostname aarch64 \
           -v ohpc-aarch64:/opt/ohpc \
           -v yum-aarch64:/var/lib/yum \
           -e HTTP_PROXY=$HTTP_PROXY -e http_proxy=$HTTP_PROXY \
           -e HTTPS_PROXY=$HTTPS_PROXY -e https_proxy=$HTTPS_PROXY \
           -e NO_PROXY=$no_proxy -e no_proxy=$NO_PROXY \
           sms-aarch64.sh $@
fi
