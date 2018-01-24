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

# Set up build arguments
# Override with: --build-arg APT_MIRROR=whatever
ARG APT_MIRROR=mirrors.linode.com
ARG QUARTUS_VERSION=17.0
ARG QUARTUS_DOWNLOAD=http://download.altera.com/akdlm/software/acdsinst/17.0std.2/602/ib_tar/Quartus-lite-17.0.2.602-linux.tar

# Use local apt mirror
RUN sed -i -e "s|archive.ubuntu.com|${APT_MIRROR}|g" /etc/apt/sources.list

# Where to install
ENV QUARTUS_PATH=/opt/intelFPGA_lite/${QUARTUS_VERSION}

# Add i386 architecture
RUN dpkg --add-architecture i386

# Install things...
RUN apt-get update && apt-get install -y \
        curl \
        expect \
        libboost-system-dev \
        libc6:i386 \
        libstdc++6:i386 \
        libtcmalloc-minimal4 \
        locales \
        lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Locale setup
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

# Scripts
COPY inc/setup /root/

# Run the installation
RUN mkdir -p /root/quartus && \
    cd /root/quartus && \
    (curl ${QUARTUS_DOWNLOAD} | tar xf -) && \
    /root/setup ${QUARTUS_VERSION} ${QUARTUS_PATH} && \
    rm -rf /root/quartus

# Clean up bad libs
RUN rm ${QUARTUS_PATH}/quartus/linux64/libboost_system.so \
       ${QUARTUS_PATH}/quartus/linux64/libccl_curl_drl.so \
       ${QUARTUS_PATH}/quartus/linux64/libstdc++.so.6

