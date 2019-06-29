#! /bin/bash
# User self eject tool to:
# 1. Auto eject in abnormalities
# 2. Or for users to self umount all loop images and kill all ssh sessions on every node.
# Suggested by Even, request gethered from users.

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
		/bin/mv $REPLX `/bin/echo -e "$opstmp/sec$REPLXNAME"`
		/bin/chmod 666 `/bin/echo -e "$opstmp/sec$REPLXNAME"`
	else
		# /bin/mv $REPLX.fail  #DBG
		/bin/rm $REPLX
	fi
done
}

mountlist()
{
	MountList=`/bin/cat $opstmp/secrt.sitrep.unirep.* 2>/dev/null | /bin/grep "log=imgon" | /bin/egrep "(\.\.|\/)$LOGNAME\.img"`
	if [ -n "$MountList" ]
	then
		MountList_node=`/bin/echo -e "$MountList" | /usr/bin/head -n 1 | /usr/bin/awk '{print $1}'`
		MountList_img=`/bin/echo -e "$MountList" | /usr/bin/awk '{print $3}'`
		MountList_mntp=`/bin/echo -e "$MountList" | /usr/bin/awk '{print $4}'`
		MountList_lag=`/bin/echo $(( $(/bin/date +%s) - $(/bin/echo -e "$MountList" | /bin/sed '2,$d; s/^.*\t//g') )) 2>/dev/null`
	fi
	# /bin/echo -e "#DBG_mountlist MountList family:\n$MountList\n#DBG_mountlist MountList_node:\n$MountList_node"
	# /bin/echo -e "#DBG_mountlist MountList_img:\n$MountList_img\n#DBG_mountlist MountList_mntp:\n$MountList_mntp"
	# /bin/echo -e "#DBG_mountlist MountList_lag =\t$MountList_lag\n#DBG_mountlist Log latency =\t$loglatency\n\n"
}


# Subfunction to send ticket of kill all user threads and umount $UmountInfo on $InvoNode terminator v2, and check till finished
terminator()
{
/bin/echo -e "Sending kill and umount request to $InvoNode now...\n"
KILLUSER=$LOGNAME
# /bin/echo -e "#DBG_terminator_in var input \n MOUNTROOT=$MOUNTROOT \n KILLUSER=$LOGNAME\n ImgList=\n$ImgList"
for execnode in $InvoNode
do
	/bin/echo -e "#! /bin/bash\nCOLUMNS=512\nMOUNTROOT=\"$MOUNTROOT\"\nKILLUSER=\"$LOGNAME\"" > /tmp/draft.rt.geoexec.$LOGNAME.$execnode

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

	killlist=`/bin/ps -aux | /bin/grep -vE "/bin/grep|lcctkt." | /bin/grep $KILLUSER | /usr/bin/awk '{print $2}'`
	# echo -e "killlist=\n`/bin/ps -aux | /bin/grep -vE "/bin/grep|lcctkt." | /bin/grep $KILLUSER`" >> /tmp/DBG_terminator #DBG
	while [ -n "$killlist" ]
	do
		for killthd in $killlist
		do
			/bin/kill -9 $killthd 2>/dev/null
		done
		killlist=`/bin/ps -aux | /bin/grep -vE "/bin/grep|lcctkt." | /bin/grep $KILLUSER | /usr/bin/awk '{print $2}'`
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
done
}

/bin/echo -e "\nSpooling user eject tool...\n"
RTinfo=`/bin/cat $opstmp/secrt.sitrep.unirep.* 2>/dev/null | /bin/grep "$LOGNAME"`

LogNode=`/bin/echo -e "$RTinfo" | /bin/grep "log=ulsc" | /usr/bin/awk '{print $1}'`
LogNode_CL=`/bin/echo -e "$LogNode"| /usr/bin/wc -l`

MountNode=`/bin/echo -e "$RTinfo" | /bin/grep "log=imgon" | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
MountNode_CL=`/bin/echo -e "$MountNode"| /usr/bin/wc -l`

InvoNode=`/bin/echo -e "$LogNode\n$MountNode" | /usr/bin/sort -u`

MountInfo=`/bin/echo -e "$RTinfo" | /bin/grep "log=imgon" | /usr/bin/awk '{printf $1"\t"$3"\t"$4"\n"}'`
MountInfo_CL=`/bin/echo -e "$MountInfo"| /usr/bin/wc -l`

ImageInfo=`/bin/ls /images/vol0*/*.img | /bin/egrep "(\.\.|\/)$LOGNAME\.img$" | /usr/bin/sort -r 2>/dev/null`
ImageInfo_CL=`/bin/echo -e "$ImageInfo"| /usr/bin/wc -l`

/bin/echo -e "RTinfo:\n$RTinfo\n" #DBG
/bin/echo -e "LogNode\t$LogNode_CL\n$LogNode\n" #DBG
/bin/echo -e "MountNode\t$MountNode_CL\n$MountNode\n" #DBG
/bin/echo -e "InvoNode\n$InvoNode\n" #DBG
/bin/echo -e "MountInfo\t$MountInfo_CL\n$MountInfo\n" #DBG
/bin/echo -e "ImageInfo\t$ImageInfo_CL\n$ImageInfo\n" #DBG
mountlist #DBG
# if [ "$LogNode" != "$MountNode" -o "$MountNode_CL" != 1 -o "$MountInfo_CL" -gt "$ImageInfo_CL" ]
# then
#
#
# 	if [ "$LogNode_CL" != 1 ]
# 	then
# 		/bin/echo -e "User connected to multiple nodes!\n\nFound sessions on:\n$LogNode"
# 	fi
#
# 	if [ "$MountNode_CL" != 1 ]
# 	then
# 		/bin/echo -e "User images mounted to multiple nodes!\n\nFound image mounted on:\n$MountNode"
# 	fi
#
# 	if [ "$LogNode" != "$MountNode" ]
# 	then
# 		/bin/echo -e "User connected to a wrong node!\n\nFound sessions on:\n$LogNode\nFound image mounted on:\n$MountNode"
# 	fi
#
# 	if [ "$MountInfo_CL" -gt "$ImageInfo_CL" ]
# 	then
# 		/bin/echo -e "Found image redundant mount!\n\nMount stat:\n$MountInfo"
# 	fi
#
#
# 	InvoNode=`/bin/echo -e "$InvoNode" | /bin/grep -v $(hostname)`
# 	if [ -n "$InvoNode" ]
# 	then
# 		terminator
# 		sleep 3
# 	fi
# 	InvoNode=`hostname`
# 	terminator
# fi
#


if [ "$LogNode_CL" != 1 ]
then
	/bin/echo -e "User connected to multiple nodes!\n\nFound sessions on:\n$LogNode"
elif [ "$MountNode_CL" != 1 ]
then
	/bin/echo -e "User images mounted to multiple nodes!\n\nFound image mounted on:\n$MountNode"
elif [ "$LogNode" != "$MountNode" ]
then
	/bin/echo -e "User connected to a wrong node!\n\nFound sessions on:\n$LogNode\nFound image mounted on:\n$MountNode"
elif [ "$MountInfo_CL" -gt "$ImageInfo_CL" ]
then
	/bin/echo -e "Found image redundant mount!\n\nMount stat:\n$MountInfo"
else
	/bin/echo -e "\nInitiating user eject tool now...\n\nThis tool will:\n\t1. Kill all of your LCC sessions \n\t2. Unmount all of your workspace images.\n\nContinue? Y/N" &
	while true
	do
		read USER_CHO
		case $USER_CHO in
		Y|y|YES|Yes|yes)
			/bin/echo -e "\n*** Emergency eject WILL KILL ALL OF YOU CURRENT SESSIONS ***\n"
			/bin/echo -e "Input YES (exactly in uppercase) to final confirm user eject, or anything else to quit.\n"
			read USER_CFM
			if [ "$USER_CFM" == "YES" ]
			then
				terminator
			else
				/bin/echo -e "\nThe answer is not \"YES\".\n\nExiting tool by the safty protocal now...\n"
				exit
			fi
		;;
		N|n|NO|No|no)
			/bin/echo -e "\nWithdrawing user eject tool now.\n"
			exit
		;;
		*)
			/bin/echo -e "\nInvalid choice, please input Yes or No.\n"
		;;
		esac
	done
fi

/bin/echo -e "\n\n!!! Warning !!!\nAbnormal user status found!\n\nInitiating auto ejection...\n\n"
InvoNode=`/bin/echo -e "$InvoNode" | /bin/grep -v $(hostname)`
if [ -n "$InvoNode" ]
then
	terminator
	sleep 3
fi
InvoNode=`hostname`
terminator
