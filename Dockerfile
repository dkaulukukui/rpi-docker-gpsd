FROM alpine:3.22
# working as of 2025-06-03 on Alpine version 3.22.0
# not working on Alpine version 3.21.3

# Print the UID and GID
# CMD sh -c "echo 'Inside Container:' && echo 'User: $(whoami) UID: $(id -u) GID: $(id -g)'"

# install packages as root
#USER root # install packages as root

ARG BUILD_DATE

# first, a bit about this container
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.authors="Donald Kaulukukui donald.kaulukukui@arl.hawaii.edu" \
      org.opencontainers.image.documentation=https://github.com/dkaulukukui/rpi-docker-gpsd

# Update apk repositories and install gpsd
RUN apk update && \
    apk add --no-cache \
    pps-tools \
    gpsd \
    gpsd-clients \
    chrony \
    bash \
    sudo \ 
    nano \ 
    && rm -rf /var/cache/apk/*

# Expose the gpsd port (2947 is the default gpsd port)
EXPOSE 2947

# Expose the chrony ntp port
EXPOSE 123/udp

# Copy chrony config file 
COPY chrony.conf /etc/chrony/chrony.conf

# marking volumes that need to be writable
VOLUME /etc/chrony /run/chrony /var/lib/chrony

# let docker know how to test container health
HEALTHCHECK CMD chronyc -n tracking || exit 1

# Add entrypoint script (as before)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
