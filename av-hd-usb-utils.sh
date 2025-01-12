#!/bin/bash

source tv-scheduler.conf

# Raspberry Pi GPIO pin default states:
#
# gpio    boot default    We used
# --------------------------------
# 2       high    3.3v
# 3       high    3.3v
# 4       low     0v?
# Ground
# 17      low     0v?	Power pin
# 27      low     0v?	Data pin
# 22      low     0v?	Ground pin

# Raspberry Pi be connected to the normal open side of Relay
# AverMedia ER130 be conntected to the normal close side of Relay
# And this is a Low level trigger Relay
switchUSB2Rasp()
{
	# Attach logic from USB: Power pin first, then Data pin
	# pin 27 : D+ D- data pin	be controlled by a low-level trigger Relay
	# pin 17 : power/ground pin	be controlled by a low-level trigger Relay
	# pin 17 : second level power/ground pin control, be controlled by a MOSFET (Deprecated)
	# gpioset gpiochip0 17=0; sleep 1; gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 17=1; sleep 1; gpioset gpiochip0 3=0
	# gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 4=1; sleep 1; gpioset gpiochip0 3=0

	# Attach logic from USB: Power pin first, then Data pin
	# 	Only Raspberry Pi view point because AverMedia is turn-off when switching.
	# pin 17 (pull-up): power pin		be controlled by a low-level trigger Relay
	# 					(ON = power off = 0, OFF = power on = 1 = normal) 
	# pin 27 (pull-up): D+ D- data pins	be controlled by a low-level trigger Relay
	# 					(ON = Raspberry Pi side = 0, OFF = Avermedia side = 1 = normal) 
	# pin 22 (pull-up): ground pin		be controlled by a low-level trigger Relay
	# 					(ON = Raspberry Pi side = 0, OFF = Avermedia side = 1 = normal) 
	# Turn off power pin 1 second for reset vbus 
	gpioset gpiochip0 17=1; sleep 1
	# Switch ground pin to Raspberry Pi side 
	gpioset gpiochip0 22=1; sleep 1
	# Turn on power pin
	gpioset gpiochip0 17=0; sleep 1
	# Switch data pins to Raspberry Pi side 
	gpioset gpiochip0 27=1; sleep 1

	echo "switched USB to Raspberry pi"
	# one command for testing:
	# gpioset gpiochip0 2=0; sleep 1; gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 2=1; sleep 1; gpioset gpiochip0 3=0; sleep 1
}

# A MOSFET be used as the second level controller of power pin. It's to control
# the timing of enabling the power when attaching to ER130. The VBUS? power of
# thumb disk must be turn-off at least 0.5-1 second before the thumb be attached
# on ER130 or another machine. Otherwise that the thumb can not be initial by ER130
# or anyother machine. Without a second-level power control (MOSFET here), only
# one Relay can not fulfill this requirement.
switchUSB2AverMedia()
{
	# Dttach logic from USB: Data pin first, then Power pin
	# pin 27 : D+ D- data pin	be controlled by a low-level trigger Relay
	# pin 17 : power/ground pin	be controlled by a low-level trigger Relay
	# pin 17 : second level power/ground pin control, be controlled by a MOSFET (Deprecated)
	# gpioset gpiochip0 3=1; sleep 1; gpioset gpiochip0 17=0; sleep 1; gpioset gpiochip0 4=1; sleep 1; gpioset gpiochip0 17=1
	# gpioset gpiochip0 3=1; sleep 1; gpioset gpiochip0 4=0; sleep 1; gpioset gpiochip0 4=1

	# Dttach logic from USB: Data pin first, then Power pin
	# 	Only Raspberry Pi view point because AverMedia is turn-off when switching.
	# pin 17 (pull-up): power pin		be controlled by a low-level trigger Relay
	# 					(ON = power off = 0, OFF = power on = 1 = normal) 
	# pin 27 (pull-up): D+ D- data pins	be controlled by a low-level trigger Relay
	# 					(ON = Raspberry Pi side = 0, OFF = Avermedia side = 1 = normal) 
	# pin 22 (pull-up): ground pin		be controlled by a low-level trigger Relay
	# 					(ON = Raspberry Pi side = 0, OFF = Avermedia side = 1 = normal) 
 	# Switch data pins to AverMedia side 
	gpioset gpiochip0 27=0; sleep 1
	# Turn off power pin 1 second for reset vbus
	gpioset gpiochip0 17=1; sleep 1
	# Switch ground pin to AverMedia side 
	gpioset gpiochip0 22=0; sleep 1
	# Turn on power pin
	gpioset gpiochip0 17=0; sleep 1
	
	echo "switched USB to AverMedia"
	# one command for testing:
	# gpioset gpiochip0 3=1; sleep 1; gpioset gpiochip0 2=0; sleep 1; gpioset gpiochip0 4=1; sleep 1; gpioset gpiochip0 2=1; sleep 1
}

resetAVHDpower()
{
	# Turn off power pin 1 second for reset vbus
	gpioset gpiochip0 17=1; sleep 5
	# Turn on power pin
	gpioset gpiochip0 17=0; sleep 5

	printLog "Reset AV HD power"
}
