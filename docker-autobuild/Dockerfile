# bladeRF autobuild bot

# VERSION 0.0.5

FROM ubuntu
MAINTAINER Ryan Tucker <docker@ryantucker.us>
RUN sed -i -e "s|archive.ubuntu.com|mirrors.linode.com|g" /etc/apt/sources.list
RUN apt-get update
RUN apt-get dist-upgrade -y

RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y build-essential libstdc++6:i386 language-pack-en git clang curl
RUN apt-get build-dep -y bladerf

ADD inc/autobuild.sh        /bladerf/autobuild.sh
ADD inc/autobuild_inc.sh    /bladerf/autobuild_inc.sh
ADD inc/builder_loop.sh     /bladerf/builder_loop.sh
ADD inc/clean_builds.sh     /bladerf/clean_builds.sh
ADD inc/coverity_upload.sh  /bladerf/coverity_upload.sh
ADD inc/update_html.sh      /bladerf/update_html.sh

WORKDIR /srv/bladerf

ENV BINDIR          /bladerf
ENV WORKDIR         /srv/bladerf
ENV QUARTUS_PATH    /opt/altera/15.0
ENV COVERITY_PATH   /opt/coverity/cov-analysis-linux64-7.6.0/bin
ENV TZ              Etc/UTC
ENV REVISION        HEAD

RUN git config --global user.email "bladeRF-buildbot@ryantucker.us"
RUN git config --global user.name "bladeRF buildbot"

CMD ["bash", "/bladerf/builder_loop.sh"]
