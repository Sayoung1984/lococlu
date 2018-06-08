#! /bin/bash
echo -e "#DBG You're been hosted by receptionist v0.1"
echo -e "#DBG Your login UID is "$LOGNAME

# Subfunction to list user images, output $UserImgList if found
listimg()
{
	find  /images/vol* -type f 1> /receptionist/opstmp/resource.image
	chmod 666 /receptionist/opstmp/resource.image
#	UserImgList=`grep [\.\/]$LOGNAME\. /receptionist/opstmp/resource.image`
	UserImgList=`cat /receptionist/opstmp/resource.image | egrep "(\.\.|\/)$LOGNAME\.img$"`
}

# Subfunction to list nodes' load
listnode()
{
	cat /receptionist/opstmp/secrep.loadrep.* 1> /receptionist/opstmp/resource.node
	chmod 666 /receptionist/opstmp/resource.node
}

# Subfunction to list IMGoN mounted images 
listimgon()
{
	cat /receptionist/opstmp/secrep.imgonrep.* 1> /receptionist/opstmp/resource.imgon
	chmod 666 /receptionist/opstmp/resource.imgon
}

# Subfunction to select free node, output $FreeNode
selectnode()
{
	
}

# Main0 User launch lock
lockpath=/receptionist/opstmp/launchlock.$LOGNAME
# echo lockpath=$lockpath #DBG
# ls -lah $lockpath #DBG
# cat $lockpath #DBG
if [ ! -f "$lockpath" ]
	then
		echo -e "Spooling login session on `hostname` now...\n"
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
        			Y|y|YES|Yes|yes )
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
	echo $LOGNAME > /receptionist/opstmp/ticket.mkimg.$LOGNAME
	chmod 666 /receptionist/opstmp/ticket.mkimg.$LOGNAME
	echo -e "#DBG Z UserImgList = $UserImgList"
	echo -e "Creating image for new user, please wait \c"
	while [ ! -n "$UserImgList" ]
		do
			echo -ne "."
			listimg
			sleep 1
		done
	echo
fi
echo -e "Got your image "$UserImgList"\n"
rm -f /receptionist/opstmp/resource.image


# Main2, check Image mount status, get $LaunchNode when finished.
ImgonLine=`cat /receptionist/opstmp/secrep.imgonrep.* | egrep "(\.\.|\/)$LOGNAME\.img"`
ImgonLine_node=`echo -e "$ImgonLine" | awk -F " " '{print $1}'`
ImgonLine_timestamp=`echo -e "$ImgonLine" | awk -F " " '{print $NF}'`
ImgonLine_latency=`expr $(date +%s) - $ImgonLine_timestamp 2>/dev/null`
# ImgonLine_latency=`$(($(date +%s) - $ImgonLine_timestamp)) 2>/dev/null`
echo -e "#DBG ImgonLine =\t"$ImgonLine"\n#DBG ImgonLine_node =\t"$ImgonLine_node"\n#DBG ImgonLine_latency =\t"$ImgonLine_latency
if [ ! -n "$ImgonLine_node" ]
then
	echo -e "Did not find your image mounted on any node \n"
	#####################################
	echo insert mount command here...
	#####################################
elif [ "$ImgonLine_latency" -gt 30 ]
then
	echo -e "ImgonLine_latency > 30, IMGoN record of $ImgonLine_node overtime!!!"
	#####################################
	echo insert wait loop here...
	#####################################
	exit
else
	LaunchNode=$ImgonLine_node
	echo -e "Find your image mounted on "$LaunchNode
	#####################################
	echo insert node load check here...
	echo insert node switch module here...
	#####################################
fi

# Main 3, drop USER to NODE with IMAGE mounted
if [ ! -n "$UserImgList" ]
	then
		echo -e "#DBG Missing user image path info, current UserImgList = $UserImgList\n"
		echo -e "Kicking you out now...\n"
		exit
elif [ ! -n "$LaunchNode" ]
	then
		echo -e "#DBG Missing user launch node info, current LaunchNode = $LaunchNode\n"
		echo -e "Kicking you out now...\n"
		exit
else
	echo -e "#DBG Got your UID: $LOGNAME, your image: $UserImgList mounted on $LaunchNode\n"
	echo -e "Patching you through now...\n"
	rm -f /receptionist/opstmp/launchlock.$LOGNAME
	/usr/bin/ssh $LOGNAME@$LaunchNode
fi
