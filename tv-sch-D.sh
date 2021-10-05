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
source tv-sch-utils.sh

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

set_Dtag()
{
	if [[ $NAME != *"[D"* ]]; then
		NAME=$NAME"[D]"
	fi
}

mkdir -p $TVSCH_PATH

# TODO: check input time should not zero

# the recording time should not be a past time
past

# The recording time should not conflict with any scheduled program
# This conflict checking function call should not be move to after
# tvsch file be generated, otherwise conflict will find this program self.
conflict

# set D tag to NAME for indicate this is a daily recording
set_Dtag

TVSCH_FILE=$TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvsch

# The following logic is producing the content of tvsch file

# will checking .tvschB [B]lock tag in pre-record script
echo "$TVSCH_BIN_PATH/tv-rec-pre-D.sh $DATE $TIME $MINUTESm $CHANNEL $NAME" > $TVSCH_FILE
echo "if [ \$? -eq 1 ]; then exit 0; fi" >> $TVSCH_FILE

# generate tvsch file, request tv recording script
# The [D] after name means Daily
echo "$TVSCH_BIN_PATH/tv-rec.sh $CHANNEL $MINUTESm $NAME" >> $TVSCH_FILE

# Add flag to file extension: [F]inish, [D]elete, [B]lock
# Set flag to [F]inish after recording job is finished
echo "mv $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvsch $TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME.tvschF" >> $TVSCH_FILE

# request post recording script
echo "$TVSCH_BIN_PATH/tv-rec-post-D.sh $TIME $MINUTESm $CHANNEL $NAME" >> $TVSCH_FILE

# if this daily schedule conflicts with other TV program, then set [B]lock tag on tvsch file
if [ $CONFLICT == true ]; then
	mv $TVSCH_FILE $TVSCH_FILE"B"
	TVSCH_FILE=$TVSCH_FILE"B"
	# we still schedule blocked tvsch for next cycle
fi

# call at command to schedule the recording
at $TIME $DATE -f $TVSCH_FILE
