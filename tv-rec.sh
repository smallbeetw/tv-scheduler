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

CHANNEL=$1
MINUTES_m=$2
NAME=$3

# Set baud rate of Arduino
setBaudRate
sleep 3

# Escape the ISP's CV
echo -e "b" > /dev/ttyUSB0
sleep 1s
echo -e "b" > /dev/ttyUSB0
sleep 1s
echo -e "b" > /dev/ttyUSB0
sleep 1s
echo -e "b" > /dev/ttyUSB0
sleep 10s

# Switch channel
echo -e $CHANNEL > /dev/ttyUSB0
sleep 5s

# Escape last state of recorder
echo -e "E" > /dev/ttyUSB0
sleep 3s 
echo -e "E" > /dev/ttyUSB0
sleep 3s 
echo -e "E" > /dev/ttyUSB0
sleep 3s
echo -e "E" > /dev/ttyUSB0
sleep 3s
echo -e "E" > /dev/ttyUSB0
sleep 3s
# If it's recording, stop it
echo -e "S" > /dev/ttyUSB0
sleep 10s
echo -e "S" > /dev/ttyUSB0
sleep 10s

# Start to Record
echo -e "R" > /dev/ttyUSB0

# Wait until TV program finished
sleep $MINUTES_m

# Stop recording
echo -e "S" > /dev/ttyUSB0
sleep 20s
echo -e "S" > /dev/ttyUSB0
sleep 20s
