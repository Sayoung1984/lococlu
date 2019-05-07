#! /bin/bash
# Tool of user self service code images dumper, relys on $opstmp/listcodeimage.sh

opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
source $lococlu/lcc.conf

# export NEWT_COLORS='
# window=,red
# border=white,red
# textbox=white,red
# button=black,white
# '

$lococlu/tools/usercodeimagelist.sh
derliste=`cat $opstmp/ucdimglst.$LOGNAME | awk '{print $0, "OFF"}'`
# echo -e "$derliste"
lstlenth=$(echo -e "$derliste" | wc -l)
height=`/bin/echo -e "scale=1; $lstlenth + 7 " | /usr/bin/bc`
lstheight=`/bin/echo -e "scale=1; $lstlenth " | /usr/bin/bc`

select=$(whiptail --title "Code Image list"  --checklist --separate-output \
"       Image name                                Mount node" $height 80 $lstheight \
$derliste 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus = 0 ];
then
    echo "You've choose these images to be destroyed" $select
else
    echo "You chose Cancel."
fi
