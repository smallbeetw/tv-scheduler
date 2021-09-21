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
 
	PG_TYPE="Series"
	if [[ $TARGET_NAME == *"[M]"* ]]; then
	  PG_TYPE="Movies"
	fi
	# remove all tags in folder name
	DEST_FOLDER=${TARGET_NAME/\[*\]/}
	DEST_FOLDER=$TVREC_PATH/$PG_TYPE/$DEST_FOLDER
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

	# change .tvschC to .tvschD. [D] means Done. 
	mv $TARGET_TVSCHC ${TARGET_TVSCHC/.tvschC/.tvschD} 
}

delMatchMP4()
{
	SIZE_SOURCE_MP4=$(stat -c%s $MATCH_MP4_FILENAME)
	SIZE_DEST_FILE=$(stat -c%s $DEST_FILE)
	# use ffprobe check the format of DEST_FILE
	if command -v ffprobe &> /dev/null; then
		FFPROBE_ERR=$(ffprobe -v error $DEST_FILE 2>&1)
		if [ ! -z "$FFPROBE_ERR" ]; then
			echo "FFPROBE_ERR: " $FFPROBE_ERR
		fi
	fi
	# if size match and also no ffprobe error, then we can remove the source mp4
	if [ $SIZE_SOURCE_MP4 -eq $SIZE_DEST_FILE ] && [ -z "$FFPROBE_ERR" ]; then
		rm $MATCH_MP4_FILENAME
		sync
		echo "Removed source MP4 file: " $MATCH_MP4_FILENAME
	fi
}

parseKeepTag()
{
	D_BASENAME=$1
	# take the number in [D??], the number between "[D" with "]"
	if [[ $D_BASENAME == *"[D"* ]]; then
	  # take the substring after "[D"
	  KEEP_NUM=${D_BASENAME#*[D}
	  # take the subtring before the first "]"
	  KEEP_NUM=${KEEP_NUM%%]*}
	fi

	# If KEEP_NUM is not a number, then set it to 0 means disable
	re='^[0-9]+$'
	if ! [[ $KEEP_NUM =~ $re ]] ; then
	  echo $KEEP_NUM" is NOT a number, set to 0"
	  KEEP_NUM=0
	fi
	echo "KEEP_NUM: "$KEEP_NUM
}

delOldestMP4()
{
	# 210904-1900_中視新聞[D].mp4
	OLDEST_EPOCH=0
	mp4s=`ls $DEST_FOLDER/*.mp4`
	for mp4 in $mp4s
	do
		BASENAME=$(basename $mp4)
		IFS='_' read -a array <<< $BASENAME
		DATETIME=${array[0]/-/ }
		START_EPOCH=$(date -d "$DATETIME" +%s)
		if [ $OLDEST_EPOCH -eq 0 ] || [ $START_EPOCH -lt $OLDEST_EPOCH ]; then
		    OLDEST_EPOCH=$START_EPOCH
		    OLDEST_MP4=$mp4
		fi
	done
	if [ $OLDEST_EPOCH -ne 0 ]; then
		rm $OLDEST_MP4
		echo "removed "$OLDEST_MP4
	fi
}

delOutdatedMP4s()
{
	# parsing the [D?] tag to find out how many mp4 files we want to keep
	# in the dest folder in storage, the result will be set in KEEP_NUM
	parseKeepTag $TARGET_NAME
	REMOVE_NUM=0
	MP4_NUM=`ls $DEST_FOLDER/*.mp4 | wc -l`
	echo "MP4_NUM: "$MP4_NUM
	if [ $KEEP_NUM -gt 0 ] && [ $MP4_NUM -gt $KEEP_NUM ]; then
	    REMOVE_NUM=$((${MP4_NUM}-${KEEP_NUM}))
	fi
	echo "REMOVE_NUM: " $REMOVE_NUM
	while [ $REMOVE_NUM -gt 0 ]
	do
	    delOldestMP4
	    REMOVE_NUM=$((REMOVE_NUM-1))
	done
}

# Find out the copy target (shortest non-copy program)
findTarget

checkSlot

matchMP4

# copy match mp4 file to rasp
copy

# delete source MP4 to save space of thumb
delMatchMP4

# delete outdated mp4 files in destination folder
delOutdatedMP4s
	
# call self script again, until no enough slot or no any program can copy
$TVSCH_BIN_PATH/tv-rec-post-copy.sh
