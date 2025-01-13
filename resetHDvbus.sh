#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh
source ER130-utils.sh

printLog "Reset HD power"

echo "Turn off AverMedia ER130"
AverMediaPower

# Turn off power pin 1 second for reset vbus 
echo "Turn off vbus"
gpioset gpiochip0 17=1; sleep 5

# Turn on power pin
echo "Turn on vbus"
gpioset gpiochip0 17=0; sleep 5

echo "Turn on AverMedia ER130"
AverMediaPower
