# bladeRF autobuild bot, Windows edition

# VERSION 0.0.4

FROM ubuntu
MAINTAINER Ryan Tucker <docker@ryantucker.us>
RUN sed -i -e "s|archive.ubuntu.com|mirrors.linode.com|g" /etc/apt/sources.list
RUN apt-get update
RUN apt-get dist-upgrade -y

RUN apt-get install -y build-essential gcc-mingw-w64-i686 g++-mingw-w64-i686 mingw-w64-tools git wget unzip zip cmake

# External files:
# ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip
# http://downloads.sourceforge.net/project/libusbx/releases/1.0.18/source/libusbx-1.0.18.tar.bz2
ADD inc/pthreads-w32-2-9-1-release.zip /tmp/
ADD inc/libusbx-1.0.18.tar.bz2 /tmp/

# Essential configuration for cmake cross-compiling
ADD inc/i686-w64-mingw32.toolchain /bladerf/i686-w64-mingw32.toolchain

# Unpack pthreads
RUN mkdir -p /pthreads
RUN (cd /pthreads && unzip /tmp/pthreads-w32-2-9-1-release.zip)
RUN ln -s /pthreads /usr/i686-w64-mingw32/pthreads
ENV LIBPTHREADSWIN32_PATH /pthreads/Pre-built.2

ADD inc/run-build.sh /bladerf/run-build.sh

WORKDIR /bladerf
