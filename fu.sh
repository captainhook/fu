#!/bin/bash
# FU - Folder Updater | Update a folder while preserving target ownership/group/permissions
# This script is released under GNU General Public License v3.0.
# Version: 2.0
# Changelog: 
# + batch processing (https://github.com/captainhook/fu/issues/2)
# + accept absolute path for source directory (https://github.com/captainhook/fu/issues/1)
# + overall improvement of output and processing

#####
# Functions
#####

# Help text for the script
Fhelp() {
	echo "Usage: $(basename $0) -s <source directory> -t <target directory>"
	echo ""
}
# Prefix date/time to output
Fecho() {
	echo "$(date "+%d-%m-%Y %H:%M:%S:") $@"
}
# Write error to stdout and log file
Ferror() {
	case "$1" in
		exit)
			shift
			Fecho "[ERROR] $@"
			exit 1
			;;
		noexit)
			shift
			Fecho "[ERROR] $@"
			;;
	esac
}
FisInstalled() {
	if which "$1" &> /dev/null
	then
		return 0
	else
		return 1
	fi
}

#####
# Variables
#####
sdir=
tdir=

#####
# Script Start
#####

# Check required binaries/tools
for i in install find
do
	if ! FisInstalled "$i"
	then
		Fecho exit "ERROR: > $i < not found! Please install it using the package manager of your system!"
	fi
done

# Interpreting script parameters
while ! test -z "$1"
do
	case "$1" in
		-s)
			shift
			if echo "$1" | grep "^/" &> /dev/null
			then
				sdir="$1"
			else
				sdir="$(pwd)/$1"
			fi
			;;
		-t)
			shift
			if echo "$1" | grep "^/" &> /dev/null
			then
				tdir="$1"
			else
				tdir="$(pwd)/$1"
			fi
			;;
		*)
			Ferror noexit "Unknown argument: $1"
			Fhelp
			exit 1
			;;
	esac
	shift
done

# Check given parameters
if ! test -d "$sdir"
then
	Ferror exit "Source directory not found!"
fi
if ! test -d "$tdir"
then
	Ferror exit "Target directory not found!"
fi

find "$tdir" -type d > "/tmp/fu.target.tmp"

find "$sdir" -maxdepth 1 ! -path "$sdir" -type d | while read sourcefile
do
	# Remove the path to get a pattern to search for on the target
	file=$(echo "$sourcefile" | awk -F "/" '{print $NF}')
	
	# Skip empty lines
	test -z "$file" && continue
	
	Fecho "SOURCE: $sourcefile"
	
	# Find correct path in target directory
	grep "$file$" "/tmp/fu.target.tmp" | while read targetfile
	do
		Fecho "TARGET: $targetfile"
		
		fileowner=$(stat -c "%U" "$targetfile")
		filegroup=$(stat -c "%G" "$targetfile")
		
		if test -d "$targetfile"
		then
			# If file is a directory - copy it to the target location and set permissions
			Fecho "Copying Directory!"
			if cp -frT "$sourcefile" "$targetfile"
			then
				Fecho "SUCCESS!"
				chown -R "${fileowner}" "$targetfile"
				chgrp -R "${filegroup}" "$targetfile"
				find "$targetfile" -type d -exec chmod 755 {} \;
				find "$targetfile" -type f -exec chmod 644 {} \;
			else
				Ferror noexit "Failed to copy directory!"
			fi
		else
			# Skipping
			continue
		fi
	done
	echo "-------"
done

rm "/tmp/fu.target.tmp"

exit 0
