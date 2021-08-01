#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh

tvsch=$1

matchAtqJob()
{
	BASENAME=$(basename $tvsch)
	filename=$(echo "$BASENAME" | cut -f 1 -d '.')
	IFS='_' read -a array <<< $filename
	START_TIME=${array[0]}"_"${array[1]}
#	START_EPOCH=$(date -d "$START_TIME" +%s)
#	DEVIATION=$((${START_EPOCH}-${TARGET_EPOCH}))
#	DEVIATION=${DEVIATION#-}
#	if [ $DEVIATION -le $MIN_DEVINATION ]; then
##		MIN_DEVINATION=$DEVIATION
#		MATCH_MP4_NAME=$filename	
#		MATCH_MP4_FILENAME=$mp4
#	fi
#	echo "MATCH_MP4_NAME: " $MATCH_MP4_NAME
#	echo "MATCH_MP4_FILENAME: " $MATCH_MP4_FILENAME
	echo "BASENAME: " $BASENAME
	echo "START_TIME: " $START_TIME
	# TODO: support multi atq job in the same time
	JOB=$(atq -o '%Y-%m-%d_%H:%M' | grep "$START_TIME")
	echo "job: " $JOB
	if [ -z "$JOB" ]; then
		exit 0
	fi
	IFS=$'\t' read -a array <<< $JOB
	JOB_NUMBER=${array[0]}
	echo "Job Number: " $JOB_NUMBER
	# confirm that the tvsch file name is in the job 
	TVSCH_IN_JOB=$(at -c $JOB_NUMBER | grep $tvsch)
	echo "TVSCH_IN_JOB: " $TVSCH_IN_JOB
	if [ ! -z "$TVSCH_IN_JOB" ]; then
		atrm $JOB_NUMBER
		echo "Removed matched atq job: " $JOB
		rm $tvsch
		echo "Removed tvsch: " $tvsch
	fi
}

matchAtqJob
