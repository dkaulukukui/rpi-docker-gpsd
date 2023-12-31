# rpi-docker-gpsd

This Docker image facilitates the running of the Linux GPS daemon (gpsd) on a 
Raspberry Pi, making it available as a network service. `gpsd` is a daemon 
that monitors one or more GPSes or AIS receivers attached to a host computer 
through serial or USB ports.

**Docker image:** jfig/rpi-docker-gpsd

**Github repo:** https://github.com/jfig/rpi-docker-python-gpio


## Prerequisites

Ensure Docker is installed on your Raspberry Pi.


## Usage

To use `gpsd`, the GPS device's serial port needs to be mapped to the Docker 
container. This is essential for `gpsd` to communicate with the GPS device. 

The default command to run the container is:

```bash 
docker run --rm -it --device=/dev/ttyACM0:/dev/ttyUSB0 -p 2947:2947 gpsd
```
Here's what each parameter does:

```--rm```: Automatically remove the container when it exits. <br />
```-it```: Interactive mode; allows you to interact with the container.<br />
```--device=/dev/ttyACM0:/dev/ttyUSB0```: Maps the GPS device from the host 
    (Raspberry Pi) to the container.<br />
```-p 2947:2947```: Exposes the gpsd port, allowing network access to the service.

### Example docker/compose file

```yaml
version: '3'

services:
  gpsd:
    image: jfig/rpi-docker-gpsd
    devices:
      - "/dev/ttyACM0:/dev/ttyUSB0
    ports:
      - "2947:2947"
    restart: always

  gps-consumer:
    image: your-gps-consumer-image  # Replace with your actual GPS consumer Docker image
    depends_on:
      - gpsd
    environment:
      GPSD_HOST: gpsd
      GPSD_PORT: 2947
    restart: always
```