# bladeRF autobuild bot, Windows edition

# VERSION 0.0.1

FROM ubuntu
MAINTAINER Ryan Tucker <rtucker@gmail.com>

RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y gcc-mingw-w64-i686 g++-mingw-w64-i686 mingw-w64-tools
RUN apt-get install -y git wget unzip zip cmake

# Retrieve external files
# NOTE: This doesn't work for ftp:
#ADD ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip /tmp/
# ...by "URL", docker clearly means "string starting with http:// or https://"
RUN (cd /tmp && wget ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip)
ADD http://downloads.sourceforge.net/project/libusbx/releases/1.0.18/source/libusbx-1.0.18.tar.bz2 /tmp/

# Essential configuration for cmake cross-compiling
ADD inc/i686-w64-mingw32.toolchain /bladerf/i686-w64-mingw32.toolchain

# Unpack libusb source tree
RUN mkdir -p /pthreads
RUN (cd /pthreads && unzip /tmp/pthreads-w32-2-9-1-release.zip)
RUN ln -s /pthreads /usr/i686-w64-mingw32/pthreads
ENV LIBPTHREADSWIN32_PATH /pthreads/Pre-built.2

# Inject libusbx source tree
RUN (cd /tmp && tar -jxf libusbx-1.0.18.tar.bz2)

ADD inc/run-build.sh /bladerf/run-build.sh

WORKDIR /bladerf
