#!/bin/sh

# Program to use the command install recursivly in a folder
# Original: https://gist.github.com/Bl4ckb0ne/3a79934492114eb812956dd4ec2bbc7e

magic_func() {
	echo "entering ${1}"
	echo "target ${2}"
	
	fileowner=$(stat -c "%U" $2)
	filegroup=$(stat -c "%G" $2)

	for file in ${1}; do
		if [ -f "$file" ]; then
			echo "file : $file"
			echo "installing into ${2}/$file"
			install -C -o ${fileowner} -g ${filegroup} -D $file $2/$file
			find "$2/$file" -type d -exec chmod 755 {} \;
			find "$2/$file" -type f -exec chmod 644 {} \;
			
		elif [ -d "$file" ]; then
			echo "directory : $file"
			magic_func "$file/*" "${2}"
			
		else
			echo "not recognized : $file"
		fi
	done
}

magic_func "$1" "$2"
