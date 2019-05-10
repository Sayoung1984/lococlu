#!/bin/bash


for folder in $FOLDER1 $FOLDER2 $FOLDER3
do
	FOLDER="L"`echo $folder | awk -FL '{print $2}' | sed 's/;//g'`
	echo $FOLDER
	if [ -d "/image/vol00/${FOLDER}..${BUILD_USER}.img" ]; then
		killlist="$FOLDER..$BUILD_USER.img"
		echo $killlist
		#imgdel.sh -i $killlist 
	else
		echo "$FOLDER not found. Please check if you have input the right folder name!"
	fi

done
