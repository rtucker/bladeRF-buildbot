# bladeRF autobuild bot

# VERSION 0.0.1

# Relies on: docker-buildtools/Dockerfile

FROM ubuntu
MAINTAINER Ryan Tucker <rtucker@gmail.com>

RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y build-essential libstdc++6:i386
RUN apt-get build-dep -y bladerf
RUN apt-get install -y git
RUN apt-get install -y clang

ADD inc/autobuild.sh        /bladerf/autobuild.sh
ADD inc/autobuild_inc.sh    /bladerf/autobuild_inc.sh
ADD inc/builder_loop.sh     /bladerf/builder_loop.sh
ADD inc/clean_builds.sh     /bladerf/clean_builds.sh
ADD inc/coverity_upload.sh  /bladerf/coverity_upload.sh
ADD inc/update_html.sh      /bladerf/update_html.sh

WORKDIR /srv/bladerf

ENV BINDIR          /bladerf
ENV WORKDIR         /srv/bladerf
ENV QUARTUS_PATH    /opt/altera/14.0
ENV COVERITY_PATH   /opt/coverity/cov-analysis-linux64-7.0.2/bin
ENV TZ              Etc/UTC
ENV REVISION        HEAD

CMD ["bash", "/bladerf/builder_loop.sh"]
