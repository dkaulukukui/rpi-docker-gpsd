#Chrony offset calibration procedure


## 1. Let system run for a while

## 2. Grab Chrony Statistics file

Run the below to grab the last 100 lines of the statistics log file

```bash
sudo tail -n 100 /var/lib/docker/volumes/rpi_gpsd_chrony_chrony_logs/_data/statistics.log > chrony_statistics.log

```

## 3. Download the statistics file to machine to be used for processing

## 4. Run the chrony_statistics_analyzer.py script

```bash
python chrony_statistics_analyzer.py
```

## 5. Input the offset parameter into chrony.conf 

Bring the container down

```bash
sudo docker compose down
```

Edit the [chrony.conf](../chrony_config/chrony.conf) file line 22, replace the X.XXX with the offset in seconds.

```bash
refclock SHM 0 refid GPS offset X.XXX precision 1e-3 poll 0 filter 3
```





