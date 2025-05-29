#!/bin/sh

# Start gpsd and forward arguments
# Replace /dev/ttyUSB0 with your GPS device path

#exec sh -c "echo 'Inside Container:' && echo 'User: $(whoami) UID: $(id -u) GID: $(id -g)'"

# Start GPSD service
# -G means to listen on all addresses rather than just the loopback
# -N means to dont deamonize and run in the foreground
# -n means to not wait for a client to connect before polling GPS
# -D3 means to set the debug level to 3
# -F means to create a control socket for device addition and removal commands
# -s sets a fixed port speed for the GNSS device, default is autobaud
# /dev/ttyAMA0 is the serial port of the Local GNSS device
# /dev/pps0 is the Local PPS device

#exec sudo gpsd -GNn -D3 -F /var/run/gpsd.sock -s 38400 /dev/ttyAMA0 /dev/pps0 "$@"
exec sudo gpsd -GNn -D1 -F /var/run/gpsd.sock -s 38400 /dev/ttyAMA0 /dev/pps0 "$@"
