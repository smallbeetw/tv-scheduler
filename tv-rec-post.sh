#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh

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

# Find out the copy target (shortest non-copy program)
findTarget

checkSlot

AverMediaPower
sleep 20

switchUSB2Rasp
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
sleep 10

AverMediaFixDisk

# restart nfs-server because USB EMI
# /usr/bin/systemctl restart nfs-server

# TODO: remove tvsch file?
