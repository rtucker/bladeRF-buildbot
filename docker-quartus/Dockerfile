# Quartus installer for Docker
#
# Copyright (c) 2018 Rey Tucker <bladeRF-buildbot@reytucker.us>
# Based on work by Christof Harnischmacher: https://github.com/chriz2600/quartus-lite/
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

FROM ubuntu:16.04

LABEL maintainer="Rey Tucker <bladeRF-buildbot@reytucker.us>"
LABEL version="0.0.1"
LABEL description="Installer for Altera Quartus Prime"

# Use local apt mirror
ARG APT_MIRROR=mirrors.linode.com
RUN sed -i -e "s|archive.ubuntu.com|${APT_MIRROR}|g" /etc/apt/sources.list

# Install things...
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
        curl \
        expect \
        locales \
        lsb-release \
 && rm -rf /var/lib/apt/lists/* \
 && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && /usr/sbin/update-locale LANG=en_US.UTF-8

# Scripts
COPY inc/setup /root/

# Run the installation, clean up bad libs
ARG QUARTUS_VERSION
ARG QUARTUS_DOWNLOAD
ARG QUARTUS_MD5SUM

ENV QUARTUS_PATH=/opt/intelFPGA_lite/${QUARTUS_VERSION}

RUN mkdir -p /tmp/inst /tmp/dl \
 && curl -o /tmp/dl/quartus.tar "${QUARTUS_DOWNLOAD}" \
 && echo "${QUARTUS_MD5SUM} /tmp/dl/quartus.tar" | md5sum -c - \
 && tar -C /tmp/inst -xf /tmp/dl/quartus.tar \
 && rm -rf /tmp/dl \
 && cd /tmp/inst \
 && /root/setup ${QUARTUS_VERSION} ${QUARTUS_PATH} \
 && rm -rf /tmp/inst \
           ${QUARTUS_PATH}/quartus/linux64/libboost_system.so \
           ${QUARTUS_PATH}/quartus/linux64/libccl_curl_drl.so \
           ${QUARTUS_PATH}/quartus/linux64/libstdc++.so.6 \
           ${QUARTUS_PATH}/modelsim_ae

