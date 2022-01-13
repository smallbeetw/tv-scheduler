#!/bin/bash

source tv-scheduler.conf

findTarget()
{
	# find out the tvschF that is shortest TV program 
	# .tvschF format: 2020-05-31_01:15_170m_65_搶救雷恩大兵.tvschF
	TARGET_MINUTES=0
	tvschFs=`ls $TVSCH_PATH/*.tvschF`
	for tvschF in $tvschFs
	do
		BASENAME=$(basename $tvschF)
		IFS='_' read -a array <<< $BASENAME
		NAME=${array[4]}
		NAME=$(echo "$NAME" | cut -f 1 -d '.')
		MINUTES=${array[2]/m/}
		if [ $TARGET_MINUTES -eq 0 ] || [ $MINUTES -lt $TARGET_MINUTES ]; then
			TARGET_NAME=$NAME
			# Per testing 60 mins program needs 5 mins copy time
			# so we count hours then plus 7 mins as buffer time
			TARGET_MINUTES=$((${MINUTES} / 60 * 5 + 7))
			TARGET_TVSCHF=$tvschF
			START_TIME=${array[0]}" "${array[1]}
			TARGET_EPOCH=$(date -d "$START_TIME" +%s)
		fi
	done

	# if no tvschF, means no program then exit
	if [ $TARGET_MINUTES -eq 0 ]; then
		exit 0
	fi

	echo "TARGET_NAME: " $TARGET_NAME
	echo "TARGET_MINUTES: " $TARGET_MINUTES
	echo "TARGET_TVSCHF: " $TARGET_TVSCHF
	echo "TARGET_EPOCH: " $TARGET_EPOCH
}


checkSlot()
{
	# find out the next program and check the time slot from now 
	SLOT_EPOCH=0
	MIN_SLOT_EPOCH=0
	tvschfilenames=`ls $TVSCH_PATH/*.tvsch`
	for filename in $tvschfilenames
	do
		BASENAME=$(basename $filename)
		IFS='_' read -a array <<< $BASENAME
		START_TIME=${array[0]}" "${array[1]}
		START_EPOCH=$(date -d "$START_TIME" +%s)
		NOW_EPOCH=$(date +%s)
		# The next program is maybe recording, the start epoch just passed a bit
		# So we take the absolute value.
		SLOT_EPOCH=$((${START_EPOCH}-${NOW_EPOCH}))
		SLOT_EPOCH=${SLOT_EPOCH#-}
		if [ $MIN_SLOT_EPOCH -eq 0 ] || [ $SLOT_EPOCH -lt $MIN_SLOT_EPOCH ]; then
			MIN_SLOT_EPOCH=$SLOT_EPOCH
		fi
	done
	# if minimum slot epoch is 0, means no next program in schedule, we can just copy any thing
	# if slot minutes is smaller than target minutes, then stop copy in this time
	SLOT_MINUTES=$((${MIN_SLOT_EPOCH}/60))
	if [ ! $MIN_SLOT_EPOCH -eq 0 ] && [ $SLOT_MINUTES -lt $TARGET_MINUTES ]; then
		exit 0
	fi
	echo "SLOT_MINUTES: " $SLOT_MINUTES
}

setBaudRate()
{
	SNAME=$RANDOM 
	screen -S $SNAME -dm /dev/ttyUSB0 115200; sleep 5; screen -X -S $SNAME quit
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
	# gpioset gpiochip0 17=0; sleep 1; gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 17=1; sleep 1; gpioset gpiochip0 3=0
	# gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 4=1; sleep 1; gpioset gpiochip0 3=0

	# Attach logic from USB: Power pin first, then Data pin
	# 	Only Raspberry Pi view point because AverMedia is turn-off when switching.
	# pin 2 (pull-up): power pin		be controlled by a low-level trigger Relay 
	# 					(ON = power off = 0, OFF = power on = 1 = normal) 
	# pin 3 (pull-up): D+ D- data pins	be controlled by a low-level trigger Relay 
	# 					(ON = Raspberry Pi side = 0, OFF = Avermedia side = 1 = normal) 
	# pin 4 (pull-up): ground pin		be controlled by a low-level trigger Relay 
	# 					(ON = Raspberry Pi side = 0, OFF = Avermedia side = 1 = normal) 
	# Turn off power pin 1 second for reset vbus 
	gpioset gpiochip0 2=0; sleep 1
	# Switch ground pin to Raspberry Pi side 
	gpioset gpiochip0 4=0; sleep 1
	# Turn on power pin
	gpioset gpiochip0 2=1; sleep 1
	# Switch data pins to Raspberry Pi side 
	gpioset gpiochip0 3=0; sleep 1

	echo "switched USB to Raspberry pi"
	# one command for testing:
	# gpioset gpiochip0 2=0; sleep 1; gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 2=1; sleep 1; gpioset gpiochip0 3=0; sleep 1
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
	# gpioset gpiochip0 3=1; sleep 1; gpioset gpiochip0 17=0; sleep 1; gpioset gpiochip0 4=1; sleep 1; gpioset gpiochip0 17=1
	# gpioset gpiochip0 3=1; sleep 1; gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 4=1

	# Dttach logic from USB: Data pin first, then Power pin
	# 	Only Raspberry Pi view point because AverMedia is turn-off when switching.
	# pin 2 (pull-up): power pin		be controlled by a low-level trigger Relay
	# 					(ON = power off = 0, OFF = power on = 1 = normal) 
	# pin 3 (pull-up): D+ D- data pins	be controlled by a low-level trigger Relay
	# 					(ON = Raspberry Pi side = 0, OFF = Avermedia side = 1 = normal) 
	# pin 4 (pull-up): ground pin		be controlled by a low-level trigger Relay
	# 					(ON = Raspberry Pi side = 0, OFF = Avermedia side = 1 = normal) 
 	# Switch data pins to AverMedia side 
	gpioset gpiochip0 3=1; sleep 1
	# Turn off power pin 1 second for reset vbus
	gpioset gpiochip0 2=0; sleep 1
	# Switch ground pin to AverMedia side 
	gpioset gpiochip0 4=1; sleep 1
	# Turn on power pin
	gpioset gpiochip0 2=1; sleep 1
	
	echo "switched USB to AverMedia"
	# one command for testing:
	# gpioset gpiochip0 3=1; sleep 1; gpioset gpiochip0 2=0; sleep 1; gpioset gpiochip0 4=1; sleep 1; gpioset gpiochip0 2=1; sleep 1
}
