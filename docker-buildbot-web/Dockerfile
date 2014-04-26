# bladeRF buildbot web site

# VERSION 0.0.1

# Build using: docker build -t bladerf-buildbot-web .
# Run using:  docker run --rm --volumes-from BLADERF-AUTOBUILDER --name BLADERF-WEB bladerf-buildbot-web

FROM ubuntu
MAINTAINER Ryan Tucker <rtucker@gmail.com>

RUN apt-get update
RUN apt-get install -y nginx

RUN rm -v /etc/nginx/nginx.conf

ADD nginx.conf /etc/nginx/

EXPOSE 80

CMD service nginx start
