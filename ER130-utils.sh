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
        echo ${samples[$i]}
    done
}


ledConstantlyGreenBright()
{
    CONSTANTGREEN=false
    CONSTANT=true
    sample0=${samples[0]}
    for i in ${samples[@]};
    do
        if [[ "$sample0" != "$i" ]]; then
            CONSTANT=false
            break
        fi
    done
    if [ $CONSTANT == true ]; then
	CONSTANTGREEN=true
    else
        printLog "NOT Constantly Green Bright"
    fi
}

AverMediaPower()
{
	printLog "AverMediaPower"
	# power off (standby) or power on AverMedia
	echo -e "P" > $AVERMEDIA_TTY
	sleep 30s
}
