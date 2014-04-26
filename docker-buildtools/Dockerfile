# Imports the build tools from the local machine into Docker

# BUILD USING: docker build -t bladerf-buildtool-importer .
# RUN USING:   docker run -v /opt:/mnt:ro --name BLADERF-BUILDTOOLS bladerf-buildtool-importer
# USE LIKE:    docker run -t -i --rm --volumes-from BLADERF-BUILDTOOLS ubuntu bash

FROM busybox
MAINTAINER Ryan Tucker <rtucker@gmail.com>

VOLUME ["/opt/altera", "/opt/cypress", "/opt/coverity"]

CMD ["cp", "-a", "/mnt/altera", "/mnt/cypress", "/mnt/coverity", "/opt"]
