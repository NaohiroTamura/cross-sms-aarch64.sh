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
if [ -e /var/lib/yum ]; then
    package_volume=/var/lib/yum
elif [ -e /var/lib/zypp ]; then
    package_volume=/var/lib/zypp
else
    echo "unknown system"
    exit 1
fi

if [ -v $YUM_REPOS_D -a -v $LOCAL_REPO ]; then
    volume_options="-v ohpc-aarch64:/opt/ohpc \
                    -v yum-aarch64:$package_volume \
                    -v /opt/ohpc-aarch64/var/chroots:/var/chroots"
else
    volume_options="-v ohpc-aarch64:/opt/ohpc \
                    -v yum-aarch64:$package_volume \
                    -v /opt/ohpc-aarch64/var/chroots:/var/chroots \
                    -v ${YUM_REPOS_D}:/etc/yum.repos.d \
                    -v ${LOCAL_REPO}:${LOCAL_REPO/opt\/ohpc-aarch64\//}"
fi

if [ -v $HTTP_PROXY -a -v $HTTPS_PROXY ]; then
    proxy_options=
else
    proxy_options="-e HTTP_PROXY=$HTTP_PROXY \
                   -e http_proxy=$HTTP_PROXY \
                   -e HTTPS_PROXY=$HTTPS_PROXY \
                   -e https_proxy=$HTTPS_PROXY \
                   -e NO_PROXY=$NO_PROXY \
                   -e no_proxy=$NO_PROXY"
fi

docker run -it --rm --hostname aarch64 \
       $volume_options \
       $proxy_options \
       sms-aarch64.sh $@
