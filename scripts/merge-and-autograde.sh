#!/bin/bash

# usage
display_usage() {
	echo -e "\nUsage:\n$0 <PA_number> \n" 
}


# text file to parse the question file mappings
file="question-file-mappings.txt"

if [ "$#" -ne 1 ]
then
    echo "Illegal number of parameters"
    display_usage
fi

if [ "$1" -lt 1  ] || [ "$1" -gt 5  ]
then
    echo "PA assignment number should be between 1 and 5"
    display_usage
fi

# the programming assignment number
pa_number=$1
echo "PA number : $pa_number"

sub_files=$(cat "$file" | grep "$pa_number")

IFS=$','
sub_files_arr=($(cut -d ":" -f 2 <<< "$sub_files"))

trim() {
	echo "${1}" | awk '{gsub(/^ +| +$/,"")} {print $0}'
}

# trimming all the file names
for ((i=0; i<${#sub_files_arr[@]}; ++i))
do
	sub_files_arr[$i]=$(trim "${sub_files_arr[$i]}")
done

# Printing files needed to be merged
if [ "${#sub_files_arr[@]}" -gt 0 ]
then
	echo "files submitted for assignment : "
fi
for ((i=0; i<${#sub_files_arr[@]}; ++i)); do     echo "${sub_files_arr[$i]}"; done

# clean up temp/ if exists else create
if [ -d  "tmp/" ]
then
	echo "tmp folder exists so cleaning it"
	rm -rf "tmp/*"
else
	echo "creating tmp folder"
	mkdir "tmp"
fi
# unzip correct zip to temp

# repeat for each student
# copy student files to temp, autograde, and publish to report


