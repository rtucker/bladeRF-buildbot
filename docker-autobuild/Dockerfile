# bladeRF autobuild bot
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
ARG QUARTUS_VERSION=17.0

FROM ${QUARTUS_BASEIMAGE}:${QUARTUS_VERSION}

# bring QUARTUS_VERSION forward
ARG QUARTUS_VERSION=17.0

LABEL maintainer="Rey Tucker <bladeRF-buildbot@reytucker.us>"
LABEL version="0.0.8"
LABEL description="Autobuild bot for bladeRF FPGA images"

# Set up build arguments
# Override with: --build-arg APT_MIRROR=whatever
ARG APT_MIRROR=mirrors.linode.com
ARG DEFAULT_REVISION=HEAD

# Set up environment variables
ENV TZ=UTC
ENV BINDIR=/bladerf
ENV WORKDIR=/data/work
ENV QUARTUS_SHORTVERSION=17.0
ENV QUARTUS_LONGVERSION=17.0.2.602
ENV QUARTUS_PATH=/opt/intelFPGA_lite/${QUARTUS_SHORTVERSION}
ENV REVISION=${DEFAULT_REVISION}
ENV COVERITY_PATH=/opt/coverity/cov-analysis-linux64-7.6.0/bin

#ENV BUILD_FIRMWARE=YES
#ENV BUILD_COVERITY=YES

# Use local mirror
RUN sed -i -e "s|archive.ubuntu.com|${APT_MIRROR}|g" /etc/apt/sources.list

# Add i386 architecture
RUN dpkg --add-architecture i386

# Install things...
RUN apt-get update && apt-get install -y \
        build-essential \
        clang \
        curl \
        git \
        gtk2-engines-pixbuf:i386 \
        language-pack-en \
        lib32ncurses5-dev \
        libc6:i386 \
        libncurses5:i386 \
        libstdc++6:i386 \
        libtcmalloc-minimal4 \
        libxext6:i386 \
        libxft2:i386 \
        libzmq3-dev \
        locales \
        lsb-release \
        unixodbc-dev \
    && apt-get build-dep -y bladerf \
    && rm -rf /var/lib/apt/lists/*

# Locale setup
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

# User setup
RUN groupadd -r bladerf \
    && useradd --no-log-init -r -g bladerf bladerf \
    && mkdir -p /home/bladerf \
    && chown -R bladerf.bladerf /home/bladerf

# Storage setup
RUN mkdir -p ${WORKDIR}
RUN chown -R bladerf.bladerf ${WORKDIR}
VOLUME /data

# Become user
USER bladerf

# Git setup
RUN git config --global user.email "bladeRF-buildbot@reytucker.us"
RUN git config --global user.name  "bladeRF buildbot"

# Add scripts!
COPY inc/autobuild.sh        ${BINDIR}/autobuild.sh
COPY inc/autobuild_inc.sh    ${BINDIR}/autobuild_inc.sh
COPY inc/builder_loop.sh     ${BINDIR}/builder_loop.sh
COPY inc/clean_builds.sh     ${BINDIR}/clean_builds.sh
COPY inc/coverity_upload.sh  ${BINDIR}/coverity_upload.sh
COPY inc/update_html.sh      ${BINDIR}/update_html.sh

# Do the thing!
WORKDIR ${WORKDIR}
CMD ["bash", "/bladerf/builder_loop.sh"]

