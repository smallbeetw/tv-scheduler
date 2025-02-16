#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh

detachAVHD()
{
	# Escape last state of recorder
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	# Press MENU and F1 key to detach disk from avermedia box
	echo -e "M" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "F" > $AVERMEDIA_TTY
	sleep 10s
	echo -e "F" > $AVERMEDIA_TTY
	sleep 10s
	echo -e "F" > $AVERMEDIA_TTY
	sleep 10s
	echo -e "O" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
	echo -e "E" > $AVERMEDIA_TTY
	sleep 3s
}

ledSampling()
{
    for i in {0..9};
    do
        echo -e "?" > $AVERMEDIA_TTY
        sleep 1
        read -N1 LED_VALUE < $AVERMEDIA_TTY
        samples[i]=$LED_VALUE
    done
    printLog "LED samples: ${samples[*]}"
}

# Patterns of sampling:
#   Constantly Green Bright:
#     LED samples: 4 4 4 4 4 4 4 4 4 4
#     LED samples: 5 4 4 4 4 4 4 4 4 4
#   NOT Constantly Green Bright
#     LED samples: 4 4 4 4 4 4 4 5 0 0
#     LED samples: 0 0 0 4 0 0 0 0 0 2
#   Return: CONSTANTGREEN=true
ledConstantlyGreenBright()
{
    CONSTANTGREEN=true
    sample0=${samples[0]}
    for i in ${samples[@]};
    do
	# Let's set tolerance = 1 for sampling value
	# which means that it's NOT constant when difference > 1
	difference=`expr $sample0 - $i`
	abs=${difference#-}
	if [ $abs -gt 1 ]; then
	    CONSTANTGREEN=false
            break
        fi
    done
    if [ $CONSTANTGREEN == true ]; then
	printLog "Constantly Green Bright"
    else
        printLog "NOT Constantly Green Bright"
    fi
}

# Patterns of sampling:
#   Green Flashes:
#     LED samples: 4 4 4 4 4 4 4 5 0 0
#     LED samples: 0 0 0 4 0 0 0 0 0 2
#     LED samples: 6 0 0 0 0 0 6 0 0 0
#     LED samples: 5 5 0 5 5 1 5 5 0 5
#     LED samples: 6 1 6 1 1 1 1 1 6 1
#     LED samples: 1 1 1 1 6 1 1 1 1 1
#   The lowest value is 0 or 1
#   Difference between highest and lowest values >= 4
#   Return: GREENFLASHING=true
ledGreenFlashing()
{
    GREENFLASHING=false
    lowest=9
    highest=0
    sample0=${samples[0]}
    for i in ${samples[@]};
    do
	if [ $i -lt $lowest ]; then
		lowest=$i
	fi
	if [ $i -gt $highest ]; then
		highest=$i
	fi
    done
    difference=`expr $highest - $lowest`
    if [[ $lowest -le 1 ]] && [[ $difference -ge 4 ]]; then
	GREENFLASHING=true
	printLog "Green Flashing"
    fi
}

AverMediaPower()
{
	printLog "AverMediaPower"
	# power off (standby) or power on AverMedia
	echo -e "P" > $AVERMEDIA_TTY
	sleep 35s
}

AverMediaFixDisk()
{
	# Sometimes that Avermedia E130 requests user to push _OK_ button
	# to fix disk because it found broken file on disk. So we push
	# OK button a couple of times to trigger the fixing after E130 be
	# powered on.
	echo -e "O" > $AVERMEDIA_TTY
	sleep 15s
	echo -e "O" > $AVERMEDIA_TTY
	sleep 15s
	echo -e "O" > $AVERMEDIA_TTY
	sleep 5s
}
