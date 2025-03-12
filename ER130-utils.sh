#!/bin/bash

# Copyright (C) 2025 Smallbee.TW <smallbee.tw@gmail.com>
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
#   All values are almost the same.
#   Only allow tolerance = 1
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
#     LED samples: 4 0 3 2 0 0 0 0 1 3
#     LED samples: 0 0 0 0 2 3 0 0 0 0
#   The lowest value is 0 or 1
#   Difference between highest and lowest values >= 3
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
    if [[ $lowest -le 1 ]] && [[ $difference -ge 3 ]]; then
	GREENFLASHING=true
	printLog "Green Flashing"
    fi
}

# Patterns of sampling:
#   Constantly Amber Bright:
#     LED samples: 5 7 6 6 5 5 5 4 5 4
#     LED samples: 5 4 8 7 7 6 6 5 5 4
#     LED samples: 6 5 5 7 6 5 6 7 5 4
#     LED samples: 6 6 6 9 7 5 4 4 7 8
#     LED samples: 5 4 7 8 6 5 6 6 6 6
#   There are four or five consecutive numbers
#   No 0 or 1 value
#   Return: CONSTANTAMBER=true
ledConstantlyAmberBright()
{
    IFS=$'\n' sorted=($(sort <<<"${samples[*]}"))
    unset IFS

    CONSTANTAMBER=false
    consecutive=1
    for ((index=0; index < ${#sorted[@]}; index++)); do
	# If 0 or 1 be found, then it's NOT a sample of constantly amber
	if [ ${sorted[index]} -le 1 ]; then
	    break
	fi
	# if (i+1) - i = 1, then they are consecutive
	if [ $(($index+1)) -lt ${#sorted[@]} ]; then
	    if [ ${sorted[index+1]} -gt ${sorted[index]} ]; then
		difference=`expr ${sorted[index+1]} - ${sorted[index]}`
		if [ $difference -eq 1 ]; then
		    consecutive=$(($consecutive+1))
		fi
	    fi
	fi
    done
    # consecutive >= 4 means the samples have 4 consecutive numbers at least
    if [ $consecutive -ge 4 ]; then
	CONSTANTAMBER=true
	printLog "Constantly Amber"
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
