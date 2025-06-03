# rpi-docker-gpsd

This Docker image facilitates the running of the Linux GPS daemon (gpsd) on a 
Raspberry Pi, making it available as a network service. `gpsd` is a daemon 
that monitors one or more GPSes or AIS receivers attached to a host computer 
through serial or USB ports.


## Prerequisites

Ensure Docker is installed on your Raspberry Pi.

## Build

```bash 
 sudo docker build -t rpi-gpsd .
```


## Usage

To use `gpsd`, the GPS device's serial port needs to be mapped to the Docker 
container. This is essential for `gpsd` to communicate with the GPS device. 

The default command to run the container is:

```bash 
sudo docker run --rm -it --device=/dev/serial0 -p 2947:2947 rpi-gpsd
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


## Resources: 


Main tutorial:  [Revisiting Microsecond Accurate NTP for Raspberry Pi with GPS PPS in 2025 - Austin's Nerdy Things](https://austinsnerdythings.com/2025/02/14/revisiting-microsecond-accurate-ntp-for-raspberry-pi-with-gps-pps-in-2025/) <br>
Repo:  [dkaulukukui/docker_gpsd_alpine](https://github.com/dkaulukukui/docker_gpsd_alpine) <br>
GPSD references:  [GPSD Time Service HOWTO](https://gpsd.gitlab.io/gpsd/gpsd-time-service-howto.html) <br>
PPS tools resources: https://github.com/redlab-i/pps-tools?tab=readme-ov-file <br>
Chrony resource: https://chrony-project.org/ <br>
	

## Efforts so far: 

Followed the main tutorial above and was able to get everything working with both the Adafruit GPS featherwing and the Sparkfun Zed board <br>

Containerization efforts
- Alpine based container
- See repo - dkaulukukui/docker_gpsd_alpine
- So far I am able to run the container and verify PPS (step 4 from the main tutorial) however when I check GPS via gpsmon there is no PPS offset shown. 
- Current issues: 
	- When chrony is configured to use refclock PPS an error is kicked out saying that module is not compiled in 

   		> 2025-05-28T22:53:23Z Fatal error : refclock driver PPS is not compiled in

     	- Review of the build logs from the alpine APK chrony respository build indicates that refclock is compiled in.  This determination is based on the fact that timepps.h is found and included in the build log.
        - APK GPSD info: https://pkgs.alpinelinux.org/package/edge/main/x86/gpsd
  
	
 	- When GPSD container is started the follow warnings are displayed: 
			
		> gpsd:WARN: KPPS:/dev/ttyAMA0 no HAVE_SYS_TIMEPPS_H, PPS accuracy will suffer
  		> 	
		> gpsd:WARN: KPPS:/dev/pps0 no HAVE_SYS_TIMEPPS_H, PPS accuracy will suffer
		>
  		> gpsd:WARN: PPS:/dev/pps0 die: no TIOMCIWAIT, nor RFC2783 CANWAIT
			

## Workflow to reproduce issue on raspi: 
- From ~/NTP/rpi-docker-gpsd


```bash 
cd /NTP/rpi-docker-gpsd
```

- Build container

```bash 
sudo docker build -t rpi-gpsd ~/NTP/rpi-docker-gpsd/
```

- Run container

```bash 
sudo docker run --rm -it --device=/dev/ttyAMA0 --device=/dev/pps0 -p 2948:2947 --name gpsd --privileged rpi-gpsd
```

- Launch another terminal and run

```bash 
sudo docker exec -it gpsd bash
```

- Check PPS

```bash 
sudo ppstest /dev/pps0
```

- Check gps

```bash 
cgps
```

```bash 
gpsmon
```
- Try to launch chrony

```bash 
/usr/sbin/chronyd -u chrony -d -x -L 3
```

 - ERROR response of 	
 	> 2025-05-28T22:53:23Z Fatal error : refclock driver PPS is not compiled in!

## Next steps

- investigate further the GPSD warnings about KPPS and PPS and determine what needs to be done to fix
- fork repo to use another version of linux (debian based) which may have more default functionality to see if that will fix issues

## To do once issues are resolved: 
- setup chrony configuration file properly
- implement startup.sh to launch gpsd and chrony when container is brought up
- dial back docker --privlidged flag and make sure everything still works
- setup alpine chrony only container for remote NTP side

