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

# Raspberry Pi be connected to the normal open side of Relay
# AverMedia ER130 be conntected to the normal close side of Relay
# And this is a Low level trigger Relay
switchUSB2Rasp()
{
	# Attach logic from USB: Power pin first, then Data pin
	# pin 3 : D+ D- data pin	be controlled by a low-level trigger Relay
	# pin 4 : power/ground pin	be controlled by a low-level trigger Relay
	# pin 17 : second level power/ground pin control, be controlled by a MOSFET
	 gpioset gpiochip0 17=0; sleep 1; gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 17=1; sleep 1; gpioset gpiochip0 3=0
	echo "switched USB to Raspberry pi"
}

# A MOSFET be used as the second level controller of power pin. It's to control
# the timing of enabling the power when attaching to ER130. The VBUS? power of
# thumb disk must be turn-off at least 0.5-1 second before the thumb be attached
# on ER130 or another machine. Otherwise that the thumb can not be initial by ER130
# or anyother machine. Without a second-level power control (MOSFET here), only
# one Relay can not fulfill this requirement.
switchUSB2AverMedia()
{
	# Dttach logic from USB: Data pin first, then Power pin
	# pin 3 : D+ D- data pin	be controlled by a low-level trigger Relay
	# pin 4 : power/ground pin	be controlled by a low-level trigger Relay
	# pin 17 : second level power/ground pin control, be controlled by a MOSFET
	gpioset gpiochip0 3=1; sleep 1; gpioset gpiochip0 17=0; sleep 1; gpioset gpiochip0 4=1; sleep 1; gpioset gpiochip0 17=1
	echo "switched USB to AverMedia"
}

dump()
{
	PG_TYPE="Dump"
	DEST_FOLDER=$TVREC_PATH/$PG_TYPE/
	mkdir -p $DEST_FOLDER
	# dump all mp4 files from AverMedia's thumbdrive
	# AverMedia's mp4 file format: 201012-1805.mp4
	mp4s=`ls $AVER_PATH/*.mp4`
	for mp4 in $mp4s
	do
		echo "Dumping mp4: " $mp4
		cp $mp4 $DEST_FOLDER 
		sync
		echo "Done"
		MP4_BASENAME=$(basename $mp4)
		SIZE_SOURCE_MP4=$(stat -c%s $mp4)
		SIZE_DEST_FILE=$(stat -c%s $DEST_FOLDER/$MP4_BASENAME)
		if [ $SIZE_SOURCE_MP4 -eq $SIZE_DEST_FILE ]; then
			rm $mp4
			sync
			echo "Removed source MP4 file: " $mp4
		fi
	done
	# change owner to nobody:nobody for the delete function of Kodi 
	chown nobody:nobody -R $DEST_FOLDER
	
	# TODO: check sum and remove/keep target 
}

# Find out the copy target (shortest non-copy program)
# findTarget

# checkSlot

# script user should make sure that the time slot is enough for dumping all
# mp4 files from /mnt/avermedia to /mnt/tvrec

detachAvermedia

AverMediaPower
sleep 20

switchUSB2Rasp
sleep 5

/bin/mount /mnt/avermedia
sleep 5

#$TVSCH_BIN_PATH/tv-rec-post-copy.sh
dump
sleep 5

/bin/umount /mnt/avermedia
sleep 5
# echo 1 > /sys/block/sdb/device/delete ?

switchUSB2AverMedia
sleep 10

# /bin/stty -F /dev/ttyUSB0 115200 min 100 time 2 -icrnl -imaxbel -opost -onlcr -isig -icanon -echo
setBaudRate
sleep 3

AverMediaPower

# restart nfs-server because USB EMI
# /usr/bin/systemctl restart nfs-server

# TODO: remove tvsch file?
