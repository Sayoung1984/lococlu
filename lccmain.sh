#! /bin/bash
COLUMNS=512
endline="###---###---###---###---###"
loglatency=3
opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
source $lococlu/lcc.conf
# /bin/echo -e "# DBG_lcc.conf \nCOLUMNS=$COLUMNS\nendline=$endline\nopstmp=$opstmp\nlococlu=$lococlu\ndskinitsz=$dskinitsz\n#\n" > /root/DBG_lcc.conf
# /bin/cat $lococlu/lcc.conf >> /root/DBG_lcc.conf

# echo -e "#DBG You're been hosted by receptionist v0.1\n"
# echo -e "#DBG Your login UID is $LOGNAME\n"

# Define the globle IMGoN mount root $MOUNTROOT
CURDOM=`hostname -d`
while [ ! -n "$MOUNTROOT" ];
do
  case $CURDOM in
    28.sap|28.SAP)
      MOUNTROOT="/home/28/"
      break
      ;;
    ap.qualcomm.com|AP.QUALCOMM.COM|qualcomm.com|QUALCOMM.COM)
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
# echo -e "#DBG_MOUNTROOT Current domain = $CURDOM\n"
# echo -e "#DBG_MOUNTROOT Default user mount root = $MOUNTROOT\n"

# Secure Realtime Text Send v2, check text integrity, then drop real time text to NFS at this last step, with endline
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
        cp $REPLX `/bin/echo -e "$opstmp/sec$REPLXNAME"`
        chmod 666 `/bin/echo -e "$opstmp/sec$REPLXNAME"`
      else
        # mv $REPLX.fail  #DBG
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
listfree()
{
    NodeLine=`/bin/cat $opstmp/secrt.sitrep.load.* 2>/dev/null | grep -v $endline | sort -n -t$'\t' -k 2 | head -n 1`
    NodeLine_Name=`echo $NodeLine | awk '{print $NR}'`
    # NodeLine_Load=`echo $NodeLine | awk '{print $3}'`
    NodeLine_lag=`expr $(date +%s) - $(echo -e "$NodeLine" | awk -F " " '{print $NF}') 2>/dev/null`
    # echo -e "\n#DBG_listfree NodeLine_Name = $NodeLine_Name\n#DBG_listfree NodeLine_Load = $NodeLine_Load"
    # echo -e "#DBG_listfree NodeLine_lag = $NodeLine_lag\n#DBG_listfree Log latency = $loglatency\n\n"
}

# Subfunction to select free node, output $FreeNode
selectfree()
{
    listfree
    # echo -e "\n#DBG_selectfree_in NodeLine_Name = $NodeLine_Name\n#DBG_selectfree_in NodeLine_tstamp = $NodeLine_tstamp\n#DBG_selectfree_in NodeLine_lag = $NodeLine_lag\n\n"
    echo -e "Refreshing node load info..\c"
    while [ ! -n "$NodeLine_lag" -o "$NodeLine_lag" -gt "$loglatency" ]
    do
        #rm -f $opstmp/secrt.sitrep.load.$NodeLine_Name
        sleep $loglatency
        listfree
        echo -n .
        # echo -e "\n#DBG_selectfree_run NodeLine_Name = $NodeLine_Name\n#DBG_selectfree_run NodeLine_tstamp = $NodeLine_tstamp\n#DBG_selectfree_run NodeLine_lag = $NodeLine_lag\n\n"
    done
    echo
    # echo -e "\n#DBG_selectfree_out NodeLine_Name = $NodeLine_Name\n#DBG_selectfree_out NodeLine_tstamp = $NodeLine_tstamp\n#DBG_selectfree_out NodeLine_lag = $NodeLine_lag\n\n"
    FreeNode=$NodeLine_Name
    echo -e "\nSelect $FreeNode as node with lowest load\n"
}

# Subfunction to check Image mount info, output $MountList family
mountlist()
{
    MountList=`cat $opstmp/secrt.sitrep.imgon.* | grep -v $endline | egrep "(\.\.|\/)$LOGNAME\.img"`
    MountList_node=`echo -e "$MountList" | head -n 1 | awk -F " " '{print $NR}'`
    MountList_img=`echo -e "$MountList" | awk -F " " '{print $2}'`
    MountList_mntp=`echo -e "$MountList" | awk -F " " '{print $3}'`
    MountList_lag=`expr $(date +%s) - $(echo -e "$MountList" | head -n 1 | awk -F " " '{print $NF}') 2>/dev/null`
    # echo -e "#DBG_mountlist MountList family:\t$MountList\n#DBG_mountlist MountList_node =\t$MountList_node"
    # echo -e "#DBG_mountlist MountList_img =\t$MountList_img\n#DBG_mountlist MountList_mntp =\t$MountList_mntp"
    # echo -e "#DBG_mountlist MountList_lag =\t$MountList_lag\n#DBG_mountlist Log latency =\t$loglatency\n\n"
}

# Subfunction to send mount ticket, mount $ImgList to $FreeNode, then get $IMGoM_MP
mountcmd()
{
  echo -e "Sending mount request to $FreeNode now...\n"
  MOUNTUSER=$LOGNAME
  MOUNTOPRNODE=$FreeNode
  # echo -e "#DBG_mountcmd_in var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"

  echo -e "#! /bin/bash\nMOUNTROOT=\"$MOUNTROOT\"\nMOUNTUSER=\"$LOGNAME\"" > $opstmp/draft.rt.ticket.geoexec

  cat >> $opstmp/draft.rt.ticket.geoexec << "MAINFUNC"
  ImgList=`/usr/bin/find  /images/vol* -type f | /bin/egrep "(\.\.|\/)$MOUNTUSER\.img$" 2>/dev/null`
  MPSORT=`for IMG in $ImgList ; do /bin/echo -en $IMG | /bin/sed 's/^\/images\/vol[0-9][0-9]\///g' | /bin/sed 's/\img$/./g' | /bin/sed 's/\.\./\//g' | /usr/bin/tac -s "/" ; /bin/echo ; done | /usr/bin/sort`
  for MP in $MPSORT
  do
    IMG=`/bin/echo $ImgList | /usr/bin/tr " " "\n" | /bin/grep $(/bin/echo -n $MP | /usr/bin/tac -s "/" | /bin/sed 's/\//../g' | /bin/sed 's/\.\.$/.img/g' | /bin/sed 's/^/\//g')`
    MTP=`/bin/echo $MOUNTROOT$MP`
    # /bin/echo IMG=$IMG MTP=$MTP >> /root/mntdbg #DBG
          if [ ! -d $MTP ]
          then
            /bin/mkdir $MTP
          fi
          /bin/mount -o loop $IMG $MTP
          /bin/sleep 0.2
          /bin/chown `id -u $MOUNTUSER`:`id -g $MOUNTUSER` $MTP
    # /bin/echo -e `id -u $MOUNTUSER`:`id -g $MOUNTUSER` $MTP>>/root/mntdbg #DBG
  done

MAINFUNC
  # echo -e "#DBG_mountcmd_run1 var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"
  echo -e "$endline $FreeNode" >> $opstmp/draft.rt.ticket.geoexec
  chmod 666 $opstmp/draft.rt.ticket.geoexec
  # echo -e "#DBG_mountcmd_run2 var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"
  mv $opstmp/draft.rt.ticket.geoexec $opstmp/secrt.ticket.geoexec.$FreeNode
  # echo -e "#DBG_mountcmd_run3 var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"
  echo -e "Image mount request sent to $FreeNode...\c"
  sleep $loglatency
  mountlist
  while [ ! -n "$MountList_node" ]
  do
      echo -n .
      mountlist
      sleep $loglatency
  done
  echo
  IMGoM_MP=$MountList_mntp
  # echo -e "#DBG_mountcmd_out IMGoM_MP:\n$IMGoM_MP"
}

# Subfunction to send ticket of kill all user threads and umount $MountList_mntp on $MountNode, and check till finished
terminator()
{
  echo -e "Sending kill and umount request to $MountNode now...\n"
  KILLUSER=$LOGNAME
  # echo -e "#DBG_terminator_in var input \n MOUNTROOT=$MOUNTROOT \n KILLUSER=$LOGNAME\n ImgList=\n$ImgList"

  echo -e "#! /bin/bash\nMOUNTROOT=\"$MOUNTROOT\"\nKILLUSER=\"$LOGNAME\"" > $opstmp/draft.rt.ticket.geoexec.$MountNode

  cat >> $opstmp/draft.rt.ticket.geoexec.$MountNode << "MAINFUNC"
  umountuser()
  {
    UmountList=`/sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}' | /bin/egrep "(\.\.|\/)$KILLUSER\.img$" 2>/dev/null`
    UMRSORT=`for IMG in $UmountList ; do /bin/echo -en $IMG | /bin/sed 's/^\/images\/vol[0-9][0-9]\///g' | /bin/sed 's/\img$/./g' | /bin/sed 's/\.\./\//g' | /usr/bin/tac -s "/" ; /bin/echo ; done | /usr/bin/sort -r`
    for UM in $UMRSORT
    do
      UMP=`/bin/echo $MOUNTROOT$UM`
      /bin/umount $UMP
      /bin/sleep 0.2
    done
  }

  /usr/bin/pkill -u $KILLUSER
  killlist=`/bin/ps -aux | /bin/grep $KILLUSER | /bin/grep -v grep`
  while [ -n "$killlist" ]
  do
    /usr/bin/pkill -u $KILLUSER
    /bin/sleep 0.1
    killlist=`/bin/ps -aux | /bin/grep $KILLUSER | /bin/grep -v grep`
  done

  umountuser
  UmountList=`/sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}' | /bin/egrep "(\.\.|\/)$KILLUSER\.img$" 2>/dev/null`
  while [ -n "$UmountList" ]
  do
    umountuser
    /bin/sleep 1
    UmountList=`/sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}' | /bin/egrep "(\.\.|\/)$KILLUSER\.img$" 2>/dev/null`
  done
MAINFUNC

  echo -e "$endline $MountNode" >> $opstmp/draft.rt.ticket.geoexec.$MountNode
  chmod 666 $opstmp/draft.rt.ticket.geoexec.$MountNode
  mv $opstmp/draft.rt.ticket.geoexec.$MountNode $opstmp/secrt.ticket.geoexec.$MountNode
  echo -e "Kill request sent...\c"
  sleep $loglatency
  mountlist
  while [ -n "$MountList_node" ]
  do
      echo -n .
      mountlist
      sleep $loglatency
  done
  echo -e "\nSeems you are now terminated on $MountNode\n"
  MountNode=""
  # echo -e "#DBG_terminator_out MountList =\n$MountList\nMountNode unset as \"$MountNode\""
}

# Secure SSH redirector, the Last subfunction checking $ImgList and $LaunchNode, then patch user through
# !!!Unfinished!!! Still need the mount/unmount function, based on geoexec
secpatch()
{
    if [ ! -n "$ImgList" -o ! -n "$LaunchNode" -o ! -n "$IMGoM_MP" ]
    	then
        echo -e "\nLaunch failed, kicking you out now... Please try connect again or contact system admin with below debug info:\n"
    		echo -e "\n#DBG_secpatch_f Missing launch factor, current info:\n LaunchNode = $LaunchNode\n ImgList = \n$ImgList\n IMGoM_MP = $IMGoM_MP\n"
        rm -f $opstmp/launchlock.$LOGNAME
    		exit
    else
    	# echo -e "\n#DBG_secpatch_t Got UID: $LOGNAME\n your image:\n$ImgList\n mounted on:\n $IMGoM_MP\n of $LaunchNode\n"
    	echo -e "\nPatching you through now...\n"
      echo -e "Your workspace image is mounted on $MOUNTROOT$LOGNAME/\n"
    	# echo -e "#DBG_secpatch_t Congrats!!! All good !!! Drill interrupted!!!\n\nPress any key to exit" && read KEY && rm -f $opstmp/launchlock.$LOGNAME && exit
    	rm -f $opstmp/launchlock.$LOGNAME
      exec /usr/bin/ssh $LOGNAME@$LaunchNode
    fi
}

# Main0 User launch lock
echo -e "#DBG_Main0_in lockpath=$opstmp/launchlock.$LOGNAME"
lockpath=$opstmp/launchlock.$LOGNAME
# echo lockpath=$lockpath #DBG
# ls -lah $lockpath #DBG
# cat $lockpath #DBG
if [ ! -f "$lockpath" ]
	then
		echo -e "\nSpooling login session on `hostname` now...\n"
		echo `hostname` > $opstmp/launchlock.$LOGNAME
		chmod 666 $opstmp/launchlock.$LOGNAME
	else
		echo -e "\nYou already have a launch instance record on launch server: \c"
		cat $lockpath
		echo -e "\nThis might caused by your last launch interruption."
		echo -e "If this is your ONLY current launch instance, you can override the launch.\n"
		while true
    do
		read -p "Override to launch from here? (Y/N)" USER_OPS
			case $USER_OPS in
        			Y|y|YES|Yes|yes)
                			echo -e "\nProceeding to your launch now...\n"
                			break
					;;
        			N|n|NO|No|no)
                			echo -e "\nYou've been dropped out by launch locker, please contact admins if need help.\n"
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
# echo -e "#DBG_Main1   First Check, ImgList =\n$ImgList"
if [ ! -n "$ImgList" ]
then
    sleep $loglatency
    listimg
    # echo -e "#DBG_Main1   Double check, ImgList =\n$ImgList"
    if [ ! -n "$ImgList" ]
    then
        sleep $loglatency
        listimg
        # echo -e "#DBG_Main1   Treble Check, ImgList =\n$ImgList"
        if [ ! -n "$ImgList" ]
        then
        	echo -e "$LOGNAME" > $opstmp/secrt.ticket.mkimg.$LOGNAME
        	chmod 666 $opstmp/secrt.ticket.mkimg.$LOGNAME
        	# echo -e "#DBG_Main1    Pre-Create, ImgList = \n$ImgList\n"
        	echo -e "\nCreating new image for you, please wait ..\c"
        	while [ ! -n "$ImgList" ]
        		do
        			echo -ne "."
        			sleep 1
        			listimg
              # echo -e "#DBG_Main1   Loop Check, ImgList =\n$ImgList"
        		done
        	echo
        fi
    fi
fi
echo -e "\nGot your image "$ImgList"\n"

# Got $LOGNAME and $ImgList above, Needs $LaunchNode and $IMGoM_MP

# Main2_a, check Image mount status, if not mount then $LaunchNode=$FreeNode
# echo -e "#DBG_Main2_run_in MountList = $MountList"
mountlist
# echo -e "#DBG_Main2_run_1 MountList = $MountList"
# echo -e "#DBG_Main2_run_1 MountList family:\t$MountList\n#DBG_Main2_run_1 MountList_node =\t$MountList_node"
# echo -e "#DBG_Main2_run_1 MountList_img =\t$MountList_img\n#DBG_Main2_run_1 MountList_mntp =\t$MountList_mntp"
# echo -e "#DBG_Main2_run_1 MountList_lag =\t$MountList_lag\n#DBG_Main2_run_1 Log latency =\t$loglatency\n\n"
if [ ! -n "$MountList_node" ]
then
    echo -e "Did not find your image mounted on any node\n"
    selectfree
    mountcmd
    LaunchNode=$FreeNode
    # echo -e "#DBG_Main2_a_run_2 LaunchNode=$LaunchNode\n MountList = $MountList"
    secpatch
# Main2_b, check Image mount status, if mount then MountNode=$MountList_node
elif [ "$loglatency" -lt "$MountList_lag" ]
then
  # echo -e "#DBG_Main2_b_in MountList = $MountList"
  rm -f $opstmp/secrt.sitrep.imgon.$MountList_node 2>/dev/null
	echo -e "Image mount record overtime > $loglatency seconds!!! Refreshing ..\c"
  sleep $loglatency
  mountlist
  #while [ "$loglatency" -lt "$MountList_lag" ]
  while [ ! -n "$MountList_lag" ]
  do
    # rm -f $opstmp/secrt.sitrep.imgon.$MountList_node 2>/dev/null
    sleep $loglatency
    mountlist
    echo -n .
  done
  echo
fi
MountNode=$MountList_node
IMGoM_MP=$MountList_mntp
echo -e "\nFound your image mounted on:\n$MountList_mntp\n of $MountNode\n"

# Check CPU usage of $MountNode, if over 80% ask if change node, else patch through
while [ ! -n "$MountNodeLoad" ]
do
  MountNodeLoad=`cat $opstmp/secrt.sitrep.load.$MountNode | grep -v $endline | awk '{print $3}'`
  sleep $loglatency
done
# echo -e "#DBG_checkload MountNodeLoad = $MountNodeLoad %\n"

if [ "$MountNodeLoad" -gt 80 ]
then
  echo -e "Your current node is under heavy load, switch node? Y/N\n"
  while true
  do
  read USER_CHO
    case $USER_CHO in
    Y|y|YES|Yes|yes)
      echo -e "!!! Switching node WILL KILL ALL OF YOU LIVE SESSIONS !!!\n"
      echo -e "Input uppercase YES to confirm, or anything else to quit.\n"
      read USER_CFM
      if [ "$USER_CFM" == "YES" ]
      then
        terminator
        selectfree
        mountcmd
        LaunchNode=$FreeNode
        secpatch
      else
        rm -f $opstmp/launchlock.$LOGNAME
        echo -e "Dropping you out now, please try connect again."
        exit
      fi
      ;;
    N|n|NO|No|no)
      echo -e "\nPatching you through to $MountNode under heavy load now, you can always switch node with new logins.\n"
      LaunchNode=$MountNode
      secpatch
      ;;
    *)
      echo -e "\nInvalid choice, please tell me Yes or No.\n"
      ;;
    esac
  done
else
  echo -e "Node not busy...\n"
  LaunchNode=$MountNode
  secpatch
fi
