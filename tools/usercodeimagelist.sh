#! /bin/bash
# Tool of generate user code image list
# Run as $LOGNAME, then generate $opstmp/ucdimglst.$LOGNAME

opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
source $lococlu/lcc.conf

for CODEIMG in `ls -lahs /images/vol* | grep -E "\.\."$LOGNAME | awk '{print $NF}'`
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
done > $opstmp/ucdimglst.$LOGNAME
