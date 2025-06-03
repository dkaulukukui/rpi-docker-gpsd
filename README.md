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

The command to bring up both containers is:

```bash 
sudo docker compose up 
```

## Verficition steps

1. Ensure that the container starts up successfully
2. Check GPSD container

```bash 
sudo docker exec -it gpsd bash

chronyc sources

chronyc tracking
```

4. Check Chrony container

```bash 
sudo docker exec -it gpsd sh

chronyc sources

chronyc tracking
```

6. Verify System time

```bash 
date
```


## Resources: 


Main tutorial:  [Revisiting Microsecond Accurate NTP for Raspberry Pi with GPS PPS in 2025 - Austin's Nerdy Things](https://austinsnerdythings.com/2025/02/14/revisiting-microsecond-accurate-ntp-for-raspberry-pi-with-gps-pps-in-2025/) <br>
Repo:  [dkaulukukui/docker_gpsd_alpine](https://github.com/dkaulukukui/docker_gpsd_alpine) <br>
GPSD references:  [GPSD Time Service HOWTO](https://gpsd.gitlab.io/gpsd/gpsd-time-service-howto.html) <br>
PPS tools resources: https://github.com/redlab-i/pps-tools?tab=readme-ov-file <br>
Chrony resource: https://chrony-project.org/ <br>
	
			

## Next steps

- investigate further the GPSD warnings about KPPS and PPS and determine what needs to be done to fix
- fork repo to use another version of linux (debian based) which may have more default functionality to see if that will fix issues

## To do once issues are resolved: 
- setup chrony configuration file properly
- implement startup.sh to launch gpsd and chrony when container is brought up
- dial back docker --privlidged flag and make sure everything still works
- setup alpine chrony only container for remote NTP side

