# rpi-docker-gpsd-chrony

This Docker image facilitates the running of the Linux GPS daemon (gpsd) on a 
Raspberry Pi connected to an instance of Chrony. `gpsd` is a daemon 
that monitors one or more GPSes or AIS receivers attached to a host computer 
through serial or USB ports. `Chrony` is an NTP service.  

Together these services allow for a GPS 1PPS corrected timeserver. 

## Resources: 


Main tutorial:  [Revisiting Microsecond Accurate NTP for Raspberry Pi with GPS PPS in 2025 - Austin's Nerdy Things](https://austinsnerdythings.com/2025/02/14/revisiting-microsecond-accurate-ntp-for-raspberry-pi-with-gps-pps-in-2025/) <br>
Repo:  [dkaulukukui/rpi-docker-gpsd-chrony](https://github.com/dkaulukukui/rpi-docker-gpsd-chrony) <br>
GPSD references:  [GPSD Time Service HOWTO](https://gpsd.gitlab.io/gpsd/gpsd-time-service-howto.html) <br>
PPS tools resources: https://github.com/redlab-i/pps-tools?tab=readme-ov-file <br>
Chrony resource: https://chrony-project.org/ <br>


## Prerequisites

- Raspberry Pi with Docker installed.
- timing specific GPS module
- 5 wires needed – +VDC/RX/TX/GND/PPS

## Setup and Configuration Steps

### 1. Copy github project 

```bash
git clone https://github.com/dkaulukukui/rpi-docker-gpsd-chrony
```


### 2. Build Image

```bash
cd rpi-docker-gpsd
sudo docker build -t rpi-gpsd .
```

### 3. Setup Raspi GPIO
1. Enable the PPS dignal on Pin 18. In /boot/firmware/config.txt add the below to a new line.

    ```bash
    sudo bash -c "echo '# GPS PPS signals Information' >> /boot/firmware/config.txt"
    sudo bash -c "echo 'dtoverlay=pps-gpio,gpiopin=18' >> /boot/firmware/config.txt"
    ``` 

2. Enable UART and set the initial baud rate. Note: Set baud rate for the specific GPS unit you have, if avaialble use the highest most frequently updated GPS output settings.  GPSD can parse most common GPS receiver outputs automatically and for the most part anything is better than the default 9600 NMEA.

    ```bash
    sudo bash -c "echo 'enable_uart=1' >> /boot/firmware/config.txt"
    sudo bash -c "echo 'init_uart_baud=9600' >> /boot/firmware/config.txt"
    ```

3. In /etc/modules, add ‘pps-gpio’ to a new line.

    ```bash 
    sudo bash -c "echo 'pps-gpio' >> /etc/modules"
    ```

4. Reboot

    ```bash
    sudo reboot
    ```

### 4. Wire up the GPS module

Determine the voltage requirements of your GPS module first. 

Pin connections:

1. GPS PPS to RPi GPIO pin 12 (GPIO 18)
2. GPS VIN to RPi 5V pin 2 or 4 (or for 3.3V pin 1 or 17)
3. GPS GND to RPi GND pin 6,9,14,20,25,30,34 or 39
4. GPS RX to RPi UART TX pin 8 (GPIO14)
5. GPS TX to RPi UART RX pin 10 (GPIO15)

### 5. Enable the serial hardware port

Run raspi-config -> 3 – Interface options -> I6 – Serial Port -> Would you like a login shell to be available over serial -> No. -> Would you like the serial port hardware to be enabled -> Yes.

## Bring up the container

The command to bring up both containers (attached to the stdio terminal, useful for debugging) is:

```bash 
sudo docker compose up 
```

The command to bring up both containers in the background is:

```bash 
sudo docker compose up --detach
```

## Verficition steps

1. Ensure that the container starts up successfully

    Monitor docker console logs for any error messages.  Successful container start up should look similar to the below: 

<Insert Image of Console output showing successful container startup>


2. Check GPSD 

    - Attach container terminal 

        ```sudo docker exec -it gpsd bash```

    - Verify PPS signal.

        ```sudo ppstest /dev/pps0 ```

        - Successful PPS connectivity should look like the below

            ```bash
            trying PPS source "/dev/pps0"
            found PPS source "/dev/pps0"
            ok, found 1 source(s), now start fetching data...
            source 0 - assert 1739485509.000083980, sequence: 100 - clear  0.000000000, sequence: 0
            source 0 - assert 1739485510.000083988, sequence: 101 - clear  0.000000000, sequence: 0
            source 0 - assert 1739485511.000083348, sequence: 102 - clear  0.000000000, sequence: 0
            source 0 - assert 1739485512.000086343, sequence: 103 - clear  0.000000000, sequence: 0
            source 0 - assert 1739485513.000086577, sequence: 104 - clear  0.000000000, sequence: 0
            ^C
            ```

    - Verify GPS data

        ```gpsmon```

3. Check Chrony

    - Verify Chrony is seeing both the GPS and 1 PPS signals as valid and is using 1 PPS

        ```chronyc sources```

        <Insert image showing the output of chronyc sources>

    - Verify that chrony is tracking and updating the system clock

        ```chronyc tracking```

4. Verify System time

    ```date```
			
## To do: 
- setup chrony configuration file properly
- dial back docker --privlidged flag and make sure everything still works
- develop offset calculation and verification procedure to determine and quantify system timing accuracy

