#!/bin/bash

# Enable pipefail
set -euo pipefail

# I always forget git codes, so why not script it?
# Usage: ./gitpushscript webserverbootstrap.sh

if [ $# -ne 1 ]; then
	echo " Error. Usage: gitscriptpush path_to_file"
	exit 1
fi

git add $1
sleep 0.5
echo -e "Do you want to write a commit message before commiting?"
echo "Y/N or Q - quit" 
read options; 

case $options in
	y|Y)
		echo "write a commit message:/n"
		read -r commitmessage
		git commit -m "$commitmessage"
		;;
	n|N)
		 git commit
		 ;;
	q|Q)
		exit 0
		 ;;
	*)
		 echo "BITCH!! daFuck is wrong with you? PIck an option gAADAMMIT"
		 ;;
esac

git branch -M main
git pull origin main
git push origin main
