#!/bin/bash

# text file to parse git handles one by one
file="names.txt"

# check if repos folder exists before starting to clone
if [ -d "../repos/" ]
then
	echo "repos exists"
else
	# setting up the repos folder
	echo "repos folder does not exist, setting up repos folder ..."
	mkdir "../repos/"
	touch "../repos/repos-readme.txt"
	echo "The git repos will be pulled into this folder" > "../repos/repos-readme.txt"
fi

while IFS= read -r gitHandle || [[ -n "$gitHandle" ]]
do
	# trimming leading and trailing white spaces
	gitHandle="${gitHandle##*( )}"
	gitHandle="${gitHandle%%*( )}"

	# ignore empty lines or comments
	if [ -z "$gitHandle" ] || [[ ${gitHandle:0:1} == '#' ]]
	then
		continue
	fi

	# clone repo

	# Format of remote repo : https://github.ccs.neu.edu/{gitHandle}/CS4100.git
	# Output folder : repos/gitHandle-CS4100/
	if [ ! -d "../repos/$gitHandle-CS4100" ]
	then
		git clone "https://github.ccs.neu.edu/$gitHandle/CS4100.git" "../repos/$gitHandle-CS4100"
		echo "cloned repo for $gitHandle"
	else
		echo "repo already exists"
	fi
done < "$file"
