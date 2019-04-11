#! /bin/bash
COLUMNS=512
endline="###---###---###---###---###"
loglatency=3
opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
dskinitsz=500
source $lococlu/lcc.conf
# /bin/echo -e "#DBG_lcc.conf \nCOLUMNS=$COLUMNS\nendline=$endline\nopstmp=$opstmp\nlococlu=$lococlu\ndskinitsz=$dskinitsz\n#\n" > /root/DBG_lcc.conf
# /bin/cat $lococlu/lcc.conf >> /root/DBG_lcc.conf

# /bin/echo -e "#DBG You're been hosted by the receptionist\n"
# /bin/echo -e "#DBG Your login UID is $LOGNAME\n"

# Define the globle IMGoN mount root $MOUNTROOT
CURDOM=`/bin/hostname -d`
while [ ! -n "$MOUNTROOT" ];
do
  case $CURDOM in
    28.sap|28.SAP)
      MOUNTROOT="/home/28/"
      break
      ;;
    ap.qualcomm.com|AP.QUALCOMM.COM|qualcomm.com|QUALCOMM.COM)
      MOUNTROOT="/local/mnt/workspace/"
      # /bin/cat /var/adm/gv/user > $lococlu/user.conf
      break
      ;;
    *)
    /bin/echo -e "\nUnknown domain, please choose define the image mount root:\n"
    read MOUNTROOT
    break
    ;;
  esac
done
MOUNTROOT=`/bin/echo $MOUNTROOT | /bin/sed '/\/$/!  s/^.*$/&\//'`
# /bin/echo -e "#DBG_MOUNTROOT Current domain = $CURDOM\n"
# /bin/echo -e "#DBG_MOUNTROOT Default user mount root = $MOUNTROOT\n"

# lccmain bypass user list
Whitelist=`cat $lococlu/backstage.conf`
UserChecker=`/bin/echo $Whitelist | grep $LOGNAME`
if [ -n "$UserChecker" ]
then
    /bin/echo -e "Aha! White list user! LCC-Main bypassed to head back stage!"
    exec /bin/bash
fi


# Secure Realtime Text Send v2, check text integrity, then drop real time text to NFS at this last step, with endline
# /bin/sed -i '$d' $REPLX # To cat last line, on receive side
secrtsend()
{
    for REPLX in `/bin/ls /var/log/rt.*`
    do
      CheckLineL1=`/usr/bin/tac $REPLX | /bin/sed -n '1p'`
      CheckLineL2=`/usr/bin/tac $REPLX | /bin/sed -n '2p'`
      if [ "$CheckLineL1"  == "$endline `/bin/hostname`" -a "$CheckLineL2"  != "$endline `/bin/hostname`" ]
      then
        REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
        /bin/cp $REPLX `/bin/echo -e "$opstmp/sec$REPLXNAME"`
        chmod 666 `/bin/echo -e "$opstmp/sec$REPLXNAME"`
      else
        # mv $REPLX.fail  #DBG
        /bin/rm $REPLX
      fi
    done
}


# Subfunction to list all user images, output $ImgList if found
lsallimg()
{
    ImgList=`/usr/bin/find  /images/vol*/*.img -type f | /bin/egrep "(\.\.|\/)$LOGNAME\.img$" 2>/dev/null`
}

# Subfunction to list user root workspace image, output $RootImg if found
lsrootimg()
{
    RootImg=`/usr/bin/find  /images/vol*/*.img -type f | /bin/egrep "\/$LOGNAME\.img$" 2>/dev/null`
}

# Subfunction to get node in lowest load, output $NodeLine family
listfree()
{
    NodeLine=`/bin/cat $opstmp/secrt.sitrep.load.* 2>/dev/null | /bin/grep -v $endline | /usr/bin/sort -n -t$'\t' -k 2 | /usr/bin/head -n 1`
    NodeLine_Name=`/bin/echo $NodeLine | /usr/bin/awk '{print $NR}'`
    # NodeLine_Load=`/bin/echo $NodeLine | /usr/bin/awk '{print $3}'`
    NodeLine_lag=`/usr/bin/expr $(/bin/date +%s) - $(/bin/echo -e "$NodeLine" | /usr/bin/awk -F " " '{print $NF}') 2>/dev/null`
    # /bin/echo -e "\n#DBG_listfree NodeLine_Name = $NodeLine_Name\n#DBG_listfree NodeLine_Load = $NodeLine_Load"
    # /bin/echo -e "#DBG_listfree NodeLine_lag = $NodeLine_lag\n#DBG_listfree Log latency = $loglatency\n\n"
}

# Subfunction to select free node, output $FreeNode
selectfree()
{
    listfree
    # /bin/echo -e "\n#DBG_selectfree_in NodeLine_Name = $NodeLine_Name\n#DBG_selectfree_in NodeLine_tstamp = $NodeLine_tstamp\n#DBG_selectfree_in NodeLine_lag = $NodeLine_lag\n\n"
    /bin/echo -e "Refreshing node load info..\c"
    while [ ! -n "$NodeLine_lag" -o "$NodeLine_lag" -gt "$loglatency" ]
    do
        # /bin/rm -f $opstmp/secrt.sitrep.load.$NodeLine_Name #Drop1
        /bin/rm -f $opstmp/*.$NodeLine_Name #Drop1*
        /bin/sleep $loglatency
        listfree
        /bin/echo -n .
        # /bin/echo -e "\n#DBG_selectfree_run NodeLine_Name = $NodeLine_Name\n#DBG_selectfree_run NodeLine_tstamp = $NodeLine_tstamp\n#DBG_selectfree_run NodeLine_lag = $NodeLine_lag\n\n"
    done
    /bin/echo
    # /bin/echo -e "\n#DBG_selectfree_out NodeLine_Name = $NodeLine_Name\n#DBG_selectfree_out NodeLine_tstamp = $NodeLine_tstamp\n#DBG_selectfree_out NodeLine_lag = $NodeLine_lag\n\n"
    FreeNode=$NodeLine_Name
    /bin/echo -e "\nSelect $FreeNode as node with lowest load\n"
}

# Subfunction to check Image mount info, output $MountList family
mountlist()
{
    MountList=`/bin/cat $opstmp/secrt.sitrep.imgon.* | /bin/grep -v $endline | /bin/egrep "(\.\.|\/)$LOGNAME\.img"`
    MountList_node=`/bin/echo -e "$MountList" | /usr/bin/head -n 1 | /usr/bin/awk -F " " '{print $NR}'`
    MountList_img=`/bin/echo -e "$MountList" | /usr/bin/awk -F " " '{print $2}'`
    MountList_mntp=`/bin/echo -e "$MountList" | /usr/bin/awk -F " " '{print $3}'`
    MountList_lag=`/usr/bin/expr $(/bin/date +%s) - $(/bin/echo -e "$MountList" | /usr/bin/head -n 1 | /usr/bin/awk -F " " '{print $NF}') 2>/dev/null`
    # /bin/echo -e "#DBG_mountlist MountList family:\t$MountList\n#DBG_mountlist MountList_node =\t$MountList_node"
    # /bin/echo -e "#DBG_mountlist MountList_img =\t$MountList_img\n#DBG_mountlist MountList_mntp =\t$MountList_mntp"
    # /bin/echo -e "#DBG_mountlist MountList_lag =\t$MountList_lag\n#DBG_mountlist Log latency =\t$loglatency\n\n"
}

# Subfunction to send make image ticket, $FreeNode make user image from diskinfant, then get $ImgList
mkrootimg()
{
  /bin/echo -e "Sending image make request to $FreeNode now...\n"
  MKIMGUSER=$LOGNAME
  MKIMGOPRNODE=$FreeNode
  # /bin/echo -e "#DBG_mkrootimg_in var input \n  MKIMGUSER=$MKIMGUSER\n FreeNode=$FreeNode\n MKIMGOPRNODE=$MKIMGOPRNODE\n dskinitsz=$dskinitsz"

  /bin/echo -e "#! /bin/bash\nMKIMGUSER=\"$MKIMGUSER\"\ndskinitsz=\"$dskinitsz\"" > $opstmp/draft.rt.ticket.geoexec

  /bin/cat >> $opstmp/draft.rt.ticket.geoexec << "MAINFUNC"
  # Ticket of make user image

  # Subfunc of make disk infant, now for /images/vol**
  mkdskinfant()
  {
      for volpath in `/bin/ls -d /images/vol*`
      do
          fmtvolpath=`/bin/echo $volpath | /usr/bin/awk -F ":" '{print $1}'`
          if [ ! -f $fmtvolpath/diskinfant ]
      	then
      		/bin/dd if=/dev/zero of=$fmtvolpath/diskinfant bs=1G count=0 seek="$dskinitsz"
      		/bin/chmod 666 $fmtvolpath/diskinfant
      		/sbin/mkfs.ext4 -Fq $fmtvolpath/diskinfant "$dskinitsz"G
          # /bin/echo -e "#DBG_mkdskinfant dskinitsz=$dskinitsz" > /root/DBG_mkdskinfant
      		/bin/sleep 1
          fi
      done
  }

  # Subfunc of sort image volumes in quota usage, and output $SelVol
  selvol()
  {
    SelVol=$(
    for imgvol in `/bin/ls /images | /bin/grep -v vol00`
    do
            /bin/echo -ne "/images/$imgvol \t"
            quotausage=`/bin/ls -l --block-size=g /images/$imgvol |  /usr/bin/awk '{ total += $5; print }; END { print total}' | /usr/bin/tail -n 1`
            /bin/echo -ne "$quotausage \t"
            volsize=`/bin/df -BG /images/$imgvol | /usr/bin/tail -n 1 | /usr/bin/awk '{print $2}' | /bin/sed 's/.$//'`
            /bin/echo -ne "$volsize \t"
            quotaperc=`/bin/echo -e " 100 * $quotausage / $volsize " | /usr/bin/bc`
            /bin/echo -e $quotaperc%
    done | /usr/bin/sort -n -k4 | /usr/bin/head -n 1 | /usr/bin/awk '{print $1}'
    )
    /bin/echo SelVol=$SelVol
  }

  # Make root image main functions below
  mkdskinfant
  chkrootimg=`/usr/bin/find /images/vol*/*.img -type f | /bin/egrep "\/$MKIMGUSER\.img$" 2>/dev/null`
  if [ -n "$chkrootimg" ]
  then
    /bin/echo -e "Got mkrootimg conflict for $MKIMGUSER, image file found at $chkrootimg, time `/bin/date +%Y-%m%d-%H%M-%S`" > /var/log/fail.mkrootimg
  else
    selvol
    /bin/mv $SelVol/diskinfant $SelVol/$MKIMGUSER.img
  fi
  mkdskinfant

MAINFUNC
  /bin/echo -e "$endline $FreeNode" >> $opstmp/draft.rt.ticket.geoexec
  chmod 666 $opstmp/draft.rt.ticket.geoexec
  mv $opstmp/draft.rt.ticket.geoexec $opstmp/secrt.ticket.geoexec.$FreeNode
  /bin/echo -e "Creating image on $FreeNode...\c"
  /bin/sleep $loglatency
  lsrootimg
  while [ ! -n "$RootImg" ]
  do
      /bin/echo -n .
      lsrootimg
      /bin/sleep $loglatency
  done
  /bin/echo

}

# Subfunction to check and create user root workspace image if does not exist, output $ImgList when finished.
chkusrimg()
{
  /bin/echo -e "Looking for your root workspace image...\n"
  lsrootimg
  # /bin/echo -e "#DBG_Main1   First Check, ImgList =\n$ImgList"
  if [ ! -n "$RootImg" ]
  then
      /bin/sleep $loglatency
      lsrootimg
      # /bin/echo -e "#DBG_Main1   Double check, ImgList =\n$ImgList"
      if [ ! -n "$RootImg" ]
      then
          /bin/sleep $loglatency
          lsrootimg
          # /bin/echo -e "#DBG_Main1   Treble Check, ImgList =\n$ImgList"
          if [ ! -n "$RootImg" ]
          then
            mkrootimg
            /bin/echo -e "\nFetching your new image..\c"
            while [ ! -n "$RootImg" ]
              do
                /bin/echo -ne "."
                /bin/sleep 1
                lsrootimg
                # /bin/echo -e "#DBG_Main1   Loop Check, ImgList =\n$ImgList"
              done
            /bin/echo
          fi
      fi
  fi
  lsallimg
  /bin/echo -e "\nGot your image "$ImgList"\n"
}

# Subfunction to send mount ticket, mount $ImgList to $FreeNode, then get $IMGoN_MP
mountcmd()
{
  /bin/echo -e "Sending mount request to $FreeNode now...\n"
  MOUNTUSER=$LOGNAME
  MOUNTOPRNODE=$FreeNode
  # /bin/echo -e "#DBG_mountcmd_in var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$MOUNTUSER\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"

  /bin/echo -e "#! /bin/bash\nMOUNTROOT=\"$MOUNTROOT\"\nMOUNTUSER=\"$LOGNAME\"" > $opstmp/draft.rt.ticket.geoexec

  /bin/cat >> $opstmp/draft.rt.ticket.geoexec << "MAINFUNC"
  # Ticket of mount user image
  ImgList=`/usr/bin/find /images/vol*/*.img -type f | /bin/egrep "(\.\.|\/)$MOUNTUSER\.img$" 2>/dev/null`
  MPSORT=`for IMG in $ImgList ; do /bin/echo -en $IMG | /bin/sed 's/^\/images\/vol[0-9][0-9]\///g' | /bin/sed 's/\img$/./g' | /bin/sed 's/\.\./\//g' | /usr/bin/tac -s "/" ; /bin/echo ; done | /usr/bin/sort`
  for MP in $MPSORT
  do
    IMG=`/bin/echo $ImgList | /usr/bin/tr " " "\n" | /bin/grep $(/bin/echo -n $MP | /usr/bin/tac -s "/" | /bin/sed 's/\//../g' | /bin/sed 's/\.\.$/.img/g' | /bin/sed 's/^/\//g')`
    MTP=`/bin/echo $MOUNTROOT$MP`
    # /bin/echo IMG=$IMG MTP=$MTP >> /root/mntdbg #DBG
          if [ ! -d $MTP ]
          then
            /bin/mkdir -p $MTP
          fi
          /bin/mount -o loop $IMG $MTP 2>/dev/null
          /bin/sleep 0.2
          /bin/chown `id -u $MOUNTUSER`:`id -g $MOUNTUSER` $MTP
    # /bin/echo -e `id -u $MOUNTUSER`:`id -g $MOUNTUSER` $MTP>>/root/mntdbg #DBG
  done

MAINFUNC
  # /bin/echo -e "#DBG_mountcmd_run1 var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"
  /bin/echo -e "$endline $FreeNode" >> $opstmp/draft.rt.ticket.geoexec
  chmod 666 $opstmp/draft.rt.ticket.geoexec
  # /bin/echo -e "#DBG_mountcmd_run2 var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"
  mv $opstmp/draft.rt.ticket.geoexec $opstmp/secrt.ticket.geoexec.$FreeNode
  # /bin/echo -e "#DBG_mountcmd_run3 var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"
  /bin/echo -e "Mounting images on $FreeNode...\c"
  /bin/sleep $loglatency
  mountlist
  while [ ! -n "$MountList_node" ]
  do
      /bin/echo -n .
      mountlist
      /bin/sleep $loglatency
  done
  /bin/echo
  IMGoN_MP=$MountList_mntp
  # /bin/echo -e "#DBG_mountcmd_out IMGoN_MP:\n$IMGoN_MP"
}

# Subfunction to send ticket of kill all user threads and umount $MountList_mntp on $MountNode, and check till finished
terminator()
{
  /bin/echo -e "Sending kill and umount request to $MountNode now...\n"
  KILLUSER=$LOGNAME
  # /bin/echo -e "#DBG_terminator_in var input \n MOUNTROOT=$MOUNTROOT \n KILLUSER=$LOGNAME\n ImgList=\n$ImgList"

  /bin/echo -e "#! /bin/bash\nMOUNTROOT=\"$MOUNTROOT\"\nKILLUSER=\"$LOGNAME\"" > $opstmp/draft.rt.ticket.geoexec.$MountNode

  /bin/cat >> $opstmp/draft.rt.ticket.geoexec.$MountNode << "MAINFUNC"
  # Ticket of terminate user session and umount user images
  umountuser()
  {
    UmountList=`/sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}' | /bin/egrep "(\.\.|\/)$KILLUSER\.img$" 2>/dev/null`
    UMRSORT=`for IMG in $UmountList ; do /bin/echo -en $IMG | /bin/sed 's/^\/images\/vol[0-9][0-9]\///g' | /bin/sed 's/\img$/./g' | /bin/sed 's/\.\./\//g' | /usr/bin/tac -s "/" ; /bin/echo ; done | /usr/bin/sort -r`
    for UM in $UMRSORT
    do
      UMP=`/bin/echo $MOUNTROOT$UM`
      /bin/umount -l $UMP
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

  service smbd restart
  service nmbd restart
  umountuser
  UmountList=`/sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}' | /bin/egrep "(\.\.|\/)$KILLUSER\.img$" 2>/dev/null`
  while [ -n "$UmountList" ]
  do
    umountuser
    /bin/sleep 1
    UmountList=`/sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}' | /bin/egrep "(\.\.|\/)$KILLUSER\.img$" 2>/dev/null`
  done
  service smbd restart
  service nmbd restart
MAINFUNC

  /bin/echo -e "$endline $MountNode" >> $opstmp/draft.rt.ticket.geoexec.$MountNode
  chmod 666 $opstmp/draft.rt.ticket.geoexec.$MountNode
  mv $opstmp/draft.rt.ticket.geoexec.$MountNode $opstmp/secrt.ticket.geoexec.$MountNode
  /bin/echo -e "Kill request sent...\c"
  /bin/sleep $loglatency
  mountlist
  while [ -n "$MountList_node" ]
  do
      /bin/echo -n .
      mountlist
      /bin/sleep $loglatency
  done
  /bin/echo -e "\nSeems you are now terminated on $MountNode\n"
  MountNode=""
  # /bin/echo -e "#DBG_terminator_out MountList =\n$MountList\nMountNode unset as \"$MountNode\""
}

# Secure SSH redirector, the Last subfunction checking $ImgList and $LaunchNode, then patch user through
# !!!Unfinished!!! Still need the mount/unmount function, based on geoexec
secpatch()
{
    if [ ! -n "$ImgList" -o ! -n "$LaunchNode" -o ! -n "$IMGoN_MP" ]
    	then
        /bin/echo -e "\nLaunch failed, kicking you out now... Please try connect again or contact system admin with below debug info:\n"
    		echo -e "\n#DBG_secpatch_f Missing launch factor, current info:\n LaunchNode = $LaunchNode\n ImgList = \n$ImgList\n IMGoN_MP = $IMGoN_MP\n"
        /bin/rm -f $opstmp/launchlock.$LOGNAME
    		exit
    else
    	# /bin/echo -e "\n#DBG_secpatch_t Got UID: $LOGNAME\n your image:\n$ImgList\n mounted on:\n $IMGoN_MP\n of $LaunchNode\n"
    	echo -e "\nPatching you through now...\n"
      /bin/echo -e "Your workspace is now at $MOUNTROOT$LOGNAME/\n"
    	# /bin/echo -e "#DBG_secpatch_t Congrats!!! All good !!! Drill interrupted!!!\n\nPress any key to exit" && read KEY && /bin/rm -f $opstmp/launchlock.$LOGNAME && exit
    	rm -f $opstmp/launchlock.$LOGNAME
      exec /usr/bin/ssh $LOGNAME@$LaunchNode
    fi
}

# Main0 User launch lock
# /bin/echo -e "#DBG_Main0_in lockpath=$opstmp/launchlock.$LOGNAME"
lockpath=$opstmp/launchlock.$LOGNAME
# /bin/echo lockpath=$lockpath #DBG
# ls -lah $lockpath #DBG
# /bin/cat $lockpath #DBG
if [ ! -f "$lockpath" ]
	then
		echo -e "\nSpooling login session on `/bin/hostname` now...\n"
		echo `/bin/hostname` > $opstmp/launchlock.$LOGNAME
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


# Main1, check Image mount status, if mount then $LaunchNode=$MountNode, else $LaunchNode=$FreeNode

mountlist
if [ ! -n "$MountList_node" ]
then
    /bin/echo -e "Did not find your image mounted on any node...\n"
    selectfree
    chkusrimg
    mountcmd
    LaunchNode=$FreeNode
    # /bin/echo -e "#DBG_Main1_a_run_2 LaunchNode=$LaunchNode\n MountList = $MountList"
    secpatch
elif [ "$loglatency" -lt "$MountList_lag" ]
then
  # /bin/echo -e "#DBG_Main1_b_in MountList = $MountList"
    # /bin/rm -f $opstmp/secrt.sitrep.imgon.$MountList_node 2>/dev/null #Drop0
    /bin/rm -f $opstmp/*.$MountList_node 2>/dev/null #Drop0*
	echo -e "Image mount record overtime > $loglatency seconds!!! Refreshing ..\c"
  /bin/sleep $loglatency
  mountlist
  #while [ "$loglatency" -lt "$MountList_lag" ]
  while [ ! -n "$MountList_lag" ]
  do
    # /bin/rm -f $opstmp/secrt.sitrep.imgon.$MountList_node 2>/dev/null #Drop2
    /bin/rm -f $opstmp/*.$MountList_node 2>/dev/null #Drop2*
    /bin/sleep $loglatency
    mountlist
    /bin/echo -n .
  done
  /bin/echo
fi
MountNode=$MountList_node
IMGoN_MP=$MountList_mntp
lsallimg
echo -e "\nFound your image:\n $ImgList\nmounted on:\n $MountList_mntp\nof $MountNode\n"

#Mount integrity check
ImgCount=`/bin/echo $ImgList | /bin/grep -o "/images/vol" | wc -l`
MntCount=`/bin/echo $MountList_mntp | /bin/grep -o "/local/mnt/workspace" | wc -l`
if  [ "$ImgCount" -gt "$MntCount" ]
    then
    FreeNode=$MountNode
    /bin/echo -e "Found your new image, mounting to $MountNode now...\n"
    mountcmd

fi

# Check /bin/cpU usage of $MountNode, if over 80% ask if change node, else patch through
while [ ! -n "$MountNodeLoad" ]
do
  MountNodeLoad=`/bin/cat $opstmp/secrt.sitrep.load.$MountNode | /bin/grep -v $endline | /usr/bin/awk '{print $3}'`
  /bin/sleep $loglatency
done
# /bin/echo -e "#DBG_checkload MountNodeLoad = $MountNodeLoad %\n"

if [ "$MountNodeLoad" -gt 150 ]
then
  /bin/echo -e "Your current node is under heavy load, switch node? Y/N\n"
  while true
  do
  read USER_CHO
    case $USER_CHO in
    Y|y|YES|Yes|yes)
      /bin/echo -e "!!! Switching node WILL KILL ALL OF YOU CURRENT SESSIONS !!!\n"
      /bin/echo -e "Input uppercase YES to confirm, or anything else to quit.\n"
      read USER_CFM
      if [ "$USER_CFM" == "YES" ]
      then
        terminator
        selectfree
        mountcmd
        LaunchNode=$FreeNode
        secpatch
      else
        /bin/rm -f $opstmp/launchlock.$LOGNAME
        /bin/echo -e "Dropping you out now, please try connect again."
        exit
      fi
      ;;
    N|n|NO|No|no)
      /bin/echo -e "\nPatching you through to $MountNode under heavy load now, you can always switch node with new logins.\n"
      LaunchNode=$MountNode
      secpatch
      ;;
    *)
      /bin/echo -e "\nInvalid choice, please tell me Yes or No.\n"
      ;;
    esac
  done
else
  /bin/echo -e "Node not busy...\n"
  LaunchNode=$MountNode
  secpatch
fi
