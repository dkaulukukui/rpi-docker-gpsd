FROM alpine:latest

# Print the UID and GID
# CMD sh -c "echo 'Inside Container:' && echo 'User: $(whoami) UID: $(id -u) GID: $(id -g)'"

# install packages as root
#USER root # install packages as root

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
    openrc \
    && rm -rf /var/cache/apk/*

# Expose the gpsd port (2947 is the default gpsd port)
EXPOSE 2947

# Expose the chrony ntp port
EXPOSE 123

#COPY timeapps.h /sys/timeapps.h

# Copy chrony config file 
COPY chrony.conf /etc/chrony/chrony.conf

# Add entrypoint script (as before)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
