#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh

fixAvermediaDisk()
{
	switchUSB2Rasp
	sleep 5

	/bin/mount /mnt/avermedia
	sleep 10

	# try to access avermedia disk to fix it
	ls /mnt/avermedia

	/bin/umount /mnt/avermedia
	sleep 5

	switchUSB2AverMedia
	sleep 15
}

# make sure the gpio pin of MOSFET be enabled
# pin 17 : second level power/ground pin control, be controlled by a MOSFET
# echo "Enable MOSFET for scond-level power"
# gpioset gpiochip0 17=1
# sleep 1

# Set baud rate of Arduino
echo "Set baud rate of Arduino"
setBaudRate
sleep 3

fixAvermediaDisk

# turn on ER130 by sending power IR code
echo "Turn on ER130"
AverMediaPower
sleep 15

# run the fix routing on ER130 side
echo "Run the Fix routing on E130"
AverMediaFixDisk

echo "mount tvrec"
mount /mnt/tvrec

echo "restart nfs-erver"
/usr/bin/systemctl restart nfs-server
