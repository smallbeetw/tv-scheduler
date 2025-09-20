#!/bin/bash

# Copyright (C) 2020 Smallbee.TW <smallbee.tw@gmail.com>
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
source ER130-utils.sh

CHANNEL=$1
MINUTES_m=$2
NAME=$3

printLog "        "
printLog "tv-rec: "$CHANNEL" "$MINUTES_m" "$NAME

# Set baud rate of Arduino
setBaudRate
sleep 3

# check LED state before recording start
ledSampling
ledConstantlyGreenBright
if [ "$CONSTANTGREEN" = false ]; then
	printLog "tv-rec: try to reset recorder state"
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
	# Maybe it's still in recording, stop it
	echo -e "S" > $AVERMEDIA_TTY
	sleep 10s
	echo -e "S" > $AVERMEDIA_TTY
	sleep 10s
fi

# Escape the ISP's CV
# escapeKBROcv

# Switch channel
echo -e $CHANNEL > $AVERMEDIA_TTY
sleep 10s

# Turn on/off PX RC-8000 box to workaround no-sound issue
echo -e "p" > $AVERMEDIA_TTY
sleep 5s
echo -e "p" > $AVERMEDIA_TTY
sleep 15s

# Start to Record
echo -e "R" > $AVERMEDIA_TTY
sleep 5s
# check the LED state on ER130
ledSampling
# If LED state is still in constantly green bright,
# which means that the recording is NOT started.
# Let's sending 'R'ecording IR code again
ledConstantlyGreenBright
if [ "$CONSTANTGREEN" = true ]; then
	# sending Record code again
	echo -e "R" > $AVERMEDIA_TTY
	printLog "tv-rec: resend R code"
	sleep 5s
	# smapling LED state again
	ledSampling
	ledConstantlyGreenBright
fi
if [ "$CONSTANTGREEN" = false ]; then
	printLog "tv-rec: Recording started"
else
	printLog "tv-rec: start recording failed"
fi

# Wait until TV program finished
sleep $MINUTES_m

# Stop recording
echo -e "S" > $AVERMEDIA_TTY
sleep 20s
echo -e "S" > $AVERMEDIA_TTY
sleep 10s
