#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh
source av-hd-usb-utils.sh
source ER130-utils.sh

postRoutine()
{
	printLog "tv-rec-post: postRoutine"

	# Find out the copy target (shortest non-copy program)
	findTarget

	checkSlot

	AverMediaPower

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

	# AverMediaFixDisk

# restart nfs-server because USB EMI
# /usr/bin/systemctl restart nfs-server
}

postRoutineSecondRound()
{
	printLog "tv-rec-post: postRoutineSecondRound"

	# If we found *.tvrecC means that a program is not copied success
	# Sometimes it's driver or filesystem problem, mv it back to *.tvrecF state and try again
	tvschCs=`ls $TVSCH_PATH/*.tvschC`
	for tvschC in $tvschCs
	do
		# .tvsch state: [F]inal -> [C]opy -> [D]one/[E]rror
		# change .tvschC back to .tvschF then try again
		TVSCHF=${tvschC/.tvschC/.tvschF}
		mv $tvschC $TVSCHF
	done

	# Do copy again when *.tvschF exist
	if [ -z "$TVSCHF" ]; then
		return 0
	fi
	# Confirm that the *.tvschF file is exist, run postRoutine again
	if [ -f "$TVSCHF" ]; then
		echo "Launch the second around copy"
		postRoutine
	fi

	# If we still see *.tvschC after second round, then mv *.tvschC to [E]rror state
	tvschCs=`ls $TVSCH_PATH/*.tvschC`
	for tvschC in $tvschCs
	do
		# .tvsch state: [F]inal -> [C]opy -> [D]one/[E]rror
		# change .tvschC to to .tvschE because we already try two rounds
		TVSCHE=${tvschC/.tvschC/.tvschE}
		mv $tvschC $TVSCHE
	done
}

checkAndResetBoxState()
{
	printLog "tv-rec-post: checkAndResetBoxState"

	# check the LED state on ER130
	# Sampling the state of LED first
	ledSampling

	# If LED state is NOT constantly green bright
	# then reset AV hard drive's power and reboot
	# AVerMedia Box to try re-mount AV HD.
	ledConstantlyGreenBright
	if [ $CONSTANTGREEN == false ]; then
		# sampling again to confirm
		sleep 30s
		ledSampling
		ledConstantlyGreenBright
		if [ $CONSTANTGREEN == false ]; then
			# Turn off AverMedia ER130
			AverMediaPower
			# reset AV HD power
			resetAVHDpower
			# Turn on AverMedia ER130 for remount HD
			AverMediaPower
		fi
	fi
}

postRoutine

postRoutineSecondRound

checkAndResetBoxState

# TODO: remove tvsch file?
