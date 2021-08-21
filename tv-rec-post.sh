#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh

AVERMEDIA_TTY=/dev/ttyUSB0

detachAvermedia()
{
	# Escape last state of recorder
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	# Press MENU and F1 key to detach disk from avermedia box
	echo -e "M" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "F" > $AVERMEDIA_TTY
	sleep 10s
	echo -e "F" > $AVERMEDIA_TTY
	sleep 10s
	echo -e "F" > $AVERMEDIA_TTY
	sleep 10s
	echo -e "O" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
}

AverMediaPower()
{
	# power off (standby) AverMedia
	echo -e "P" > $AVERMEDIA_TTY
}

switchUSB2Rasp()
{
	# low gpio to enable power of relay
	gpioset gpiochip0 14=0 15=0
	sleep 1
	# low gpio to detach USB pins of AverMedia
	gpioset gpiochip0 2=0 3=0 4=0 5=0
}

switchUSB2AverMedia()
{
	# high gpio to detach USB pins of Raspberry Pi
	gpioset gpiochip0 2=1 3=1 4=1 5=1
	sleep 1
	# high gpio to disable power of relay
	gpioset gpiochip0 14=1 15=1
}

# Find out the copy target (shortest non-copy program)
findTarget

checkSlot

detachAvermedia

switchUSB2Rasp
sleep 5

AverMediaPower
sleep 5

/bin/mount /mnt/avermedia
sleep 5

$TVSCH_BIN_PATH/tv-rec-post-copy.sh
sleep 5

/bin/umount /mnt/avermedia
sleep 5

switchUSB2AverMedia
sleep 10

# /bin/stty -F /dev/ttyUSB0 115200 min 100 time 2 -icrnl -imaxbel -opost -onlcr -isig -icanon -echo
setBaudRate
sleep 3

AverMediaPower

# restart nfs-server because USB EMI
/usr/bin/systemctl restart nfs-server

# TODO: remove tvsch file?
