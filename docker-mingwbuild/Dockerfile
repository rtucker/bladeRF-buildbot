# bladeRF autobuild bot, Windows edition

# VERSION 0.0.1

# Relies on: docker-buildtools/Dockerfile

FROM ubuntu
MAINTAINER Ryan Tucker <rtucker@gmail.com>

#RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y gcc-mingw-w64-i686 g++-mingw-w64-i686 mingw-w64-tools
RUN apt-get install -y git wget unzip cmake

# Essential configuration for cmake cross-compiling
ADD inc/i686-w64-mingw32.toolchain /bladerf/i686-w64-mingw32.toolchain

# Inject pthreads-win32
ADD inc/pthreads-w32-2-9-1-release.zip /tmp/pthreads-w32-2-9-1-release.zip
RUN mkdir -p /pthreads
RUN (cd /pthreads && unzip /tmp/pthreads-w32-2-9-1-release.zip)
RUN ln -s /pthreads /usr/i686-w64-mingw32/pthreads
ENV LIBPTHREADSWIN32_PATH /pthreads/Pre-built.2

# Inject libusbx source tree
ADD inc/libusbx-1.0.18.tar.bz2 /tmp

ADD inc/run-build.sh /bladerf/run-build.sh

WORKDIR /bladerf
