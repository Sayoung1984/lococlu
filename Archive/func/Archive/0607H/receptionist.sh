#! /bin/bash
echo -e "#DBG You're been hosted by receptionist v0.1"
echo -e "#DBG Your login UID is "$LOGNAME

# Set log latency threshhold
loglatency=3

# Unique finish tag to ensure report integrity
endline()
{
    /bin/echo -e "---###---###---###---###---"
}

# Secure Real Time Text Copy, check text integrity, then drop real time text to NFS at this last step
secrttcp()
{
    for REPLX in `ls /var/log/rt.*`
        do
            rpcheckline=`/usr/bin/tail -n 1 $REPLX`
            if [ "$rpcheckline"  != "---###---###---###---###---" ]
                then
                    rm $REPLX
                else
                    /bin/sed -i '$d' $REPLX
		    rpchecklineL2=`/usr/bin/tail -n 1 $REPLX`
		    if [ "$rpchecklineL2"  == "---###---###---###---###---" ]
		    	then
			     rm $REPLX
			else
			     REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
		    	     cp $REPLX `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
					 chmod 666 `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
#                    	     cp $REPLX `echo $REPLX | sed 's/\/var\/log/\/receptionist/'`
		    fi
            fi
        done
}

# Subfunction to list user images, output $UserImgList if found
listimg()
{
find  /images/vol* -type f 1> /receptionist/opstmp/resource.image
chmod 666 /receptionist/opstmp/resource.image
#	UserImgList=`grep [\.\/]$LOGNAME\. /receptionist/opstmp/resource.image`
UserImgList=`cat /receptionist/opstmp/resource.image | egrep "(\.\.|\/)$LOGNAME\.img$"`
}

# Subfunction to get node in lowest load
listnode()
{
/bin/cat /receptionist/opstmp/secrt.sitrep.load.* | awk '{ print $1"\t"$2"\t"$3"\t"$4"\t"$5}' | sort -n -t$'\t' -k 2 1> /receptionist/opstmp/resource.sortload
chmod 666 /receptionist/opstmp/resource.sortload
NodeLine=`cat /receptionist/opstmp/resource.sortload | head -n 1`
NodeLine_Name=`echo $NodeLine | awk '{print $1}'`
NodeLine_timestamp=`echo -e "$NodeLine" | awk -F " " '{print $NF}'`
NodeLine_latency=`expr $(date +%s) - $NodeLine_timestamp 2>/dev/null`
}

# Subfunction to select free node, output $FreeNode
selectnode()
{
  listnode
#   echo -e "\n#DBG_C Log latency = $loglatency\n#DBG_C NodeLine_Name = $NodeLine_Name\n#DBG_C NodeLine_timestamp = $NodeLine_timestamp\n#DBG_C NodeLine_latency = $NodeLine_latency\n\n"
  echo -e "Refreshing node load info..\c"
    while [ "$NodeLine_latency" -gt "$loglatency" ]
  		do
        rm -f /receptionist/opstmp/secrt.sitrep.load.$NodeLine_Name
  			sleep $loglatency
        listnode
        echo -e ".\c"
         echo -e "\n#DBG_D NodeLine_Name = $NodeLine_Name\n#DBG_D NodeLine_timestamp = $NodeLine_timestamp\n#DBG_D NodeLine_latency = $NodeLine_latency\n\n"
  		done
  rm -f /receptionist/opstmp/resource.sortload
  FreeNode=$NodeLine_Name
  echo -e "\n\nSelect $FreeNode as node with lowest load.\n"
}

# Subfunction to list IMGoN mounted images
listimgon()
{
cat /receptionist/opstmp/secrt.sitrep.imgon.* 1> /receptionist/opstmp/resource.imgon
chmod 666 /receptionist/opstmp/resource.imgon
}

# Subfunction to fetch IMGoN mount info
imgoninfo()
{
ImgonLine=`cat /receptionist/opstmp/secrt.sitrep.imgon.* | egrep "(\.\.|\/)$LOGNAME\.img"`
ImgonLine_node=`echo -e "$ImgonLine" | awk -F " " '{print $1}'`
ImgonLine_timestamp=`echo -e "$ImgonLine" | awk -F " " '{print $NF}'`
ImgonLine_latency=`expr $(date +%s) - $ImgonLine_timestamp 2>/dev/null`
echo -e "#DBG_A ImgonLine =\t"$ImgonLine"\n#DBG_A ImgonLine_node =\t"$ImgonLine_node"\n#DBG_A ImgonLine_latency =\t"$ImgonLine_latency"\n"
}

# Main0 User launch lock
lockpath=/receptionist/opstmp/launchlock.$LOGNAME
# echo lockpath=$lockpath #DBG
# ls -lah $lockpath #DBG
# cat $lockpath #DBG
if [ ! -f "$lockpath" ]
	then
		echo -e "\nSpooling login session on `hostname` now...\n"
		echo `hostname` > /receptionist/opstmp/launchlock.$LOGNAME
		chmod 666 /receptionist/opstmp/launchlock.$LOGNAME
		sleep 1
	else
		echo -e "\nYou already have a launch instance record on launch server: \c"
		cat $lockpath
		echo -e "\nThis might caused by your last launch interruption."
		echo -e "If this is your ONLY current launch instance, you can override the launch.\n"
		while true; do
		read -p "Override to launch from here? (Y/N)" USER_OPS
			case $USER_OPS in
        			Y|y|YES|Yes|yes)
                			echo -e "\nProceeding to your launch now...\n"
                			break
					;;
        			N|n|NO|No|no)
                			echo -e "\nYou've been dropped out by launch locker, please contract admins if need help.\n"
					exit
                			;;
				*)
					echo -e "\nInvalid choice, please choose Yes or No.\n"
					;;
			esac
		done
fi


# Main1, create user image if does not exist, get $UserImgList when finished.
echo -e "Looking for your workspace image...\n"
listimg
#echo -e "#DBG  UserImgList=$UserImgList"
if [ ! -n "$UserImgList" ]
then
	echo $LOGNAME > /var/log/rt.ticket.mkimg.$LOGNAME
	endline >> /var/log/rt.ticket.mkimg.$LOGNAME
	secrttcp
	echo -e "#DBG Z UserImgList = $UserImgList"
	echo -e "Creating image for new user, please wait \c"
	while [ ! -n "$UserImgList" ]
		do
			echo -ne "."
			sleep 1
			listimg
		done
	echo
fi
echo -e "Got your image "$UserImgList"\n"
rm -f /receptionist/opstmp/resource.image


# Main2, check Image mount status, get $LaunchNode when finished.
imgoninfo
if [ ! -n "$ImgonLine_node" ]
then
	echo -e "Did not find your image mounted on any node \n"
	selectnode
  LaunchNode=$FreeNode
  #####################################
	echo -e "#DBG Insert mount command here..."
	#####################################
elif [ "$ImgonLine_latency" -gt "$loglatency" ]
then
	rm -f /receptionist/opstmp/secrt.sitrep.imgon.$ImgonLine_node
	echo -e "Image mount record overtime > $loglatency seconds!!! Refresh? (Y/N) \c"
	while true; do
	read USER_CHO
		case $USER_CHO in
			Y|y|YES|Yes|yes)
					echo -e "\nWait $loglatency seconds and fetch mount info again..."
					sleep $loglatency
					imgoninfo
					if [ -n "$ImgonLine_node" ]
					then
						echo -e "Found your image mounted on $ImgonLine_node"
					else
						echo -e "Your image mount info still missing..."
					fi
					echo -e "Refresh again? \c"
					;;
			N|n|NO|No|no)
					break
					;;
			*)
					echo -e "\nInvalid choice, please choose Yes or No.\n"
					;;
		esac
	done
	#####################################
  selectnode
  LaunchNode=$FreeNode
	echo -e "#DBG Insert mount command here..."
	LaunchNode=DBG_E
	#####################################
else
	LaunchNode=$ImgonLine_node
	echo -e "Find your image mounted on "$LaunchNode
	#####################################
	echo -e "#DBG Insert node load check here..."
	echo -e "#DBG Insert node switch module here..."
	#####################################
fi
echo -e "Got launchnode = "$LaunchNode"\n"

# Main 3, Patch USER to NODE with IMAGE mounted, with last check
#UserImgList="" #DBG Interrupted debuger
#LaunchNode="" #DBG Interrupted debuger
if [ ! -n "$UserImgList" -o ! -n "$LaunchNode" ]
	then
		echo -e "#DBG Missing laucn info, current UserImgList = $UserImgList, LaunchNode = $LaunchNode\n"
		echo -e "Kicking you out now... Please try connect again.\n"
		exit
# elif [ ! -n "$LaunchNode" ]
#	then
#		echo -e "#DBG Missing user launch node info, current LaunchNode = $LaunchNode\n"
#		echo -e "Kicking you out now... Please try connect again.\n"
#		exit
else
	echo -e "#DBG Got your UID: $LOGNAME, your image: $UserImgList mounted on $LaunchNode\n"
	echo -e "Patching you through now...\n"
	rm -f /receptionist/opstmp/launchlock.$LOGNAME
  echo -e "#DBG_XXX   Congrats!!! You reached the last patch step!!! Drill interrupted!!!" && exit
	/usr/bin/ssh $LOGNAME@$LaunchNode
fi
