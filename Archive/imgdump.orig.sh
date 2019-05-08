#! /bin/bash
# Tool of user self service code images dumper

opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
source $lococlu/lcc.conf

#list all code images
# ls -lahs /images/vol* | grep -E "\.\."$LOGNAME | awk '{print $NF}'
# echo -e "Image name \t\t\t\t\t Image mount point \t\t\t\t\t\t Image mount node"
# echo -e "Image name \t\t\t\t\t Code Branch \t Image generate date \t\t Image mount node"
read -ra wtitem <<< $(for CODEIMG in `ls -lahs /images/vol* | grep -E "\.\."$LOGNAME | awk '{print $NF}'`
do
    echo -en $CODEIMG
#    echo -en "\t\t\""
#    echo -en $CODEIMG | awk -F "-" '{printf $1}'
#    echo -en "\"\t\""
#    timestp=`echo -en $CODEIMG | awk -F "-" '{printf $NF}' | awk -F "." '{printf $NR}'`
#    echo -en ${timestp:0:4}-${timestp:4:2}-${timestp:6:2} ${timestp:8:2}:${timestp:10:2}:${timestp:12:2}
##    echo -en "\t\t"`cat /receptionist/opstmp/secrt.sitrep.unirep.* | grep $CODEIMG | awk '{printf $4}'`
    echo -en "\t\t"
    MTNODE=`cat /receptionist/opstmp/secrt.sitrep.unirep.* | grep $CODEIMG | awk '{printf $1}'`
    if [ -n "$MTNODE" ]
    then
        echo -en $MTNODE
    else
        echo -en Unmount!
    fi
#    echo -en `cat /receptionist/opstmp/secrt.sitrep.unirep.* | grep $CODEIMG | awk '{printf $1}'`
    echo -e "\t\t"OFF
done)


# echo ${wtitem[@]}


lstlenth=$(for v in ${wtitem[@]}
do
echo $v;
done | grep .img | wc -l)
height=`/bin/echo -e "scale=1; $lstlenth + 7 " | /usr/bin/bc`
lstheight=`/bin/echo -e "scale=1; $lstlenth " | /usr/bin/bc`

select=$(whiptail --title "Code Image list"  --checklist \
"       Image name                                Mount node" $height 80 $lstheight \
${wtitem[@]} 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus = 0 ];
then
    echo "You've choose these images to be destroyed" $select
else
    echo "You chose Cancel."
fi
