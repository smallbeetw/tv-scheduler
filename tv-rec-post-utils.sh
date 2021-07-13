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
