#! /bin/bash

# Execute Broadcaster v3
# Send multiple line commands as Bash scripts to all live nodes running noderep deamon.
# The noderep deamon will execute command with root permission.
# Needs root permission to run this tool.

COLUMNS=300
endline="###---###---###---###---###"
opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
source $lococlu/lcc.conf

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

# Main0, root permission check
# if [ $(id -u) != 0 ]
if [[ $EUID -ne 0 ]]
then
	echo "Please run broadcast execute as root!!!"
	exit 1
else
	echo "Spooling command broadcast..."
	echo "This tool will pack commands into geoexec tickets, and send to all live nodes running noderep deamon."
fi

# Main1, list live nodes
execlist=`cat $opstmp/secrt.sitrep.unirep.* 2>/dev/null | grep log=load | awk -F " " '{print $1}'`
echo -e "Found nodes as below:"
echo "$execlist"
echo -e "Refresh node list? (Y/N) \c"
while true; do
read USER_CHO
	case $USER_CHO in
		Y|y|YES|Yes|yes)
			execlist=`cat $opstmp/secrt.sitrep.unirep.* 2>/dev/null | grep log=load | awk -F " " '{print $1}'`
			echo -e "Now the list are:"
			echo "$execlist"
			echo -e "Refresh again? (Y/N) \c"
		;;
		N|n|NO|No|no)
			break
		;;
		*)
			echo -e "\nInvalid choice, please choose Yes or No.\n"
		;;
	esac
done

# Main2, get $USER_CMD as array
echo -e "Please input your commands, and input blank line to finish"
IFS="" ; USER_CMD=()
while IFS="" read -r USER_CMD_LINE
do
	[[ "$USER_CMD_LINE" == "" ]] && break
	USER_CMD+=(`echo -en "$USER_CMD_LINE\n"`)
done

echo -e "Your command to be sent out is:"
echo -e "\n###############\n"
printf '%s\n' "${USER_CMD[@]}"
echo -e "\n###############\n"
echo -e "Confirm? (Y/N) \c"
while true; do
read USER_CHO
case $USER_CHO in
	Y|y|YES|Yes|yes)
		break
	;;
	N|n|NO|No|no)
		echo -e "Input your command again:"
		IFS="" ; USER_CMD=()
		while IFS="" read -r USER_CMD_LINE
		do
			[[ "$USER_CMD_LINE" == "" ]] && break
			USER_CMD+=(`echo -en "$USER_CMD_LINE\n"`)
		done
		echo -e "Your command to be sent out is:"
		echo -e "\n###############\n"
		printf '%s\n' "${USER_CMD[@]}"
		echo -e "\n###############\n"
		echo -e "Confirm? (Y/N) \c"
	;;
	*)
		echo -e "\nInvalid choice, please choose Yes or No.\n"
	;;
esac
done
echo -e "\nDrafting these commands into tickets now:\n###############\n"
printf '%s\n' "${USER_CMD[@]}"
echo -e "\n###############\n"
echo -e "Please input YES to continue: \c"
while true; do
read USER_CHO
case $USER_CHO in
	YES)
		break
	;;
	*)
		echo -e "\nThe upper case YES please, or press Ctrl+C to abort. It's never too late :)\n"
		echo -e "Please input YES to continue: \c"
	;;
esac
done




# Main3, write $USER_CMD into tickets and send
IFS=$'\n' ARR=($execlist)
# declare -p ARR
for execnode in `printf '%s\n' "${ARR[@]}"`
do
	# echo -e "#DBG_Main3 $execnode"
	echo -e "#! /bin/bash\nsource /etc/environment\n#Ticket sent from $HOSTNAME\n" > /tmp/draft.rt.geoexec.$LOGNAME.$execnode
	chmod a+x /tmp/draft.rt.geoexec.$LOGNAME.$execnode
	printf '%s\n' "${USER_CMD[@]}" >> /tmp/draft.rt.geoexec.$LOGNAME.$execnode
	echo -e "\n$endline $execnode" >> /tmp/draft.rt.geoexec.$LOGNAME.$execnode
	mv /tmp/draft.rt.geoexec.$LOGNAME.$execnode /tmp/rt.geoexec.$LOGNAME.$execnode
	secrtsend_execbd
	echo -e "Ticket to $execnode sent..."
done
 echo -e "All command tickets sent out"
