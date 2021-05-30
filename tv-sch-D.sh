#!/bin/bash

# Copyright (C) 2021 Smallbee.TW <smallbee.tw@gmail.com>
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

# use today as DATE first
DATE=$(date +'%Y-%m-%d')
TIME=$1
MINUTESm=$2
CHANNEL=$3
NAME=$4
	
START_TIME=$DATE" "$TIME
START_EPOCH=$(date -d "$START_TIME" +%s)

past()
{
	NOW_EPOCH=$(date +%s)
	if [ $START_EPOCH -lt $NOW_EPOCH ]; then
		echo "Past time!"
		# assign tomorrow to DATE
		DATE=$(date -d tomorrow +'%Y-%m-%d')	
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
		B_START_TIME=${array[0]}" "${array[1]}
		B_START_EPOCH=$(date -d "$B_START_TIME" +%s)
		B_END_TIME=$(date -d "$B_START_TIME $MINUTES minutes" +'%Y-%m-%d %H:%M')
		B_END_EPOCH=$(date -d "$B_END_TIME" +%s)

		# echo $BASENAME
		# echo "B_START_TIME: "$B_START_TIME
		# echo "B_START_EPOCH:" $B_START_EPOCH
		# echo "B_END_TIME:" $B_END_TIME
		# echo "B_END_EPOCH:" $B_END_EPOCH

		if [ $A_START_EPOCH -le $B_END_EPOCH ] && [ $B_START_EPOCH -le $A_END_EPOCH ]; then
			echo $BASENAME "conflict!!!!!!"
			CONFLICT=true
		fi
	done

	if [ $CONFLICT = true ]; then
		exit 0
	fi

	# TODO: careful between two date, last date, next date
}

# the recording time should not be a past time
past

# the recording time should not conflict with any scheduled program 
# conflict

# generate tvsch file, request tv recording script
# The [D] after name means Daily
echo "$TVSCH_BIN_PATH/tv-rec.sh $CHANNEL $MINUTESm $NAME" > $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvsch

# Add flag to file extension: [F]inish, [D]elete, [B]lock
# Set flag to [F]inish after recording job is finished
echo "mv $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvsch $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvschF" >> $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvsch

# request post recording script
echo "$TVSCH_BIN_PATH/tv-rec-post-D.sh $TIME $MINUTESm $CHANNEL $NAME" >> $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvsch

# Set flag to [D]one after post recording job is done. It should includes moving video file to network storage
echo "mv $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvschF $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvschD" >> $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvsch

# call at command to schedule the recording
at $TIME $DATE -f $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvsch
