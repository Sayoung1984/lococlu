#! /bin/bash
export COLUMNS=512
endline="###---###---###---###---###"
loglatency=3
opstmp=/LCC/opstmp
lococlu=/LCC/bin
dskinitsz=500
source /LCC/bin/lcc.conf

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

STD_CNT_SVR=`/bin/ls $opstmp/secrt.sitrep.* | /usr/bin/wc -l`
LOGINFO=`/bin/cat $opstmp/secrt.sitrep.*`
LIVE_CNT_SVR=`/bin/echo -e "$LOGINFO" | /bin/grep $endline | /usr/bin/wc -l`
while [ "$STD_CNT_SVR" != "$LIVE_CNT_SVR" ]
do
	sleep 1
	# echo -e "Refresh cycle!"
	LOGINFO=`/bin/cat $opstmp/secrt.sitrep.*`
	LIVE_CNT_SVR=`/bin/echo -e "$LOGINFO" | /bin/grep $endline | /usr/bin/wc -l`
done

IMGINFO=`/bin/ls /images/vol*/*.img`
echo -e "User\tCNT_Img\tCNT_MNT\tCNT_SVR\tM_SVR"
for TGT_USER in `/bin/echo -e "$LOGINFO" | /bin/grep log=imgon | /usr/bin/awk '{print $4}' | /bin/sed 's#^/local/mnt/workspace/##g' | /usr/bin/awk -F '/' '{print $1}' | /usr/bin/sort -u`
do
	M_SVR=`/bin/echo -e "$LOGINFO" | /bin/grep $MOUNTROOT$TGT_USER | /bin/grep $TGT_USER.img | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
	CNT_SVR=`/bin/echo -e "$M_SVR" | /usr/bin/wc -l`
	CNT_IMG=`/bin/echo -e "$IMGINFO" | /bin/egrep "(\.\.|\/)$TGT_USER\.img" | /usr/bin/sort | /usr/bin/wc -l`
	CNT_MNT=`/bin/echo -e "$LOGINFO" | /bin/grep imgon | /bin/egrep "(\.\.|\/)$TGT_USER\.img" | /usr/bin/awk '{print $3}' | /usr/bin/sort | /usr/bin/wc -l`
	if [ "$CNT_IMG" != "$CNT_MNT" -o "$CNT_SVR" != 1 ]
	then
		/bin/echo -e "$TGT_USER\t$CNT_IMG\t$CNT_MNT\t$CNT_SVR\t$M_SVR"
		if [ "$CNT_SVR" == 1 -a "$CNT_IMG" -gt "$CNT_MNT" ]
		then
			IMG=`/bin/echo -e "$IMGINFO" | /bin/egrep "(\.\.|\/)$TGT_USER\.img" | /usr/bin/sort`
			MNT=`/bin/echo -e "$LOGINFO" | /bin/grep imgon | /bin/grep ..$TGT_USER.img | /usr/bin/awk '{print $3}' | /usr/bin/sort`
			/bin/echo -e "Missing image mounted on "$M_SVR
			/usr/bin/diff <(/bin/echo -e "$IMG") <(/bin/echo -e "$MNT") | /bin/grep -e "^< " | /bin/sed 's#^< ##g'
			/bin/echo
		fi
	fi
done #| /usr/bin/sort -k 4