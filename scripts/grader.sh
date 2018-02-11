#!/bin/bash

# usage
display_usage_and_exit() {
	echo -e "\nUsage:\n$0 <PA_number> \n"
	exit 2
}


# text file to parse the question file mappings
file="question-file-mappings.txt"

if [ "$#" -ne 1 ]
then
    echo "Illegal number of parameters"
    display_usage_and_exit
fi

if [ "$1" -lt 1  ] || [ "$1" -gt 5  ]
then
    echo "PA assignment number should be between 1 and 5"
    display_usage_and_exit
fi

# the programming assignment number
pa_number=$1
echo "PA number : $pa_number"

sub_files=$(cat "$file" | grep "pa${pa_number} :")

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

# Normalize files
sh ./normalize-files.sh "$pa_number"

# clean up tmp/ if exists else create
if [ -d  "tmp/" ]
then
	echo "tmp folder exists so cleaning it"
	rm -rf "./tmp/"
fi

mkdir "tmp"

# unzip correct zip to temp
declare -a zips=( "search" "multiagent" "reinforcement" "tracking" "classification" )

zipName="${zips[$pa_number-1]}"

echo "unzipping ..."
unzip "../zips/${zipName}.zip" -d "tmp/" &> /dev/null
echo "done unzipping"

# Storing the pwd for future jumps
PresentDir="$(pwd)"
echo "stored dir : ${PresentDir}"

# timestamp function
timestamp() {
	date "+%Y%m%d_%H%M%S"
}

# create a report file
timestampNow=$(timestamp)
reportsFile="../reports/pa${pa_number}-results-${timestampNow}.txt"
touch "${reportsFile}"
echo "Created pa${pa_number}-results-${timestampNow}.txt in reports"

printf "\nResults for $(timestamp)\n" >> "${reportsFile}"

run_grader_and_generate_report(){
		# jump and autograde
		cd "tmp/${zipName}/"
		echo "running grader for : ${gitHandle}"

		#default score (when error)
		score="N/A"

		result=$(python -m compileall . &>/dev/null; python "autograder.py" 2>/dev/null | grep "Total: ")

		if [ ! -z "$result" ]
		then
			score=$(trim $(cut -d ":" -f 2 <<< "$result"))
		else
			# Note: sleeping for some seconds here because autograder 
			# chews up a thread when in error -_-
			echo "sleeping 2 secs..."
			sleep 2
		fi

		# jump back
		cd "${PresentDir}"
		echo "${gitHandle}  : ${score}" >> "${reportsFile}"
}


# text file to parse git handles one by one
namesfile="names.txt"

declare -i number_of_sub_files_copied
while IFS= read -r gitHandle || [[ -n "$gitHandle" ]]
do
	cd "${PresentDir}"
	# trimming leading and trailing white spaces
	gitHandle="${gitHandle##*( )}"
	gitHandle="${gitHandle%%*( )}"

	# ignore empty lines or comments
	if [ -z "$gitHandle" ] || [[ ${gitHandle:0:1} == '#' ]]
	then
		continue
	fi

	number_of_sub_files_copied=0

	echo "Grading student : ${gitHandle}"

	# repeat for each student (gitHandle)
	# copy student files to temp, autograde, and publish to report

	for ((i=0; i<${#sub_files_arr[@]}; ++i))
	do
		fileName=${sub_files_arr[$i]}
		echo "copying ${fileName} of ${gitHandle} to tmp"
		if [ -e "../repos_normalized/$gitHandle-CS4100/${fileName}" ]
		then
			yes | cp -rf "../repos_normalized/$gitHandle-CS4100/${fileName}" "tmp/${zipName}/"
			((number_of_sub_files_copied++))
		else
			echo "${fileName} does not exist for ${gitHandle}"
			echo "${gitHandle}  : NoFile" >> "${reportsFile}"
		fi
	done

	if [ "${number_of_sub_files_copied}" -eq "${#sub_files_arr[@]}" ]
	then
		run_grader_and_generate_report
	fi

done < "$namesfile"
