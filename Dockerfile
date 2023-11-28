FROM alpine:latest

# Update apk repositories and install gpsd
RUN apk update && \
    apk add --no-cache \
    gpsd \
    && rm -rf /var/cache/apk/*

# Expose the gpsd port (2947 is the default gpsd port)
EXPOSE 2947

# Add entrypoint script (as before)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
