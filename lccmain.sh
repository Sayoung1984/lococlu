#! /bin/bash
COLUMNS=512
endline="###---###---###---###---###"
echo -e "#DBG You're been hosted by receptionist v0.1\n"
echo -e "#DBG Your login UID is $LOGNAME\n"

# Set log latency threshhold
loglatency=0

# Define the globle IMGoN mount root $MOUNTROOT
CURDOM=`hostname -d`
while [ ! -n "$MOUNTROOT" ];
do
  case $CURDOM in
    28.sap|28.SAP)
      MOUNTROOT="/home/28/"
      break
      ;;
    ap.qualcomm.com|AP.QUALCOMM.COM)
      MOUNTROOT="/local/mnt/workspace/"
      break
      ;;
    *)
    echo -e "\nUnknown domain, please choose define the image mount root:\n"
    read MOUNTROOT
    break
    ;;
  esac
done
MOUNTROOT=`echo $MOUNTROOT | sed '/\/$/!  s/^.*$/&\//'`
echo -e "Current domain = $CURDOM\n"
echo -e "Default user mount root = $MOUNTROOT\n"

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
    ImgList=`find  /images/vol* -type f | egrep "(\.\.|\/)$LOGNAME\.img$" 2>/dev/null`
}

# Subfunction to get node in lowest load, output $NodeLine family
listnode()
{
    NodeLine=`/bin/cat /receptionist/opstmp/secrt.sitrep.load.* 2>/dev/null | grep -v $endline | sort -n -t$'\t' -k 2 | head -n 1`
    NodeLine_Name=`echo $NodeLine | awk '{print $NR}'`
    NodeLine_Load=`echo $NodeLine | awk '{print $3}'`
    NodeLine_lag=`expr $(date +%s) - $(echo -e "$NodeLine" | awk -F " " '{print $NF}') 2>/dev/null`
    echo -e "\n#DBG_listnode NodeLine_Name = $NodeLine_Name\n#DBG_listnode NodeLine_Load = $NodeLine_Load"
    echo -e "#DBG_listnode NodeLine_lag = $NodeLine_lag\n#DBG_listnode Log latency = $loglatency\n\n"
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

    FreeNode=$NodeLine_Name
    echo -e "\n\nSelect $FreeNode as node with lowest load\n"
}

# Subfunction to make /receptionist/opstmp/resource.mount, output $MountList family
imgoninfo()
{
    # cat /receptionist/opstmp/secrt.sitrep.imgon.* | grep -v $endline 1> /receptionist/opstmp/resource.mount
    # chmod 666 /receptionist/opstmp/resource.mount
    # MountList=`cat /receptionist/opstmp/resource.mount | egrep "(\.\.|\/)$LOGNAME\.img"`
    MountList=`cat /receptionist/opstmp/secrt.sitrep.imgon.* | grep -v $endline | egrep "(\.\.|\/)$LOGNAME\.img"`
    MountList_node=`echo -e "$MountList" | awk -F " " '{print $NR}'`
    MountList_img=`echo -e "$MountList" | awk -F " " '{print $2}'`
    MountList_mntp=`echo -e "$MountList" | awk -F " " '{print $3}'`
    MountList_lag=`expr $(date +%s) - $(echo -e "$MountList" | awk -F " " '{print $NF}') 2>/dev/null`
    # rm -f /receptionist/opstmp/resource.mount
    echo -e "#DBG_imgoninfo MountList family:\t$MountList\n#DBG_imgoninfo MountList_node =\t$MountList_node"
    echo -e "#DBG_imgoninfo MountList_img =\t$MountList_img\n#DBG_imgoninfo MountList_mntp =\t$MountList_mntp"
    echo -e "#DBG_imgoninfo MountList_lag =\t$MountList_lag\n#DBG_imgoninfo Log latency =\t$loglatency\n\n"
}

# Subfunction to send mount ticket, mount $ImgList to $FreeNode
# mountrequest()
# {
#   #cat << EOF > /var/log/rt.ticket.geoexec.$FreeNode.DBG
#   # While got $MOUNTROOT $MOUNTUSER, mount user image in sequence
#   MOUNTROOT=$MOUNTROOT
#   MOUNTUSER=$LOGNAME
#   ImgList=$ImgList
#   MPSORT=`for IMG in $ImgList ; do echo -en $IMG | sed 's/^\/images\/vol[0-9][0-9]\///g' | sed 's/\img$/./g' | sed 's/\.\./\//g' |tac -s "/" ; echo  ; done | sort`
#   MTSEQ=`for MP in $MPSORT ; do echo $ImgList | tr " " "\n" | grep $(echo -n $MP |tac -s "/" | sed 's/\//../g' | sed 's/\.\.$/.img/g' | sed 's/^/\//g') | tr "\n" " " ; echo -e "\t"$MOUNTROOT$MP ; done`
#   for MT in $MTSEQ ; do mount -o loop $MT
#   /bin/echo -e "$endline" $(hostname)
#
#   #EOF
# }

# Secure SSH redirector, the Last subfunction checking $ImgList and $LaunchNode, then patch user through
# !!!Unfinished!!! Still need the mount/unmount function, based on geoexec
secpatch()
{
    if [ ! -n "$ImgList" -o ! -n "$LaunchNode" -o ! -n "$IMGoM_MP" ]
    	then
    		echo -e "#DBG Missing laucn info, current info:\n LaunchNode = $LaunchNode\n ImgList = \n$ImgList\n IMGoM_MP = $IMGoM_MP\n"
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
    	echo -e "#DBG_secpatch   Congrats!!! All good !!! Drill interrupted!!!\n\nPress any key to exit" && read KEY && rm -f /receptionist/opstmp/launchlock.$LOGNAME && exit
    	rm -f /receptionist/opstmp/launchlock.$LOGNAME
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
echo -e "#DBG_Main1   First Check, ImgList =\n$ImgList"
if [ ! -n "$ImgList" ]
then
    sleep $loglatency
    listimg
    echo -e "#DBG_Main1   Double check, ImgList =\n$ImgList"
    if [ ! -n "$ImgList" ]
    then
        sleep $loglatency
        listimg
        echo -e "#DBG_Main1   Treble Check, ImgList =\n$ImgList"
        if [ ! -n "$ImgList" ]
        then
        	echo -e "$LOGNAME" > /receptionist/opstmp/secrt.ticket.mkimg.$LOGNAME
        	chmod 666 /receptionist/opstmp/secrt.ticket.mkimg.$LOGNAME
        	#echo -e "#DBG_Main1    Pre-Create, ImgList = \n$ImgList\n"
        	echo -e "Creating new image for you, please wait ..\c"
        	while [ ! -n "$ImgList" ]
        		do
        			echo -ne "."
        			sleep 1
        			listimg
                    #echo -e "#DBG_Main1   Loop Check, ImgList =\n$ImgList"
        		done
        	echo
        fi
    fi
fi
echo -e "\nGot your image "$ImgList"\n"

#######################################Got $LOGNAME and $ImgList, Needs $LaunchNode and $IMGoM_MP

# Main2_a, check Image mount status, Not mount then $LaunchNode=$FreeNode
imgoninfo
if [ ! -n "$MountList_node" ]
then
    echo -e "Did not find your image mounted on any node\n"
    selectnode
    LaunchNode=$FreeNode
    #####################################
    echo -e "#DBG_Main2_a Insert mount command here...\n\n"
    #####################################
fi

# Main2_b, check Image mount status, mount then LaunchNode=$MountList_node
if [ "$loglatency" -lt "$MountList_lag" ]
then
  rm -f /receptionist/opstmp/secrt.sitrep.imgon.$MountList_node 2>/dev/null
	echo -e "Image mount record overtime > $loglatency seconds!!! Refreshing ..\c"
  sleep $loglatency
  imgoninfo
  #while [ "$loglatency" -lt "$MountList_lag" ]
  while [ ! -n "$MountList_lag" ]
      do
        rm -f /receptionist/opstmp/secrt.sitrep.imgon.$MountList_node 2>/dev/null
        sleep $loglatency
        imgoninfo
        echo -n .
      done
fi
	LaunchNode=$MountList_node
  IMGoM_MP=$MountList_mntp
	echo -e "Found your image mounted on $MountList_mntp of $LaunchNode\n"
	#####################################
	echo -e "#DBG_Main2_b Insert node load check here...\n\n"
	echo -e "#DBG_Main2_b Insert node switch module here...\n\n"
  echo -e "#DBG_Main2_b Insert unmount command here...\n\n"
  echo -e "#DBG_Main2_b Insert selectnode here...\n\n"
  echo -e "#DBG_Main2_b Insert mount command here...\n\n"
	#####################################

echo -e "Got launchnode = $LaunchNode\n ImgList =\n$ImgList"
# echo -e "\n#DBG_XXX  Main2 interrupted!!!\n\nPress any key to exit" && read KEY && rm -f /receptionist/opstmp/launchlock.$LOGNAME && exit

# Main 3, Patch USER to NODE with IMAGE mounted, with last check
#ImgList="" #DBG Interrupted debuger
#LaunchNode="" #DBG Interrupted debuger
secpatch
