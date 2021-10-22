#!/bin/bash

source tv-scheduler.conf

conflict()
{
	CONFLICT=false
	START_TIME=$DATE" "$TIME
	START_EPOCH=$(date -d "$START_TIME" +%s)
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


# x=2021-07-30_19:00_60m_10_中視新聞[P9].tvsch
# y=${x#*[P}
# z=${y%]*}
# echo $z

		if [[ $BASENAME == *"[P"* ]]; then
		  B_PRIORITY=${BASENAME#*[P}
		  B_PRIORITY=${B_PRIORITY%]*}
		fi 

		# echo $BASENAME
		# echo "B_START_TIME: "$B_START_TIME
		# echo "B_START_EPOCH:" $B_START_EPOCH
		# echo "B_END_TIME:" $B_END_TIME
		# echo "B_END_EPOCH:" $B_END_EPOCH
		# echo "B_PRIORITY: " $B_PRIORITY

		if [ $A_START_EPOCH -le $B_END_EPOCH ] && [ $B_START_EPOCH -le $A_END_EPOCH ]; then
			echo $BASENAME "conflict!!!!!!"
			CONFLICT=true
		fi
		# TODO: 將原本的 tvsch -> tvschB, [B]lock
		# Policy of Block 
		# 若 daily 還沒出現? 在 daily 走到產生下次時, 若發現已經有一個 program 在上面, 則把自己 set Block.
		# 否則把先到的的 set Blcok
		# 若 priority 相同者, 則先到先贏
		# 初次排程應該 search daily 的時間, 提醒初次排程者有 conflict.
	done

#	if [ $CONFLICT = true ]; then
#		exit 1
#	fi

	# TODO: careful between two date, last date, next date
}


