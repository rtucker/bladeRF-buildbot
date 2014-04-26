# bladeRF autobuild bot

# VERSION 0.0.1

# Relies on: docker-buildtools/Dockerfile

# Build using: docker build -t bladerf-autobuild .
# Run using:  docker run --volumes-from BLADERF-BUILDTOOLS --name BLADERF-AUTOBUILDER bladerf-autobuild
# Access build results in other containers with:  --volumes-from whatever-i-am

FROM ubuntu
MAINTAINER Ryan Tucker <rtucker@gmail.com>

VOLUME  ["/srv/bladerf"]

RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y build-essential cmake git wget doxygen libusb-1.0-0-dev libusb-1.0-0 pkg-config libstdc++6:i386

ADD inc/autobuild.sh /opt/bladerf/autobuild.sh
ADD inc/autobuild_inc.sh /opt/bladerf/autobuild_inc.sh
ADD inc/builder_loop.sh /opt/bladerf/builder_loop.sh
ADD inc/clean_builds.sh /opt/bladerf/clean_builds.sh
ADD inc/update_html.sh /opt/bladerf/update_html.sh

ADD https://raw.githubusercontent.com/rtucker/bladeRF-buildbot/master/autobuild/misc/bladerf_pic.jpg /srv/bladerf/builds/misc/

WORKDIR /srv/bladerf

ENV BINDIR /opt/bladerf
ENV WORKDIR /srv/bladerf
ENV QUARTUS_PATH /opt/altera/13.1.1
ENV COVERITY_PATH /opt/coverity/cov-analysis-linux64-7.0.2/bin
ENV TZ Etc/UTC
ENV REVISION HEAD

CMD ["bash", "/opt/bladerf/builder_loop.sh"]
