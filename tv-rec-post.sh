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
	sleep 10s
}

AverMediaFixDisk()
{
	# Sometimes that Avermedia E130 requests user to push _OK_ button
	# to fix disk because it found broken file on disk. So we push
	# OK button a couple of times to trigger the fixing after E130 be
	# powered on.
	echo -e "O" > $AVERMEDIA_TTY
	sleep 15s
	echo -e "O" > $AVERMEDIA_TTY
	sleep 15s
	echo -e "O" > $AVERMEDIA_TTY
	sleep 5s
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
	gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 17=1; sleep 1; gpioset gpiochip0 3=0
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

AverMediaFixDisk

# restart nfs-server because USB EMI
/usr/bin/systemctl restart nfs-server

# TODO: remove tvsch file?
