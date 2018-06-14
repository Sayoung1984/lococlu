#! /bin/bash

# Execute Broadcaster v2
# Send multiple line commands as Bash scripts to all live nodes running noderep deamon.
# The noderep deamon will execute command with root permission

COLUMNS=300
endline="###---###---###---###---###"

# Secure Realtime Text Copy v2, execbd variant with target node signature in tickets' name and checklines
# Check text integrity, then drop real time text to NFS at this last step, with endline
secrtsend_execbd()
{
  for REPLX in `/bin/ls /var/log/rt.* 2>/dev/null`
  do
    CheckLineL1=`/usr/bin/tac $REPLX | sed -n '1p'`
    CheckLineL2=`/usr/bin/tac $REPLX | sed -n '2p'`
    if [ "$CheckLineL1"  == "$endline $node" -a "$CheckLineL2"  != "$endline $execnode" ]
    then
      REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
      cp $REPLX `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
      chmod 666 `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
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
execlist=`cat /receptionist/opstmp/secrt.sitrep.load.* 2>/dev/null | grep -v $endline | awk -F " " '{print $1}'`
echo -e "Found nodes as below:"
echo "$execlist"
echo -e "Refresh node list? (Y/N) \c"
while true; do
read USER_CHO
	case $USER_CHO in
		Y|y|YES|Yes|yes)
                execlist=`cat /receptionist/opstmp/secrt.sitrep.load.* 2>/dev/null | grep -v $endline | awk -F " " '{print $1}'`
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
for node in `printf '%s\n' "${ARR[@]}"`
do
  # echo -e "#DBG_Main3 $node"
  echo -e "#! /bin/bash\n#Ticket sent from $HOSTNAME\n" > /var/log/draft.rt.ticket.geoexec.$node
  chmod a+x /var/log/draft.rt.ticket.geoexec.$node
  printf '%s\n' "${USER_CMD[@]}" >> /var/log/draft.rt.ticket.geoexec.$node
	echo -e "\n$endline $node" >> /var/log/draft.rt.ticket.geoexec.$node
  cp /var/log/draft.rt.ticket.geoexec.$node /var/log/rt.ticket.geoexec.$node
  sleep 0.33
  secrtsend_execbd
  echo -e "Ticket to $node sent..."
done
 echo -e "All command tickets sent out"
