#! /bin/bash
# LCC main function, works only when users dialing in.

export COLUMNS=512
endline="###---###---###---###---###"
loglatency=3
opstmp=/LCC/opstmp
lococlu=/LCC/bin
dskinitsz=500
source /LCC/bin/lcc.conf
# /bin/echo -e "#DBG_lcc.conf \nCOLUMNS=$COLUMNS\nendline=$endline\nopstmp=$opstmp\nlococlu=$lococlu\ndskinitsz=$dskinitsz\n#\n" > /root/DBG_lcc.conf
# /bin/cat /LCC/bin/lcc.conf >> /root/DBG_lcc.conf

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
Whitelist=`/bin/cat $lococlu/backstage.conf`
UserChecker=`/bin/echo $Whitelist | /bin/grep $LOGNAME`
if [ -n "$UserChecker" ]
then
	/bin/echo -e "Aha! White list admin! LCC-Main bypassed to back stage of the head now!"
	exec /bin/bash
fi


# Secure Realtime Text Copy v4, execbd variant with target node $execnode signature in tickets' name and checklines
# Added $LOGNAME check to avoid user ops conflict
# /bin/sed -i '$d' $REPLX # To cat last line, on receive side
secrtsend_execbd()
{
for REPLX in `/bin/ls /tmp/rt.geoexec.$LOGNAME.* 2>/dev/null`
do
	CheckLineL1=`/usr/bin/tail -n 1 $REPLX`
	CheckLineL2=`/usr/bin/tail -n 2 $REPLX | /usr/bin/head -n 1`
	if [ "$CheckLineL1" == "$endline $execnode" -a "$CheckLineL2" != "$endline $execnode" ]
	then
		REPLXNAME=`/bin/echo $REPLX | /bin/sed 's/^\/tmp\///g'`
		/bin/mv $REPLX $opstmp/sec$REPLXNAME
		/bin/chmod 666 $opstmp/sec$REPLXNAME
	else
		# /bin/mv $REPLX.fail  #DBG
		/bin/rm $REPLX
	fi
done
}


# Subfunction to get node in lowest load, output $NodeLine family
listfree()
{
	NodeLine=`/bin/cat $opstmp/secrt.sitrep.* 2>/dev/null | /bin/grep "log=load" | /usr/bin/sort -n -t$'\t' -k 3 | /usr/bin/head -n 1`
	NodeLine_Name=`/bin/echo $NodeLine | /usr/bin/awk '{print $NR}'`
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
	MountList=`/bin/cat $opstmp/secrt.sitrep.* 2>/dev/null | /bin/grep "log=imgon" | /bin/egrep "(\.\.|\/)$LOGNAME\.img"`
	if [ -n "$MountList" ]
	then
		MountList_node=`/bin/echo -e "$MountList" | /usr/bin/head -n 1 | /usr/bin/awk '{print $1}'`
		MountList_img=`/bin/echo -e "$MountList" | /usr/bin/awk '{print $3}'`
		MountList_mntp=`/bin/echo -e "$MountList" | /usr/bin/awk '{print $4}'`
		MountList_lag=`/bin/echo $(( $(/bin/date +%s) - $(/bin/echo -e "$MountList" | /bin/sed '2,$d; s/^.*\t//g') )) 2>/dev/null`
	else
		unset MountList_node
		unset MountList_img
		unset MountList_mntp
		unset MountList_lag
	fi
	# $lococlu/tools/UCIL.sh &
	# /bin/echo -e "#DBG_mountlist MountList family:\n$MountList\n#DBG_mountlist MountList_node:\n$MountList_node"
	# /bin/echo -e "#DBG_mountlist MountList_img:\n$MountList_img\n#DBG_mountlist MountList_mntp:\n$MountList_mntp"
	# /bin/echo -e "#DBG_mountlist MountList_lag =\t$MountList_lag\n#DBG_mountlist Log latency =\t$loglatency\n\n"
}

# Subfunction to send make image ticket, $FreeNode make user image from diskinfant, then get $ImgList
mkrootimg()
{
	selectfree
	/bin/echo -e "Sending image make request to $FreeNode now...\n"
	MKIMGUSER=$LOGNAME
	MKIMGOPRNODE=$FreeNode
	execnode=$MKIMGOPRNODE
	# /bin/echo -e "#DBG_mkrootimg_in var input \n  MKIMGUSER=$MKIMGUSER\n FreeNode=$FreeNode\n MKIMGOPRNODE=$MKIMGOPRNODE\n dskinitsz=$dskinitsz"

	/bin/echo -e "#! /bin/bash\nsource /etc/environment\nsource /LCC/bin/lcc.conf\nMKIMGUSER=\"$MKIMGUSER\"\ndskinitsz=\"$dskinitsz\"" > /tmp/draft.rt.geoexec.$LOGNAME.$MKIMGOPRNODE

	/bin/cat >> /tmp/draft.rt.geoexec.$LOGNAME.$MKIMGOPRNODE << "MAINFUNC"
	# Ticket of make user image
	# Subfunc of make disk infant, now for /images/vol**
	mkdskinfant()
	{
		for volpath in `/bin/ls -d /images/vol* | /bin/grep -v vol00`
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
			quotausage=`/bin/ls -l --block-size=g /images/$imgvol | /usr/bin/awk '{ total += $5; print }; END { print total}' | /usr/bin/tail -n 1`
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
	chkrootimg=`/bin/ls /images/vol*/*.img | /bin/egrep "\/$MKIMGUSER\.img$" 2>/dev/null`
	if [ -n "$chkrootimg" ]
	then
	/bin/echo -e "Got mkrootimg conflict for $MKIMGUSER, image file found at $chkrootimg, time `/bin/date +%Y-%m%d-%H%M-%S`" >> /var/log/fail.mkrootimg
	else
	selvol
	/bin/mv $SelVol/diskinfant $SelVol/$MKIMGUSER.img
	fi
	mkdskinfant
MAINFUNC
	/bin/echo -e "$endline $FreeNode" >> /tmp/draft.rt.geoexec.$LOGNAME.$MKIMGOPRNODE
	/bin/mv /tmp/draft.rt.geoexec.$LOGNAME.$MKIMGOPRNODE /tmp/rt.geoexec.$LOGNAME.$MKIMGOPRNODE
	secrtsend_execbd
	/bin/echo -e "Creating image on $FreeNode...\c"
	/bin/sleep $loglatency
	RootImg=`/bin/ls /images/vol*/*.img | /bin/egrep "\/$LOGNAME\.img$" 2>/dev/null`
	while [ ! -n "$RootImg" ]
	do
		/bin/echo -n .
		RootImg=`/bin/ls /images/vol*/*.img | /bin/egrep "\/$LOGNAME\.img$" 2>/dev/null`
		/bin/sleep $loglatency
	done
	/bin/echo

}

# Subfunction to send mount ticket mountcmd v2, mount all images of $LOGNAME to $FreeNode, then get $IMGoN_MP
mountcmd()
{
	/bin/echo -e "Sending mount request to $FreeNode now...\n"
	MOUNTUSER=$LOGNAME
	MOUNTOPRNODE=$FreeNode
	execnode=$MOUNTOPRNODE
	# /bin/echo -e "#DBG_mountcmd_in var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$MOUNTUSER\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"

	/bin/echo -e "#! /bin/bash\nsource /etc/environment\nsource /LCC/bin/lcc.conf\nMOUNTROOT=\"$MOUNTROOT\"\nMOUNTUSER=\"$LOGNAME\"" > /tmp/draft.rt.geoexec.$LOGNAME.$MOUNTOPRNODE

	/bin/cat >> /tmp/draft.rt.geoexec.$LOGNAME.$MOUNTOPRNODE << "MAINFUNC"
	# Ticket of mount user image
	# /bin/echo > /tmp/mntdbg.$MOUNTUSER #DBG

	ImgList=`/bin/ls /images/vol*/*.img | /bin/egrep "(\.\.|\/)$MOUNTUSER\.img$" | /usr/bin/sort -r 2>/dev/null`
	MUID=`/usr/bin/id -u $MOUNTUSER`
	MGID=`/usr/bin/id -g $MOUNTUSER`
	# /bin/echo -e "`/bin/date +%s`\tMUID:MGID= $MUID:$MGID\nImgList:\n$ImgList\n" >> /tmp/mntdbg.$MOUNTUSER #DBG

	for IMG in $ImgList
	do
		MP=`/bin/echo -e "$IMG" | /bin/sed 's/^\/images\/vol[0-9][0-9]\///g' | /bin/sed 's/\img$/./g' | /bin/sed 's/\.\./\//g' | /usr/bin/awk -F "/" '{for(i=NF;i>0;i--)printf("%s",$i"/");printf"\n"}' | /bin/sed 's/^\///g'`
		MTP=`/bin/echo -n "$MOUNTROOT";/bin/echo $MP`
		# /bin/echo -e "IMG=$IMG\nMTP=$MTP" >> /tmp/mntdbg.$MOUNTUSER #DBG
		if [ ! -d $MTP ]
		then
			/bin/mkdir -p $MTP 2>/dev/null
		fi
		/bin/mount -o loop $IMG $MTP 2>/dev/null
		/bin/sleep 0.2
		/bin/chown $MUID:$MGID $MTP
		/bin/chmod g+w $MTP
		umask 0002 $MTP
		# /bin/ls -l $MTP >> /tmp/mntdbg.$MOUNTUSER #DBG
		# echo -e "\n" >> /tmp/mntdbg.$MOUNTUSER #DBG
	done
MAINFUNC
	# /bin/echo -e "#DBG_mountcmd_run1 var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"
	/bin/echo -e "$endline $FreeNode" >> /tmp/draft.rt.geoexec.$LOGNAME.$MOUNTOPRNODE
	# /bin/echo -e "#DBG_mountcmd_run2 var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"
	/bin/mv /tmp/draft.rt.geoexec.$LOGNAME.$MOUNTOPRNODE /tmp/rt.geoexec.$LOGNAME.$MOUNTOPRNODE
	# /bin/echo -e "#DBG_mountcmd_run3 var input \n MOUNTROOT=$MOUNTROOT \n MOUNTUSER=$LOGNAME\n ImgList=\n$ImgList\n FreeNode=$FreeNode\n MOUNTOPRNODE=$MOUNTOPRNODE\n"
	secrtsend_execbd
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

# Subfunction to send ticket of kill all user threads and umount $MountList_mntp on $MountNode terminator v2, and check till finished
terminator()
{
	/bin/echo -e "Sending kill and umount request to $MountNode now...\n"
	KILLUSER=$LOGNAME
	# /bin/echo -e "#DBG_terminator_in var input \n MOUNTROOT=$MOUNTROOT \n KILLUSER=$LOGNAME\n ImgList=\n$ImgList"
	for execnode in $MountNode
	do
	/bin/echo -e "#! /bin/bash\nsource /etc/environment\nsource /LCC/bin/lcc.conf\nCOLUMNS=512\nMOUNTROOT=\"$MOUNTROOT\"\nKILLUSER=\"$LOGNAME\"" > /tmp/draft.rt.geoexec.$LOGNAME.$execnode

	/bin/cat >> /tmp/draft.rt.geoexec.$LOGNAME.$execnode << "MAINFUNC"
	# Ticket of terminate user session and umount user images
	# echo -e "$(hostname)" > /tmp/DBG_terminator #DBG
	umountuser()
	{
		UmountInfo=`COLUMNS=512 /bin/lsblk | /bin/grep -v snap | /bin/grep loop | /bin/grep "$KILLUSER" | /usr/bin/awk '{print $NF"\t"$1}' | /usr/bin/sort`
		# echo -e "UmountInfo=\n$UmountInfo\t$(hostname)" >> /tmp/DBG_terminator #DBG
		# COLUMNS=512 /bin/lsblk >> /tmp/DBG_terminator #DBG
		for UML in "$UmountInfo"
		do
			UMP=`/bin/echo -e "$UML" | /usr/bin/awk '{print $1}'`
			UMD=`/bin/echo -e "$UML" | /usr/bin/awk '{print $2}'`
			# echo -e "UMP=$UMP\nUMD=$UMD\t$(hostname)" >> /tmp/DBG_terminator #DBG
			/usr/sbin/service smbd restart
			/usr/sbin/service nmbd restart
			# echo -e "SMB service restarted\t$(hostname)" >> /tmp/DBG_terminator #DBG
			/bin/umount -l $UMP
			# echo -e "$UMP unmounted\t$(hostname)" >> /tmp/DBG_terminator #DBG
			# /bin/rm -f /dev/$UMD &
			# echo -e "$UMD deleted\t$(hostname)" >> /tmp/DBG_terminator #DBG
		done
	}
	# /usr/bin/pkill -u $KILLUSER
	killlist=`/bin/ps -aux | /bin/grep -vE "/bin/grep|lcctkt." | /bin/grep -e "^$KILLUSER " | /usr/bin/awk '{print $2}'`
	# echo -e "killlist=\n`/bin/ps -aux | /bin/grep -vE "/bin/grep|lcctkt." | /bin/grep $KILLUSER`" >> /tmp/DBG_terminator #DBG
	while [ -n "$killlist" ]
	do
		for killthd in $killlist
		do
			/bin/kill -9 $killthd 2>/dev/null
		done
		killlist=`/bin/ps -aux | /bin/grep -vE "/bin/grep|lcctkt." | /bin/grep -e "^$KILLUSER " | /usr/bin/awk '{print $2}'`
	done
	# echo -e "$KILLUSER killed\t$(hostname)" >> /tmp/DBG_terminator #DBG
	umountuser
	UmountList=`COLUMNS=512 /bin/mount | /bin/egrep "(\.\.|\/)$KILLUSER\.img" | /bin/grep "$MOUNTROOT" | /usr/bin/awk '{print $3}' | /usr/bin/sort -r 2>/dev/null`
	while [ -n "$UmountList" ]
	do
		umountuser
		/bin/sleep 1
		UmountList=`COLUMNS=512 /bin/mount | /bin/egrep "(\.\.|\/)$KILLUSER\.img" | /bin/grep "$MOUNTROOT" | /usr/bin/awk '{print $3}' | /usr/bin/sort -r 2>/dev/null`
	done
MAINFUNC

	/bin/echo -e "$endline $execnode" >> /tmp/draft.rt.geoexec.$LOGNAME.$execnode
	/bin/mv /tmp/draft.rt.geoexec.$LOGNAME.$execnode /tmp/rt.geoexec.$LOGNAME.$execnode
	secrtsend_execbd
	/bin/echo -e "Kill request sent...\c"
	/bin/sleep $loglatency
	mountlist
	while [ "$MountList_node" == "$execnode" ]
	do
		/bin/echo -n .
		mountlist
		/bin/sleep $loglatency
	done
	/bin/echo -e "\nSeems you are now terminated on $execnode\n"
	unset execnode
	# /bin/echo -e "#DBG_terminator_out MountList =\n$MountList\nexecnode unset as \"$execnode\""
done
}

# Secure mount module, first check and create user root workspace image if does not exist.
# Then call mountcmd() to mount all images of $LOGNAME to $FreeNode, then get $IMGoN_MP
# Check mount integrity before mount:
# If missing image mounted then mount all again
# If image mounted multiple times (one or more nodes) the call terminator() to kill all user sessions.
# Always place secmount() after mountlist() and before secpatch()
secmount()
{
	# echo -e "1 FreeNode=$FreeNode" #DBG_secmount
	# chkusrimg
	/bin/echo -e "Checking your workspace image...\n"
	RootImg=`/bin/ls /images/vol*/*.img | /bin/egrep "\/$LOGNAME\.img$" 2>/dev/null`
	# /bin/echo -e "#DBG_Main1   First Check, ImgList =\n$ImgList"
	if [ ! -n "$RootImg" ]
	then
		/bin/sleep $loglatency
		RootImg=`/bin/ls /images/vol*/*.img | /bin/egrep "\/$LOGNAME\.img$" 2>/dev/null`
		# /bin/echo -e "#DBG_Main1   Double check, ImgList =\n$ImgList"
		if [ ! -n "$RootImg" ]
		then
			/bin/sleep $loglatency
			RootImg=`/bin/ls /images/vol*/*.img | /bin/egrep "\/$LOGNAME\.img$" 2>/dev/null`
			# /bin/echo -e "#DBG_Main1   Treble Check, ImgList =\n$ImgList"
			if [ ! -n "$RootImg" ]
			then
				mkrootimg
				/bin/echo -e "\nCreating your new root image..\c"
				while [ ! -n "$RootImg" ]
				do
					/bin/echo -ne "."
					/bin/sleep 1
					RootImg=`/bin/ls /images/vol*/*.img | /bin/egrep "\/$LOGNAME\.img$" 2>/dev/null`
					# /bin/echo -e "#DBG_Main1   Loop Check, ImgList =\n$ImgList"
				done
				/bin/echo
			fi
		fi
	fi
	ImgList=`/bin/ls /images/vol*/*.img | /bin/egrep "(\.\.|\/)$LOGNAME\.img$" | /usr/bin/sort -r 2>/dev/null`
	# $lococlu/tools/UCIL.sh &
	/bin/echo -e "\nFound your image:\n$ImgList\n"

	# check and mount
	ImgCount=`/bin/echo $ImgList | /bin/grep -o "/images/vol" | /usr/bin/wc -l`
	MntCount=`/bin/echo $MountList_mntp | /bin/grep -o "$MOUNTROOT" | /usr/bin/wc -l`
	MountNodeCount=`/bin/echo -ne "$MountList" | /usr/bin/awk '{print $1}' | /usr/bin/sort -u | /usr/bin/wc -l`
	# echo -e "2 FreeNode=$FreeNode\n2 MountNode=$MountNode\n2 MountNodeCount=$MountNodeCount"  #DBG_secmount
	if [ "$MountNodeCount" -gt 1 ]
	then
		# M-Kill
		/bin/echo -e "!!! WARNING !!!\nYour images are mounted to multiple nodes!\nUmounting all of your images to protect your data.\nPlease contact LCC admin ASAP for your data safty!\n"
		terminator
		/bin/sleep $loglatency
		mountlist
		MountNode=$MountList_node
		while [ -n "$MountList" ]
		do
			terminator
			/bin/sleep 10
			mountlist
			MountNode=$MountList_node
		done
		/bin/echo -e "All session killed!!!\nThis connection will be terminated in 120 sec.\nPlease contact LCC admin ASAP for your data safty!"
		sleep 120
		exit
	elif [ "$MountNodeCount" == 0 ]
	then
		# Mount from empty
		MountNode=$FreeNode
		# echo -e "3 FreeNode=$FreeNode\n3 MountNode=$MountNode" #DBG_secmount
		/bin/echo -e "Mounting your image to $MountNode now...\n"
		mountcmd
	elif [ "$ImgCount" -gt "$MntCount" ]
	then
		# Add missiong mount
		FreeNode=$MountNode
		# echo -e "4 FreeNode=$FreeNode\n4 MountNode=$MountNode" #DBG_secmount
		/bin/echo -e "Mounting your image to $MountNode now...\n"
		mountcmd
	elif [ "$ImgCount" -lt "$MntCount" ]
	then
		# S-Kill
		/bin/echo -e "!!! WARNING !!!\nYour mounted images are more then actual images!\nUmounting all of your images to protect your data.\nPlease contact LCC admin ASAP for your data safty!\n"
		terminator
		/bin/echo -e "All session killed!!!\nThis connection will be terminated in 120 sec.\nPlease contact LCC admin ASAP for your data safty!"
		sleep 120
		exit
	fi
}

# Secure SSH redirector, the Last subfunction checking $ImgList and $LaunchNode, then patch user through
secpatch()
{
	if [ ! -n "$ImgList" -o ! -n "$LaunchNode" -o ! -n "$IMGoN_MP" ]
	then
		/bin/rm -f $opstmp/launchlock.$LOGNAME
		/bin/echo -e "\nLaunch failed, kicking you out now... Please try connect again or contact system admin with below debug info:\n"
		/bin/echo -e "\n#DBG_secpatch_f Missing launch factor, current info:\nLaunchNode= $LaunchNode\nImgList:\n$ImgList\nIMGoN_MP:\n$IMGoN_MP\n"
		exit
	else
		# /bin/echo -e "\n#DBG_secpatch_t Got UID: $LOGNAME\n your image:\n$ImgList\n mounted on:\n $IMGoN_MP\n of $LaunchNode\n"
		/bin/rm -f $opstmp/launchlock.$LOGNAME
		/bin/echo -e "\nPatching you through to $LaunchNode now...\n"
		/bin/echo -e "Your workspace is now at "$MOUNTROOT$LOGNAME'/, Samba share path: \\\\'$LaunchNode'\\workspace\\'$LOGNAME"\n"
		# /bin/echo -e "#DBG_secpatch_t Congrats!!! All good !!! Drill interrupted!!!\n\nPress any key to exit" && read KEY && /bin/rm -f $opstmp/launchlock.$LOGNAME && exit
		/usr/bin/ssh $LOGNAME@$LaunchNode
	fi
}

# tee_out series functions for lccmain user logging, DEBUG ONLY
tee_out()
{
	/usr/bin/tee >(tee_filter)
}


tee_filter()
{
output=/var/log/lcc/lcclog.`/bin/date +%y%m%d-%H%M%S`.$LOGNAME
# output=/var/log/lcc/lcclog.$LOGNAME
echo -e "\n`/bin/date +%Y-%m%d-%H%M-%S`\t User= $LOGNAME\n">$output
i=0
while read line
do
	i=$(($i+1))
    # echo -en "line$i\t" >> $output
	echo $line >> $output
    if [ -n "`echo $line | grep 'Last login'`" -o "$i" -gt 200 ]
    then
		/bin/echo -e "\nUser got into the target node.\n\n" >> $output
		output=/dev/null
		tee_passthrough 2>/dev/null
    fi
done
}

tee_passthrough()
{
 # ls -l /dev/fd/ >> /var/log/lcc/lcclog.$LOGNAME
 /bin/cat > /usr/bin/printf
}

main_out()
{

echo -e "\n`/bin/date +%Y-%m%d-%H%M-%S`\t User= $LOGNAME\n">/var/log/lcc/lcclog.`/bin/date +%y%m%d-%H%M%S`.$LOGNAME

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
	/bin/echo -e "Did not find your image mounted on any node.\n"
	selectfree
	secmount
	LaunchNode=$FreeNode
	# /bin/echo -e "#DBG_Main1_a_run_2 LaunchNode=$LaunchNode\n MountList = $MountList"
	secpatch
	exit
elif [ "$loglatency" -lt "$MountList_lag" ]
then
	# /bin/echo -e "#DBG_Main1_b_in MountList = $MountList"
	/bin/rm -f $opstmp/*.$MountList_node 2>/dev/null #Drop0*
	echo -e "Image mount record overtime > $loglatency seconds!!! Refreshing ..\c"
	/bin/sleep $loglatency
	mountlist
	#while [ "$loglatency" -lt "$MountList_lag" ]
	while [ ! -n "$MountList_lag" ]
	do
		/bin/rm -f $opstmp/*.$MountList_node 2>/dev/null #Drop2*
		/bin/sleep $loglatency
		mountlist
		/bin/echo -n .
	done
	/bin/echo
fi
MountNode=$MountList_node
IMGoN_MP=$MountList_mntp
/bin/echo -e "\nImages mounted on:\n$(/bin/cat $opstmp/secrt.sitrep.* 2>/dev/null | /bin/grep "log=imgon" | /bin/egrep "(\.\.|\/)$LOGNAME\.img" | /usr/bin/awk '{print $1"\t"$4}')"
secmount

# Check /bin/cpU usage of $MountNode, if over 80% ask if change node, else patch through
MountNodeLoad=`/bin/cat $opstmp/secrt.sitrep.$MountNode 2>/dev/null | /bin/grep "log=load" | /usr/bin/awk '{print $4}'`
while [ ! -n "$MountNodeLoad" ]
do
	MountNodeLoad=`/bin/cat $opstmp/secrt.sitrep.$MountNode 2>/dev/null | /bin/grep "log=load" | /usr/bin/awk '{print $4}'`
	/bin/sleep $loglatency
done
# /bin/echo -e "#DBG_checkload MountNodeLoad = $MountNodeLoad %\n"

if [ "$MountNodeLoad" -gt 99 ]
then
	/bin/echo -e "Your current node is under heavy load, switch node? Y/N\n"
	while true
	do
		read USER_CHO
		case $USER_CHO in
			Y|y|YES|Yes|yes)
				/bin/echo -e "\n*** Switching node WILL KILL ALL OF YOU CURRENT SESSIONS ***\n"
				/bin/echo -e "Input YES (exactly in uppercase) to confirm again, or anything else to quit.\n"
				read USER_CFM
				if [ "$USER_CFM" == "YES" ]
				then
					terminator
					selectfree
					mountlist
					secmount
					LaunchNode=$FreeNode
					secpatch
					exit
				else
					/bin/rm -f $opstmp/launchlock.$LOGNAME
					/bin/echo -e "\nDropping you out now, please try connect again."
					exit
				fi
			;;
			N|n|NO|No|no)
				/bin/echo -e "\nPatching you through to $MountNode under heavy load now, you can always switch node with new logins.\n"
				LaunchNode=$MountNode
				secpatch
				exit
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
	exit
fi
}

main_out # | tee_out #comment tee_out out to disable lcclog
