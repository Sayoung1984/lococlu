#! /bin/bash
echo -e "You're been hosted by receptionist v0.1" #DBG
echo -e "Your login UID is "$LOGNAME #DBG

#User launch lock
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
		echo -e "You already have a launch instance record on launch server: \c"
		cat $lockpath
		echo -e "This might caused by your last launch interruption."
		echo -e "If this is your ONLY current launch instance, you can override the launch."
		while true; do
		read -p "Override to launch from here? (Y/N)" USER_OPS
			case $USER_OPS in
        			Y|y|YES|Yes|yes )
                			echo -e "Proceeding to your launch now..."
                			break
					;;
        			N|n|NO|No|no)
                			echo -e "You've been dropped out by launch locker, please contract admins if need help."
					exit
                			;;
				*)
					echo -e "Invalid choice, please choose Yes or No."
					;;
			esac
		done
fi

# Subfunction to list user images
listimg()
{
	find  /images/vol* -type f > /receptionist/opstmp/resource.image
	chmod 666 /receptionist/opstmp/resource.image
	UserImgList=`grep [\.\/]$LOGNAME\. /receptionist/opstmp/resource.image`
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

# Main, create user image if does not exist
echo -e "Looking for your workspace image..."
listimg
# echo $UserImgList
# if [ ! -n "$UserImgList" ]
#	then
#		echo $LOGNAME > /receptionist/opstmp/ticket.mkimg.$LOGNAME
#		chmod 666 /receptionist/opstmp/ticket.mkimg.$LOGNAME
#		echo -e "Creating image for you, please wait \c"
#		var=1
#		while [ "$var" -le 5 ]
#			do
#        		echo -ne "."
#        		var=$(($var+1))
#        		sleep 1
#			done
#		echo
#		listimg
#	else
#		echo -e "Find your image at "$UserImgList
#		rm -f /receptionist/opstmp/resource.image
# fi
if [ ! -n "$UserImgList" ]
        then
                echo $LOGNAME > /receptionist/opstmp/ticket.mkimg.$LOGNAME
                chmod 666 /receptionist/opstmp/ticket.mkimg.$LOGNAME
                echo -e "Creating image for you, please wait \c"
		while [ ! -n "$UserImgList" ]
			do
                        	echo -ne "."
                        	sleep 1
                        	listimg
			done
		echo
		echo -e "Find your image at "$UserImgList
                rm -f /receptionist/opstmp/resource.image
        else
                echo -e "Find your image at "$UserImgList
                rm -f /receptionist/opstmp/resource.image
fi


echo -e '\n\nPlain ssh connection only!\tUser workspace image automount under development...\n'
echo -e '\nHello, Would you like to connect to remote nodes?\n'
echo -e '\t0.Launch ssh with IMGoN\t 1.ssh to delltester02\t2.ssh to smtester01\t3.ssh to smtester02\t9.head bash (For debug only)\n'
echo -e 'You are choosing: \c'
read TARGET_M
case $TARGET_M in
        0)
                rm -f /receptionist/opstmp/launchlock.$LOGNAME
                echo -e "1.Loop mount !!!imgon_path!!! to !!!imgon_mount_point!!! on !!!node_name!!!"
		echo -e "2. ssh $LOGNAME to !!!node_name!!!"
		exec /usr/bin/ssh $LOGNAME@delltester01
		;;
        1)
                exec /usr/bin/ssh $LOGNAME@delltester02
		;;
        2)
                exec /usr/bin/ssh $LOGNAME@smtester01
		;;
        3)
                exec /usr/bin/ssh $LOGNAME@smtester02
		;;
        9)
                rm -f /receptionist/opstmp/launchlock.$LOGNAME
                exec /bin/bash
                ;;

        *)
                echo "Invalid choice, please try again?"
		;;
esac
