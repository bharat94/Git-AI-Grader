#!/bin/bash

# exit if no repos directory
if [ ! -d "../repos/" ]
then
	exit 1
fi

# jump to repos
cd "../repos/"

# looping over all repos and git pulling them
for subdir in $(find . -type d -maxdepth 1 ! -name ".")
do
	cd $subdir
	pwd
	git pull
	cd ..
done