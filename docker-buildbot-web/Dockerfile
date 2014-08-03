# bladeRF buildbot web site

# VERSION 0.0.2

FROM ubuntu
MAINTAINER Ryan Tucker <rtucker@gmail.com>

VOLUME ["/var/log/nginx"]

RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install -y nginx

RUN rm -v /etc/nginx/nginx.conf

ADD nginx.conf /etc/nginx/

EXPOSE 80

CMD service nginx start
