#! /bin/bash
COLUMNS=512
endline="###---###---###---###---###"
echo -e "#DBG You're been hosted by receptionist v0.1\n"
echo -e "#DBG Your login UID is "$LOGNAME

# Set log latency threshhold
loglatency=3

# Secure Real Time Text Copy, check text integrity, then drop real time text to NFS at this last step
secrttcp_old()
{
    for REPLX in `ls /var/log/rt.*`
    do
        rpcheckline=`/usr/bin/tail -n 1 $REPLX`
        if [ "$rpcheckline"  != "###---###---###---###---###" ]
        then
            rm $REPLX
        else
            /bin/sed -i '$d' $REPLX
            rpchecklineL2=`/usr/bin/tail -n 1 $REPLX`
            if [ "$rpchecklineL2"  == "###---###---###---###---###" ]
            then
                rm $REPLX
            else
                REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
                cp $REPLX `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
                chmod 666 `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
            fi
        fi
    done
}

# Secure Realtime Text Copy v2, check text integrity, then drop real time text to NFS at this last step, with endline
# /bin/sed -i '$d' $REPLX # To cat last line, on receive side
secrtsend()
{
    for REPLX in `/bin/ls /var/log/rt.*`
    do
      CheckLineL1=`/usr/bin/tac $REPLX | sed -n '1p'`
      CheckLineL2=`/usr/bin/tac $REPLX | sed -n '2p'`
      if [ "$CheckLineL1"  == "$endline `hostname`" -a "$CheckLineL2"  != "$endline `hostname`" ]
      then
        REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
        cp $REPLX `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
        chmod 666 `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
      else
        mv $REPLX.fail  #DBG
        /bin/rm $REPLX
      fi
    done
}


# Subfunction to list user images, output $ImgList if found
listimg()
{
    find  /images/vol* -type f 1> /receptionist/opstmp/resource.image
    chmod 666 /receptionist/opstmp/resource.image
    ImgList=`cat /receptionist/opstmp/resource.image | egrep "(\.\.|\/)$LOGNAME\.img$" 2>/dev/null`
    rm -f /receptionist/opstmp/resource.image
}

# Subfunction to get node in lowest load, output $NodeLine family
listnode()
{
    /bin/cat /receptionist/opstmp/secrt.sitrep.load.* | grep -v $endline | awk '{ print $1"\t"$2"\t"$3"\t"$4"\t"$5}' | sort -n -t$'\t' -k 2 1> /receptionist/opstmp/resource.sortload
    chmod 666 /receptionist/opstmp/resource.sortload
    NodeLine=`cat /receptionist/opstmp/resource.sortload | head -n 1`
    NodeLine_Name=`echo $NodeLine | awk '{print $NR}'`
    NodeLine_Load=`echo $NodeLine | awk '{print $3}'`
    NodeLine_lag=`expr $(date +%s) - $(echo -e "$NodeLine" | awk -F " " '{print $NF}') 2>/dev/null`
    echo -e "\n#DBG_listnode NodeLine_Name = $NodeLine_Name\n#DBG_listnode NodeLine_Load = $NodeLine_Load\n#DBG_listnode NodeLine_lag = $NodeLine_lag\n#DBG_listnode Log latency = $loglatency\n\n"
}

# Subfunction to select free node, output $FreeNode
selectnode()
{
    listnode
    # echo -e "\n#DBG_selectnode NodeLine_Name = $NodeLine_Name\n#DBG_selectnode NodeLine_tstamp = $NodeLine_tstamp\n#DBG_selectnode NodeLine_lag = $NodeLine_lag\n\n"
    echo -e "Refreshing node load info..\c"
    while [ "$NodeLine_lag" -gt "$loglatency" ]
    do
        rm -f /receptionist/opstmp/secrt.sitrep.load.$NodeLine_Name
        sleep $loglatency
        listnode
        echo -e ".\c"
        # echo -e "\n#DBG_selectnode NodeLine_Name = $NodeLine_Name\n#DBG_selectnode NodeLine_tstamp = $NodeLine_tstamp\n#DBG_selectnode NodeLine_lag = $NodeLine_lag\n\n"
    done
    rm -f /receptionist/opstmp/resource.sortload
    FreeNode=$NodeLine_Name
    echo -e "\n\nSelect $FreeNode as node with lowest load.\n"
}

# Subfunction to make /receptionist/opstmp/resource.mount, output $ImgonLn family
imgoninfo()
{
    cat /receptionist/opstmp/secrt.sitrep.imgon.* | grep -v $endline 1> /receptionist/opstmp/resource.mount
    chmod 666 /receptionist/opstmp/resource.mount
    ImgonLn=`cat /receptionist/opstmp/resource.mount | egrep "(\.\.|\/)$LOGNAME\.img"`
    ImgonLn_node=`echo -e "$ImgonLn" | awk -F " " '{print $NR}'`
    ImgonLn_img=`echo -e "$ImgonLn" | awk -F " " '{print $2}'`
    ImgonLn_mntp=`echo -e "$ImgonLn" | awk -F " " '{print $3}'`
    ImgonLn_lag=`expr $(date +%s) - $(echo -e "$ImgonLn" | awk -F " " '{print $NF}') 2>/dev/null`
    rm -f /receptionist/opstmp/resource.mount
    echo -e "#DBG_imgoninfo ImgonLn =\t$ImgonLn\n#DBG_imgoninfo ImgonLn_node =\t$ImgonLn_node"
    echo -e "#DBG_imgoninfo ImgonLn_img =\t$ImgonLn_img\n#DBG_imgoninfo ImgonLn_mntp =\t$ImgonLn_mntp"
    echo -e "#DBG_imgoninfo ImgonLn_lag =\t$ImgonLn_lag\n#DBG_imgoninfo Log latency =\t$loglatency\n\n"
}

# Secure SSH redirector, the Last subfunction checking $ImgList and $LaunchNode, then patch user through
# !!!Unfinished!!! Still need the mount/unmount function, based on geoexec
secpatch()
{
    if [ ! -n "$ImgList" -o ! -n "$LaunchNode" -o ! -n "$IMGoM_MP" ]
    	then
    		echo -e "#DBG Missing laucn info, current info:\n LaunchNode = $LaunchNode\n ImgList = $ImgList\n IMGoM_MP = $IMGoM_MP\n"
    		echo -e "Kicking you out now... Please try connect again.\n"
            rm -f /receptionist/opstmp/launchlock.$LOGNAME
    		exit
    # elif [ ! -n "$LaunchNode" ]
    #	then
    #		echo -e "#DBG Missing user launch node info, current LaunchNode = $LaunchNode\n"
    #		echo -e "Kicking you out now... Please try connect again.\n"
    #		exit
    else
    	echo -e "#DBG Got UID: $LOGNAME\n your image: $ImgList\n mounted on: $IMGoM_MP of $LaunchNode\n"
    	echo -e "Patching you through now...\n"
    	rm -f /receptionist/opstmp/launchlock.$LOGNAME
    	echo -e "#DBG_XXX   Congrats!!! All good !!! Drill interrupted!!!\n\nPress any key to exit" && read KEY && exit
    	/usr/bin/ssh $LOGNAME@$LaunchNode
    fi
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


# Main1, create user root workspace image if does not exist, output  $ImgList when finished.
echo -e "Looking for your workspace image...\n"
listimg
echo -e "#DBG_Main1_A  ImgList=$ImgList"
if [ ! -n "$ImgList" ]
    then
    	echo -e "$LOGNAME" > /receptionist/opstmp/secrt.ticket.mkimg.$LOGNAME
    	chmod 666 /receptionist/opstmp/secrt.ticket.mkimg.$LOGNAME
    	echo -e "#DBG_Main1_B ImgList = $ImgList\n"
    	echo -e "Creating new image for you, please wait ..\c"
    	while [ ! -n "$ImgList" ]
    		do
    			echo -ne "."
    			sleep 1
    			listimg
    		done
    	echo
fi
echo -e "Got your image "$ImgList"\n"

#######################################Got $LOGNAME and $ImgList, Needs $LaunchNode and

# Main2, check Image mount status, get $LaunchNode when finished.
imgoninfo
if [ ! -n "$ImgonLn_node" ]
then
    echo -e "Did not find your image mounted on any node \n"
    selectnode
    LaunchNode=$FreeNode
    #####################################
    echo -e "#DBG Insert mount command here..."
    #####################################
elif [ "$ImgonLn_lag" -gt "$loglatency" ]
then
	#####################################
	echo -e "#DBG Insert wait loop here..."
	#####################################
	rm -f /receptionist/opstmp/secrt.sitrep.imgon.$ImgonLn_node
	echo -e "Image mount record overtime > $loglatency seconds!!! Refresh? (Y/N) \c"
	while true; do
	read USER_CHO
		case $USER_CHO in
			Y|y|YES|Yes|yes)
					echo -e "Wait $loglatency seconds and fetch mount info again..."
					sleep $loglatency
					imgoninfo
					if [ -n "$ImgonLn_node" ]
					then
						echo -e "Found your image mounted on $ImgonLn_node"
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
	LaunchNode=$ImgonLn_node
	echo -e "Find your image mounted on "$LaunchNode
	#####################################
	echo -e "#DBG Insert node load check here..."
	echo -e "#DBG Insert node switch module here..."
	#####################################
fi
echo -e "Got launchnode = "$LaunchNode"\n"

# Main 3, Patch USER to NODE with IMAGE mounted, with last check
#ImgList="" #DBG Interrupted debuger
#LaunchNode="" #DBG Interrupted debuger
secpatch
