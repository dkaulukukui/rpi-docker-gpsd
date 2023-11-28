#!/bin/sh

# Start gpsd and forward arguments
# Replace /dev/ttyUSB0 with your GPS device path
exec gpsd -N -D3 -F /var/run/gpsd.sock /dev/ttyUSB0 "$@"
