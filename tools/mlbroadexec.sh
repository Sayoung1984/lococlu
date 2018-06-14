#! /bin/bash

# Broadcast single line command to all nodes running noderep deamon.
# The noderep deamon will execute command with root permission

COLUMNS=300
endline="###---###---###---###---###"

# Secure Realtime Text Copy v2, check text integrity, then drop real time text to NFS at this last step, with endline
# /bin/sed -i '$d' $REPLX # To cat last line, on receive side
secrtsend_bdexec()
{
  for REPLX in `/bin/ls /var/log/rt.* 2>/dev/null`
  do
    CheckLineL1=`/usr/bin/tac $REPLX | sed -n '1p'`
    CheckLineL2=`/usr/bin/tac $REPLX | sed -n '2p'`
    if [ "$CheckLineL1"  == "$endline $execnode" -a "$CheckLineL2"  != "$endline $execnode" ]
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
    echo "This tool will pack single line commands into geoexec tickets, and send to all live nodes running noderep deamon."
fi



# Main1, get $USER_CMD
# cat /receptionist/opstmp/secrt.sitrep.load.* | grep -v $endline | awk -F " " '{print $1}' > /receptionist/opstmp/resource.livenodes
# chmod 666 /receptionist/opstmp/resource.livenodes
execlist=`cat /receptionist/opstmp/secrt.sitrep.load.* | grep -v $endline | awk -F " " '{print $1}'`
echo -e "Found nodes as below:"
# cat /receptionist/opstmp/resource.livenodes
echo "$execlist"
echo -e "Refresh node list? (Y/N) \c"
while true; do
read USER_CHO
	case $USER_CHO in
		Y|y|YES|Yes|yes)
				# cat /receptionist/opstmp/secrep.loadrep.* | awk -F " " '{print $1}' > /receptionist/opstmp/resource.livenodes
				# chmod 666 /receptionist/opstmp/resource.livenodes
                execlist=`cat /receptionist/opstmp/secrt.sitrep.load.* | grep -v $endline | awk -F " " '{print $1}'`
                echo -e "Now the list are:"
				# cat /receptionist/opstmp/resource.livenodes
                echo "$execlist"
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
echo -e "Please input your command to be broadcast, and ends with blank line"
# read -d '' x <<!END!
# read USER_CMD

# PT1
# USER_CMD=()
# # while IFS='$\n' read -r USER_CMD_LINE
# while IFS='$\n' read -r USER_CMD_LINE
# do
#     [[ "$USER_CMD_LINE" == "" ]] && break # break if line is empty
#     USER_CMD+=(`echo -e "$USER_CMD_LINE\n"`)
#     # echo -ne "${USER_CMD_LINE[$line]} , $line"
# done

# PT2
USER_CMD=($(
while IFS='$\n' read -r USER_CMD_LINE
do
    [[ "$USER_CMD_LINE" == "" ]] && break
    echo -e "$USER_CMD_LINE\n" | awk '{print $0}'
done
))

echo -e "Your command to be sent out is:"
# echo -e "${USER_CMD[*]}"
# echo ${USER_CMD[@]}
# printf '%s ' "${USER_CMD[@]}"
echo -e "#"
(IFS='$\n'; echo "${USER_CMD[@]}")
echo -e "##"
printf '%s\n' "${USER_CMD[@]}"
echo -e "###"
for ((i = 0; i < ${#USER_CMD[@]}; i++))
do
    echo "${USER_CMD[$i]}"
done
# echo -e "####"
# for line in ${USER_CMD[*]}
# do
#     echo -e "$line"
# done

echo -e "Confirm? (Y/N) \c"
while true; do
read USER_CHO
case $USER_CHO in
	Y|y|YES|Yes|yes)
			break
			;;
	N|n|NO|No|no)
			echo -e "Input your command again:"
			read USER_CMD
			echo -e "Your command to be sent out is:"
			echo -e $USER_CMD
			echo -e "Confirm? (Y/N) \c"
			;;
	*)
			echo -e "\nInvalid choice, please choose Yes or No.\n"
			;;
esac
done
echo -e "Sending out this command: \n###############"
echo -e $USER_CMD
echo -e "###############\nto all nodes in the list now"
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

# Main2, Sending $USER_CMD to ticket
for execnode in $execlist
do
	echo $USER_CMD>/var/log/rt.ticket.geoexec.$execnode
	echo -e "$endline $execnode" >> /var/log/rt.ticket.geoexec.$execnode
    sleep 0.33
    secrtsend_bdexec
    echo -e "Ticket to $execnode sent..."
done

echo -e "All command tickets sent out"
