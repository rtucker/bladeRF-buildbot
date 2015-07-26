# VERSION 0.0.4

FROM ubuntu
MAINTAINER Ryan Tucker <docker@ryantucker.us>
RUN sed -i -e "s|archive.ubuntu.com|mirrors.linode.com|g" /etc/apt/sources.list
RUN apt-get update
RUN apt-get dist-upgrade -y

RUN apt-get install -y nginx

VOLUME ["/var/log/nginx"]

ADD nginx.conf /etc/nginx/

EXPOSE 80

CMD service nginx start
