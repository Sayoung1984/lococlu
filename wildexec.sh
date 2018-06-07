#! /bin/bash

# Unique finish tag to ensure report integrity
endline()
{
    /bin/echo -e "---###---###---###---###---"
}

# Secure Real Time Text Copy, check text integrity, then drop real time text to NFS at this last step
secrttcp()
{
    for REPLX in `ls /var/log/rt.*`
        do
            rpcheckline=`/usr/bin/tail -n 1 $REPLX`
            if [ "$rpcheckline"  != "---###---###---###---###---" ]
                then
                    rm $REPLX
                else
                    /bin/sed -i '$d' $REPLX
		    rpchecklineL2=`/usr/bin/tail -n 1 $REPLX`
		    if [ "$rpchecklineL2"  == "---###---###---###---###---" ]
		    	then
			     rm $REPLX
			else
			     REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
		    	     cp $REPLX `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
					 chmod 666 `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
#                    	     cp $REPLX `echo $REPLX | sed 's/\/var\/log/\/receptionist/'`
		    fi
            fi
        done
}

# Main1, get $USER_CMD
cat /receptionist/opstmp/secrep.loadrep.* | awk -F " " '{print $1}' > /receptionist/opstmp/resource.livenodes
chmod 666 /receptionist/opstmp/resource.livenodes
echo -e "Found nodes as below:"
cat /receptionist/opstmp/resource.livenodes
echo -e "Refresh node list? (Y/N) \c"
while true; do
read USER_CHO
	case $USER_CHO in
		Y|y|YES|Yes|yes)
				cat /receptionist/opstmp/secrep.loadrep.* | awk -F " " '{print $1}' > /receptionist/opstmp/resource.livenodes
				chmod 666 /receptionist/opstmp/resource.livenodes
				echo -e "Now the list are:"
				cat /receptionist/opstmp/resource.livenodes
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
echo -e "Please input your one line command to be broadcast to all nodes:"
read USER_CMD
echo -e "Your command to be sent out is:"
echo -e $USER_CMD
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
for i in `/bin/cat /receptionist/opstmp/resource.livenodes`
do
	echo $USER_CMD>/var/log/rt.ticket.geoexec.$i
	endline >> /var/log/rt.ticket.geoexec.$i
	echo -e "Ticket to $i generated..."
done
sleep 1
rm -f /receptionist/opstmp/resource.livenodes
secrttcp
echo -e "Command tickets sent out"
