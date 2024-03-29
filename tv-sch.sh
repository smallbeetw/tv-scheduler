#!/bin/bash

# Copyright (C) 2020 Smallbee.TW <smallbee.tw@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along
# with this program; if not, see <http://www.gnu.org/licenses/>.

source tv-scheduler.conf

DATE=$1
TIME=$2
MINUTESm=$3
CHANNEL=$4
NAME=$5
	
START_TIME=$DATE" "$TIME
START_EPOCH=$(date -d "$START_TIME" +%s)

# TVSCH_PATH=/root/tvschs
# TVSCH_BIN_PATH=/root/tv-rec

help()
{
	echo "tv-sch.sh DATE TIME MINUTES CHANNEL NAME"
}

past()
{
	NOW_EPOCH=$(date +%s)
	if [ $START_EPOCH -lt $NOW_EPOCH ]; then
		echo "Past time!"
		exit 0
	fi
}

conflict()
{
	CONFLICT=false
	MINUTES=${MINUTESm/m/}
	A_START_EPOCH=$START_EPOCH
	A_END_TIME=$(date -d "$DATE $TIME $MINUTES minutes" +'%Y-%m-%d %H:%M')
	A_END_EPOCH=$(date -d "$A_END_TIME" +%s)

	# echo $MINUTES
	# echo "A_START_TIME:" $START_TIME
	# echo "A_START_EPOCH:" $A_START_EPOCH
	# echo "A_END_TIME:" $A_END_TIME
	# echo "A_END_EPOCH:" $A_END_EPOCH

	# compare time of tv scheduled files
	tvschfilenames=`ls $TVSCH_PATH/*.tvsch`
	for filename in $tvschfilenames
	do
		BASENAME=$(basename $filename)
		IFS='_' read -a array <<< $BASENAME
		B_MINUTES=${array[2]/m/}
		B_START_TIME=${array[0]}" "${array[1]}
		B_START_EPOCH=$(date -d "$B_START_TIME" +%s)
		B_END_TIME=$(date -d "$B_START_TIME $B_MINUTES minutes" +'%Y-%m-%d %H:%M')
		B_END_EPOCH=$(date -d "$B_END_TIME" +%s)

		# echo $BASENAME
		# echo "B_START_TIME: "$B_START_TIME
		# echo "B_START_EPOCH:" $B_START_EPOCH
		# echo "B_END_TIME:" $B_END_TIME
		# echo "B_END_EPOCH:" $B_END_EPOCH

		if [ $A_START_EPOCH -le $B_END_EPOCH ] && [ $B_START_EPOCH -le $A_END_EPOCH ]; then
			echo $BASENAME "conflict! At least need 2 mins buffer."
			CONFLICT=true
		fi
		# TODO: auto cut A start or A end 2 mins for scheduling the A program
	done

	if [ $CONFLICT = true ]; then
		exit 0
	fi

	# TODO: careful between two date, last date, next date
}

help

mkdir -p $TVSCH_PATH

# the recording time should not be a past time
past

# the recording time should not conflict with any scheduled program 
conflict

# generate tvsch file, request tv recording script
echo "$TVSCH_BIN_PATH/tv-rec.sh $CHANNEL $MINUTESm $NAME" > $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvsch

# Add flag to file extension: [F]inish, [D]one, [B]lock
# Set flag to [F]inish after recording job is finished
echo "mv $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvsch $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvschF" >> $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvsch

# request post recording script
# echo "$TVSCH_BIN_PATH/tv-rec-post.sh $NAME $MINUTESm $CHANNEL" >> $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvsch
echo "$TVSCH_BIN_PATH/tv-rec-post.sh" >> $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvsch

# Set flag to [D]one after post recording job is done. It should includes moving video file to network storage
# echo "mv $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvschF $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvschD" >> $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvsch

# call at command to schedule the recording
at $TIME $DATE -f $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvsch

#TODO error handling when at failed
