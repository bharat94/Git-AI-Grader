#!/bin/bash

# The aim of this script is to preprocess the repos and structure them such that all the submissions
# follow a similar hierarchy or folder structure.

# Logic demystified:
# Loop through all the repos in repos
# For each repo, search for the submission files (respective to a programming assignment number)
# move these files to a new normalized repo for easier grading and future moss detection.

# usage : pass in the programming assignment number to search for the assignments submission file
display_usage_and_exit() {
	echo -e "\nUsage:\n$0 <PA_number> \n"
	exit 2
}

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

pa_number=$1

# Array to store the submission files for the assignment
sub_files_arr=()

# storing the assignment names
declare -a assignment_names=( "search" "multiagent" "reinforcement" "tracking" "classification" )

# extracting the assignment name for this assignment
assignment_name="${assignment_names[$pa_number-1]}"

parse_question_file_mappings() {
	# text file to parse the question file mappings
	file="question-file-mappings.txt"
	# the programming assignment number
	
	echo "PA number : $pa_number"

	local sub_files=$(cat "$file" | grep "pa${pa_number} :")

	local IFS=$','
	sub_files_arr=($(cut -d ":" -f 2 <<< "$sub_files"))

	trim() {
		echo "${1}" | awk '{gsub(/^ +| +$/,"")} {print $0}'
	}

	# trimming all the file names
	for ((i=0; i<${#sub_files_arr[@]}; ++i))
	do
		sub_files_arr[$i]=$(trim "${sub_files_arr[$i]}")
	done
}

create_or_clean_normalized_dir() {
	# creates or cleans the normalized repo
	# clean up tmp/ if exists else create
	if [ -d  "../repos_normalized" ]
	then
		echo "repos_normalized folder exists so cleaning it"
		rm -rf "../repos_normalized"
	fi

	mkdir "../repos_normalized"
}

print_arr() {
	local arr=("$@")
	# Printing files needed to be merged
	for ((i=0; i<${#arr[@]}; ++i)); do     echo "${arr[$i]}"; done
}

check_if_repos_exists() {
	if [ -d "../repos/" ]
	then
		echo "repos exists, proceeding ..."
	else
		echo "repos does not exist for normalizing"
		exit 1
	fi
}

get_all_dirs() {
	cd ..
	cd "repos"
	ReposDir="$(pwd)"
	cd ..
	cd "repos_normalized"
	ReposNormDir="$(pwd)"
	cd "${PresentDir}"
}

find_path_for_filename() {
	# a priority based search for searching submission files
	# returns the path to the file if found
	# else returns empty

	#parsing inputs
	local file_to_search=$1

	# first check if file exists inside PAx directly
	if [ -e "PA${pa_number}/${file_to_search}" ]
	then
		echo "PA${pa_number}/${file_to_search}"
	# Same condition with lowercase
	elif [ -e "pa${pa_number}/${file_to_search}" ]
	then
		echo "pa${pa_number}/${file_to_search}"
	# check if file exists inside PAx/<assignmentName>/ 
	elif [ -e "PA${pa_number}/${assignment_name}/${file_to_search}" ]
	then
		echo "PA${pa_number}/${assignment_name}/${file_to_search}"
	# same condition with lower case
	elif [ -e "pa${pa_number}/${assignment_name}/${file_to_search}" ]
	then
		echo "pa${pa_number}/${assignment_name}/${file_to_search}"
	# check if file exists inside <assignmentName>/ 
	elif [ -e "${assignment_name}/${file_to_search}" ]
	then
		echo "${assignment_name}/${file_to_search}"
	# check if file exists inside PA x/<assignmentName>/ 
	elif [ -e "PA ${pa_number}/${file_to_search}" ]
	then
		echo "PA ${pa_number}/${file_to_search}"
	# checking if the file exists directly inside the root folder : you never know 
	elif [ -e "${file_to_search}" ]
	then
		echo "${file_to_search}"
	else
		# returning error if nothing found
		return 1
	fi

	return 0
	# add more advanced search logic by adding more elifs
}

# main begins here

parse_question_file_mappings

if [ "${#sub_files_arr[@]}" -gt 0 ]
then
	echo "files submitted for assignment : "
	print_arr "${sub_files_arr[@]}"
fi

check_if_repos_exists

create_or_clean_normalized_dir

# Storing the pwd and other dirs for future jumps
PresentDir="$(pwd)"
ReposDir=""
ReposNormDir=""

get_all_dirs

echo "stored dir : ${PresentDir}"
echo "repos dir : ${ReposDir}"
echo "repos normalized dir : ${ReposNormDir}"

# jump to repos
cd "${ReposDir}"

# looping over all repos, finding files and copying them over to normalized
for subdir in $(find . -type d -maxdepth 1 ! -name ".")
do
	cd $subdir
	base_subdir=$(basename $subdir)
	# make a subdir in normalized
	mkdir "${ReposNormDir}/${base_subdir}"

	# find the search files
	# copy these files to that normalized dir

	for ((i=0; i<${#sub_files_arr[@]}; ++i))
	do
		fileName=${sub_files_arr[$i]}
		#echo "${ReposNormDir}/${base_subdir}/${fileName}"
		file_path=$(find_path_for_filename ${fileName})

		if [[ -z $file_path ]]
		then
			echo "No ${fileName} found for ${base_subdir}"
		else
			yes | cp -rf "${file_path}" "${ReposNormDir}/${base_subdir}/${fileName}"
		fi
	done

	cd ..
done


