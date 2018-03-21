# bladeRF autobuild bot: FPGA build Dockerfile
#
# Copyright (c) 2014-2018 Rey Tucker <bladeRF-buildbot@reytucker.us>
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

ARG QUARTUS_BASEIMAGE=quartus-lite
ARG QUARTUS_VERSION=17.1

FROM ${QUARTUS_BASEIMAGE}:${QUARTUS_VERSION}

# bring QUARTUS_VERSION forward
ARG QUARTUS_VERSION=17.0

LABEL maintainer="Rey Tucker <bladeRF-buildbot@reytucker.us>"
LABEL version="0.0.2"
LABEL description="Worker for building FPGA images"

# Set up build arguments
# Override with: --build-arg APT_MIRROR=whatever
ARG APT_MIRROR=mirrors.linode.com
ARG DEFAULT_REVISION=HEAD

# Set up environment variables
ENV TZ=UTC \
    BINDIR=/bladerf \
    WORKDIR=/data/work \
    QUARTUS_PATH=/opt/intelFPGA_lite/${QUARTUS_VERSION} \
    REVISION=${DEFAULT_REVISION} \
    BUILDCOMMAND=${BINDIR}/autobuild.sh

# Use local mirror
RUN sed -i -e "s|archive.ubuntu.com|${APT_MIRROR}|g" /etc/apt/sources.list

# Add i386 architecture
RUN dpkg --add-architecture i386

# Install things...
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
        build-essential \
        clang \
        curl \
        git \
        language-pack-en \
        libc6:i386 \
        libstdc++6:i386 \
        libtcmalloc-minimal4 \
        locales \
        lsb-release \
        python3-boto3 \
 && apt-get build-dep -y bladerf \
 && rm -rf /var/lib/apt/lists/* \
 && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && /usr/sbin/update-locale LANG=en_US.UTF-8

# User setup
RUN groupadd -r bladerf \
    && useradd --no-log-init -r -g bladerf bladerf \
    && mkdir -p /home/bladerf \
    && chown -R bladerf.bladerf /home/bladerf

# Become user
USER bladerf

# Git setup
RUN git config --global user.email "bladeRF-buildbot@reytucker.us"
RUN git config --global user.name  "bladeRF buildbot"

# Add scripts!
COPY inc/autobuild.sh       ${BINDIR}/autobuild.sh
COPY inc/autobuild_inc.sh   ${BINDIR}/autobuild_inc.sh
COPY inc/aws_config         /home/bladerf/.aws/config
COPY inc/aws_credentials    /home/bladerf/.aws/credentials

COPY inc/common/queue_mgr.py    ${BINDIR}/queue_mgr.py
COPY inc/worker.py              ${BINDIR}/worker.py

# Do the thing!
WORKDIR ${WORKDIR}
CMD ["python3", "-u", "/bladerf/worker.py", "bladerf-buildbot-worker"]
