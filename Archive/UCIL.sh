#! /bin/bash
# Tool of generate User Code Image List
# Run as $LOGNAME, then generate $opstmp/ucdimglst.$LOGNAME
# Or run with -u parameter like:
# /receptionist/lococlu/tools/usercodeimagelist.sh -u "$username"

opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
source $lococlu/lcc.conf


if [[ -n "$1" && "$1" = "-u" ]]
then
    TGTUSER=`echo -e "$2"`
else
    TGTUSER=`echo -e "$LOGNAME"`
fi

# echo $TGTUSER
for CODEIMG in `ls -lahs /images/vol* | grep -E "\.\."$TGTUSER | awk '{print $NF}'`
do
    echo -en $CODEIMG
    echo -en "\t\t"
    MTNODE=`cat /receptionist/opstmp/secrt.sitrep.unirep.* | grep $CODEIMG | awk '{printf $1}'`
    if [ -n "$MTNODE" ]
    then
        echo -en $MTNODE
    else
        echo -en Unmount!
    fi
#    echo -en `cat /receptionist/opstmp/secrt.sitrep.unirep.* | grep $CODEIMG | awk '{printf $1}'`
    echo -e "\t\t"
done > $opstmp/ucdimglst.$TGTUSER
