#! /bin/bash
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
for i in `/bin/cat /receptionist/opstmp/resource.livenodes`
do
	echo $USER_CMD>/receptionist/opstmp/ticket.geoexec.$i
	chmod 666 /receptionist/opstmp/ticket.geoexec.$i
	rm -f /receptionist/opstmp/resource.livenodes
done
echo -e "Command tickets sent out"
