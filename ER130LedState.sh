#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh

sampling()
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


ledConstantlyBright()
{
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
	TVSCH_FILE=$TVSCH_FILE"B"
        echo "Constantly Bright"
    else
        echo "NOT Constantly Bright"
    fi
}

# ledTwinkling

# ledBreathing

sampling

ledConstantlyBright
