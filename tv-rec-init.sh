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
source av-hd-usb-utils.sh
source ER130-utils.sh

fixAvermediaDisk()
{
	switchUSB2Rasp
	sleep 5

	/bin/mount /mnt/avermedia
	sleep 10

	# try to access avermedia disk to fix it
	ls /mnt/avermedia

	/bin/umount /mnt/avermedia
	sleep 5

	switchUSB2AverMedia
	sleep 15
}

# make sure the gpio pin of MOSFET be enabled
# pin 17 : second level power/ground pin control, be controlled by a MOSFET
# echo "Enable MOSFET for scond-level power"
# gpioset gpiochip0 17=1
# sleep 1

# Set baud rate of Arduino
echo "Set baud rate of Arduino"
setBaudRate
sleep 3

fixAvermediaDisk

# turn on ER130 by sending power IR code
echo "Turn on ER130"
AverMediaPower

# run the fix routing on ER130 side
echo "Run the Fix routing on E130"
AverMediaFixDisk

echo "mount tvrec"
mount /mnt/tvrec

echo "restart nfs-erver"
/usr/bin/systemctl restart nfs-server
