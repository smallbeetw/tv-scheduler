#!/bin/bash

source tv-scheduler.conf

DATE=$1
TIME=$2
MINUTESm=$3
CHANNEL=$4
NAME=$5

# check if this tvsch be marked as [B]lock
TVSCHB_FILENAME=$TVSCH_PATH/$DATE"_"$TIME"_"$MINUTESm"_"$CHANNEL"_"$NAME"[D]".tvschB
if [ -f $TVSCHB_FILENAME ]; then
	# we still schedule next cycle, but return error
	echo $TVSCHB_FILENAME "be blocked."
	$TVSCH_BIN_PATH/tv-sch-D.sh $TIME $MINUTESm $CHANNEL $NAME
	exit 1
fi
