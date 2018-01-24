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

FROM ubuntu:16.04

LABEL maintainer="Rey Tucker <bladeRF-buildbot@reytucker.us>"
LABEL version="0.0.8"
LABEL description="Autobuild bot for bladeRF FPGA images"

# Set up build arguments
# Override with: --build-arg APT_MIRROR=whatever
ARG APT_MIRROR=mirrors.linode.com

# Set up environment variables
ENV BINDIR=/bladerf
ENV WORKDIR=/srv/bladerf
ENV QUARTUS_ARCHIVE=/opt/altera/quartus_17.0.2.602.tar.bz2
ENV QUARTUS_PATH=/usr/local/altera/17.0
ENV TZ=UTC
ENV REVISION=HEAD
#ENV COVERITY_PATH=/opt/coverity/cov-analysis-linux64-7.6.0/bin

# Use local mirror
RUN sed -i -e "s|archive.ubuntu.com|${APT_MIRROR}|g" /etc/apt/sources.list

# Add i386 architecture
RUN dpkg --add-architecture i386

# Latest sauce
RUN apt-get update
RUN apt-get dist-upgrade -y

# Install amd64 stuff
RUN apt-get install -y \
    build-essential \
    clang \
    curl \
    git \
    language-pack-en \
    lib32ncurses5-dev \
    libtcmalloc-minimal4 \
    libzmq3-dev \
    locales \
    lsb-release \
    unixodbc-dev

# Install i386 stuff
RUN apt-get install -y \
    gtk2-engines-pixbuf:i386 \
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
    libxext6:i386 \
    libxft2:i386

# Install remaining build dependencies for bladeRF
RUN apt-get build-dep -y bladerf

# Locale setup
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

# Git setup
RUN git config --global user.email "bladeRF-buildbot@reytucker.us"
RUN git config --global user.name  "bladeRF buildbot"

# Add scripts!
ADD inc/autobuild.sh        ${BINDIR}/autobuild.sh
ADD inc/autobuild_inc.sh    ${BINDIR}/autobuild_inc.sh
ADD inc/builder_loop.sh     ${BINDIR}/builder_loop.sh
ADD inc/clean_builds.sh     ${BINDIR}/clean_builds.sh
ADD inc/coverity_upload.sh  ${BINDIR}/coverity_upload.sh
ADD inc/update_html.sh      ${BINDIR}/update_html.sh

# Do the thing!
WORKDIR ${WORKDIR}
CMD ["bash", "/bladerf/builder_loop.sh"]

