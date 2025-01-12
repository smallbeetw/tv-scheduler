#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh

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
        echo "Constantly Green Bright"
    else
        echo "NOT Constantly Green Bright"
    fi
}

# ledTwinkling

# ledBreathing

ledSampling

ledConstantlyGreenBright
