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
	echo "Constantly Green Bright"
    else
        printLog "NOT Constantly Green Bright"
        echo "NOT Constantly Green Bright"
    fi
}

# Patterns of sampling:
#   Green Flashes:
#     LED samples: 4 4 4 4 4 4 4 5 0 0
#     LED samples: 0 0 0 4 0 0 0 0 0 2
#     LED samples: 6 0 0 0 0 0 6 0 0 0
#     LED samples: 5 5 0 5 5 1 5 5 0 5
#   The lowest value is 0 or 1
#   Difference between highest and lowest values >= 4
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
	echo "Green Flashing"
    else
	printLog "Not Green Flashing"
	echo "Not Green Flashing"
    fi
    echo "lowest "$lowest
    echo "difference "$difference
}

# Patterns of sampling:
#   Constantly Amber Bright:
#     LED samples: 5 7 6 6 5 5 5 4 5 4
#     LED samples: 5 4 8 7 7 6 6 5 5 4
#     LED samples: 6 5 5 7 6 5 6 7 5 4
#     LED samples: 6 6 6 9 7 5 4 4 7 8
#     LED samples: 5 4 7 8 6 5 6 6 6 6
#     LED samples: 7 4 7 7 6 5 4 4 5 7
#     LED samples: 4 4 4 7 7 5 5 4 4 4
#   There are three or more consecutive numbers
#   No 0 or 1 value
ledConstantlyAmberBright()
{
    IFS=$'\n' sorted=($(sort <<<"${samples[*]}"))
    unset IFS

    echo "sorted samples: ${sorted[*]}"
    CONSTANTAMBER=false
    consecutive=1
    for ((index=0; index < ${#sorted[@]}; index++)); do
	# If 0 or 1 be found, then it's NOT a sample of constantly amber
	if [ ${sorted[index]} -le 1 ]; then
	    break
	fi
	# if (i+1) - i = 1 or 2, then they are consecutive
	if [ $(($index+1)) -lt ${#sorted[@]} ]; then
	    if [ ${sorted[index+1]} -gt ${sorted[index]} ]; then
		difference=`expr ${sorted[index+1]} - ${sorted[index]}`
		if [[ $difference -gt 0 ]] && [[ $difference -le 2 ]]; then
		    consecutive=$(($consecutive+1))
		fi
	    fi
	fi
    done
    # consecutive >= 3 means the samples have 4 consecutive numbers at least
    if [ $consecutive -ge 3 ]; then
	CONSTANTAMBER=true
	printLog "Constantly Amber"
	echo "Constantly Amber"
    else
	printLog "Not Contantly Amber"
	echo "Not Contantly Amber"
    fi
    echo "consecutive: "$consecutive
}

# ledTwinkling

# ledBreathing

# ledSampling

# Constantly Green Bright:
#samples=(4 4 4 4 4 4 4 4 4 4)
#samples=(5 4 4 4 4 4 4 4 4 4)

# Green Flashes:
#samples=(4 4 4 4 4 4 4 5 0 0)
#samples=(0 0 0 4 0 0 0 0 0 2)
#samples=(6 0 0 0 0 0 6 0 0 0)
#samples=(5 5 0 5 5 1 5 5 0 5)

# Constantly Amber Bright:
#samples=(5 7 6 6 5 5 5 4 5 4)
#samples=(5 4 8 7 7 6 6 5 5 4)
#samples=(6 5 5 7 6 5 6 7 5 4)
#samples=(6 6 6 9 7 5 4 4 7 8)
#samples=(5 4 7 8 6 5 6 6 6 6)
#samples=(7 4 7 7 6 5 4 4 5 7)
samples=(4 4 4 7 7 5 5 4 4 4)

ledConstantlyGreenBright

ledGreenFlashing

ledConstantlyAmberBright
