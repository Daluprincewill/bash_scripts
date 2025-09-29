#!/bin/bash

################ Config files and variable declarations##############################################################################################
release_file=/etc/os-release
logfile=/var/log/updater.log
errorlog=/var/log/updater_errors.log

################ Create a function to check our exit code, to reduce redundancy ######################################################################
check_exit_status() {
	if [ $? -ne 0 ]
	then
		echo "An error occured in this hoe, Please check the $errorlog file"
	fi
}
#######################################################################################################################################################

if grep -q "Arch" $release_file
then
	# The host is based on Arch linux, run the pacman command
	sudo pacman -Syu 1>>$logfile 2>>$errorlog
	check_exit_status

elif grep -q "Debian" $release_file || grep -q "Ubuntu" $release_file
then 	# the host isbased on debian or ubuntu, run the apt update command
	sudo apt upgrade -y && sudo apt update -y 1>>$logfile 2>>$errorlog # append the stdout or stderr to the appropriate location
	check_exit_status

fi

