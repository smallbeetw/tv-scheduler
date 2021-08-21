#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh

matchMP4()
{
	MIN_DEVINATION=300	
	# find out the mp4 file that matches with target tvsch
	# AverMedia's mp4 file format: 201012-1805.mp4
	mp4s=`ls $AVER_PATH/*.mp4`
	for mp4 in $mp4s
	do
		BASENAME=$(basename $mp4)
		filename=$(echo "$BASENAME" | cut -f 1 -d '.')
		IFS='-' read -a array <<< $filename
		START_TIME=${array[0]}" "${array[1]}
		START_EPOCH=$(date -d "$START_TIME" +%s)
		DEVIATION=$((${START_EPOCH}-${TARGET_EPOCH}))
		DEVIATION=${DEVIATION#-}
		if [ $DEVIATION -le $MIN_DEVINATION ]; then
			MIN_DEVINATION=$DEVIATION
			MATCH_MP4_NAME=$filename	
			MATCH_MP4_FILENAME=$mp4
		fi
	done
	echo "MATCH_MP4_NAME: " $MATCH_MP4_NAME
	echo "MATCH_MP4_FILENAME: " $MATCH_MP4_FILENAME
}

copy()
{
	# .tvsch state: [F]inal -> [C]opy -> [D]one
	# change .tvschF to .tvschC before match/copy. [C] means Copy. 
	TARGET_TVSCHC=${TARGET_TVSCHF/.tvschF/.tvschC} 
	mv $TARGET_TVSCHF $TARGET_TVSCHC 

	# run the next program if we did not find match mp4 file by time
	if [ -z "$MATCH_MP4_FILENAME" ]; then
		return 0
	fi
 
	PG_TYPE="Movies"
	if [[ $TARGET_NAME == *"[D]"* ]]; then
	  PG_TYPE="Series"
	fi 
	DEST_FOLDER=$TVREC_PATH/$PG_TYPE/$TARGET_NAME
	DEST_FILE=$DEST_FOLDER/$MATCH_MP4_NAME"_"$TARGET_NAME.mp4
	echo $DEST_FOLDER
	echo $DEST_FILE
	# create program folder
	mkdir -p $DEST_FOLDER
	# copy mp4 to destination file
	cp $MATCH_MP4_FILENAME $DEST_FILE
	sync
	# change owner to nobody:nobody for the delete function of Kodi
	chown nobody:nobody -R $DEST_FOLDER

	# TODO: check sum and remove/keep target

	# change .tvschC to .tvschD. [D] means Done. 
	mv $TARGET_TVSCHC ${TARGET_TVSCHC/.tvschC/.tvschD} 
}

# Find out the copy target (shortest non-copy program)
findTarget

checkSlot

matchMP4

# copy match mp4 file to rasp
copy
	
# call self script again, until no enough slot or no any program can copy
$TVSCH_BIN_PATH/tv-rec-post-copy.sh
