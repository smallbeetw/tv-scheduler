#!/bin/bash

# Copyright (C) 2021 Smallbee.TW <smallbee.tw@gmail.com>
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

TIME=$1
MINUTESm=$2
CHANNEL=$3
NAME=$4

# schedule next time
$TVSCH_BIN_PATH/tv-sch-D.sh $TIME $MINUTESm $CHANNEL $NAME

$TVSCH_BIN_PATH/tv-rec-post.sh
