#! /bin/bash
echo -e "You're been hosted by receptionist v0.1" #DBG
echo -e "Your login UID is "$LOGNAME #DBG

# Main0 User launch lock
lockpath=/receptionist/opstmp/launchlock.$LOGNAME
# echo lockpath=$lockpath #DBG
# ls -lah $lockpath #DBG
# cat $lockpath #DBG
if [ ! -f "$lockpath" ]
	then
		echo -e "Spooling login session on `hostname` now..."
		echo `hostname` > /receptionist/opstmp/launchlock.$LOGNAME
		chmod 666 /receptionist/opstmp/launchlock.$LOGNAME
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

# Subfunction to list user images
listimg()
{
	find  /images/vol* -type f > /receptionist/opstmp/resource.image
	chmod 666 /receptionist/opstmp/resource.image
#	UserImgList=`grep [\.\/]$LOGNAME\. /receptionist/opstmp/resource.image`
	UserImgList=`cat /receptionist/opstmp/resource.image | egrep "(\.\.|\/)$LOGNAME\.\.img"`
}

# Subfunction to list nodes' load
listnode()
{
	cat /receptionist/opstmp/secrep.loadrep.* > /receptionist/opstmp/resource.node
	chmod 666 /receptionist/opstmp/resource.node
}

# Subfunction to list IMGoN mounted images 
listimgon()
{
	cat /receptionist/opstmp/secrep.imgonrep.* > /receptionist/opstmp/resource.imgon
	chmod 666 /receptionist/opstmp/resource.imgon
}

# Main1, create user image if does not exist, get $UserImgList when finished.
echo -e "Looking for your workspace image...\n"
listimg
##############
#echo UserImgList=$UserImgList
##############
if [ ! -n "$UserImgList" ]
then
	echo $LOGNAME > /receptionist/opstmp/ticket.mkimg.$LOGNAME
	chmod 666 /receptionist/opstmp/ticket.mkimg.$LOGNAME
	echo -e "UserImgList=$UserImgList ..Z #DBG"
	echo -e "Creating image for new user, please wait \c"
	while [ ! -n "$UserImgList" ]
		do
			echo -ne "."
			listimg
			sleep 1
		done
	echo
#	echo -e "Find your image "$UserImgList"\n..A #DBG"
#        rm -f /receptionist/opstmp/resource.image
#else
#	echo -e "Find your image "$UserImgList"\n..B #DBG"
#	rm -f /receptionist/opstmp/resource.image
fi
echo -e "Got your image "$UserImgList"\n"
rm -f /receptionist/opstmp/resource.image


# Main2, check Image mount status, get $LaunchNode when finished.
ImgonLine=`cat /receptionist/opstmp/secrep.imgonrep.* | egrep "(\.\.|\/)$LOGNAME\.\.img"`
ImgonLine_node=`echo -e "$ImgonLine" | awk -F " " '{print $1}'`
ImgonLine_timestamp=`echo -e "$ImgonLine" | awk -F " " '{print $NF}'`
ImgonLine_latency=`expr $(date +%s) - $ImgonLine_timestamp`
echo -e "ImgonLine:\n"$ImgonLine"\nImgonLine_node = "$ImgonLine_node"\nImgonLine_latency = "$ImgonLine_latency
if [ ! -n "$ImgonLine_node" ]
then
	echo -e "Did not find your image mounted on any node"
	#####################################
	echo insert mount command here...
	#####################################
elif [ $ImgonLine_latency > 1 ]
then
	echo -e "IMGoN record overtime!!!"
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




echo -e '\n\nPlain ssh connection only!\tUser workspace image automount under development...\n'
echo -e '\nHello, Would you like to connect to remote nodes?\n'
echo -e '\t0.Launch ssh with IMGoN\t 1.ssh to muscle01\t2.ssh to muscle02\t3.ssh to muscle03\t9.Local bash(For prototype demo only)\n'
echo -e 'You are choosing: \c'
read TARGET_M
case $TARGET_M in
        0)
                rm -f /receptionist/opstmp/launchlock.$LOGNAME
                echo -e "1.Loop mount !!!imgon_path!!! to !!!imgon_mount_point!!! on !!!node_name!!!"
		echo -e "2. ssh $LOGNAME to !!!node_name!!!"
		exec /usr/bin/ssh $LOGNAME@muscle01
		;;
        1)
                exec /usr/bin/ssh $LOGNAME@muscle01
		;;
        2)
                exec /usr/bin/ssh $LOGNAME@muscle02
		;;
        3)
                exec /usr/bin/ssh $LOGNAME@muscle03
		;;
        9)
                rm -f /receptionist/opstmp/launchlock.$LOGNAME
                exec /bin/bash
                ;;

        *)
                echo "Invalid choice, please try again?"
		;;
esac
