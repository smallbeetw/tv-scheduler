#!/bin/bash

source tv-scheduler.conf
source tv-rec-post-utils.sh

escapeKBROcv()
{
	# Escape the KBRO box's CV
	echo -e "b" > $AVERMEDIA_TTY
	sleep 1s
	echo -e "b" > $AVERMEDIA_TTY
	sleep 1s
	echo -e "b" > $AVERMEDIA_TTY
	sleep 1s
	echo -e "b" > $AVERMEDIA_TTY
	sleep 10s
}
