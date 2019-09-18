#! /bin/bash
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



mtd_img=`/bin/lsblk | /bin/grep -v snap | /bin/grep loop | /usr/bin/awk '{print $NF}' | /bin/grep -E "^\/" | /bin/grep $MOUNTROOT | /usr/bin/sort -r`
mtd_user=`/bin/echo -e "$mtd_img" | /bin/sed "s|$MOUNTROOT||g" | /usr/bin/awk -F "/" '{print $1}' | /usr/bin/sort -u`
lgn_user=`/usr/bin/who | /bin/grep -vE "root|tmux|:pts/|:0 " | /usr/bin/awk '{print "^" $1 "$"}' | /usr/bin/sort -u | /usr/bin/awk '{printf $1 "|"}' | /bin/sed 's/[|]$//g'`
umt_user=`/bin/echo -e "$mtd_user" | /bin/grep -vE $lgn_user | /usr/bin/awk '{printf "/" $1 "$|/" $1 "/|"}' | /bin/sed 's/[|]$//g'`
umt_img=`/bin/echo -e "$mtd_img" | /bin/grep -E $umt_user`


# echo -e "MOUNTROOT=$MOUNTROOT\n\nmtd_img=\n$mtd_img\n\nmtd_user=\n$mtd_user\n\nlgn_user=\n$lgn_user\n\numt_user=\n$umt_user\n\numt_img=\n$umt_img" #DBG

# /bin/ps -aux | /bin/grep -vE "root|nobody" | /bin/grep -E $umt_user | /bin/grep -vE "/bin/grep" #DBG
if [ -n "$umt_user" ]
then
	for TTK in `/bin/ps -aux | /bin/grep -vE "root|nobody" | /bin/grep -E $umt_user | /bin/grep -vE "/bin/grep" | awk '{print $2}'`
	do
		# echo "!!! /bin/kill -9 $TTK" #DBG
		/bin/kill -9 $TTK
	done

	/usr/sbin/service smbd restart &
	/usr/sbin/service nmbd restart

	/usr/bin/sleep 1

	for ITU in $umt_img
	do
		# echo "!!! umount -l $ITU &" #DBG
		umount -l $ITU &
	done
fi