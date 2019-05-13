#! /bin/bash
 # FOLDER1=LA.UM-XXX && FOLDER2= && FOLDER3=/images/vol00/LE.UM.0.0-20190510155420
 # BUILD_USER=$LOGNAME

c=0
for folder in $FOLDER1 $FOLDER2 $FOLDER3
do
        FOLDER=`echo $folder | sed 's/;$//g;s/\/$//g' | awk -F"/" '{print $NF}'`
        echo "FOLDER is $FOLDER"
        if [ -f "/images/vol00/$FOLDER..${BUILD_USER}.img" ]; then
                killlist[$c]="$FOLDER..${BUILD_USER}.img"
                echo "killlist is ${killlist[$c]}"
                ((c++))
        else
                echo "$FOLDER not found. Please check if you have input the right folder name!"
        fi
done
Tgtlist=$(for item in ${killlist[@]}; do echo $item; done)
# echo -e "!!!KABOOOOM!!! $Tgtlist !!!KABOOOOM!!!"
/receptionist/lococlu/tools/imgdel.sh -i "$Tgtlist"
