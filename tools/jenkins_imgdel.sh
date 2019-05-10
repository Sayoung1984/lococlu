#!/bin/bash


for folder in $FOLDER1 $FOLDER2 $FOLDER3
do
        FOLDER="L"`echo $folder | awk -FL '{print $2}' | sed 's/;//g'`
        echo "FOLDER is $FOLDER"
        if [ -f "/images/vol00/${FOLDER}..${BUILD_USER}.img" ]; then
                killlist="${FOLDER}..${BUILD_USER}.img"
                echo "killlist is $killlist"
                /receptionist/lococlu/tools/imgdel.sh -i "$killlist"
		sleep 0.2
        else
                echo "$FOLDER not found. Please check if you have input the right folder name!"
        fi

done
