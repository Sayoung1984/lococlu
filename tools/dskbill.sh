#! /bin/bash
basepath=$(cd `dirname $0`; pwd)
#Get manager name from user name, $C_HTP to $C_MGR
getmgr()
{
    C_MGR=`/usr/bin/ldapsearch -h qed-ldap -x -LLL -b "ou=people,dc=qualcomm,dc=com" "uid=$C_HTP" | /bin/grep manager | /usr/bin/awk -F "[=,]" '{printf $2}'`
}

userlist()
{
    /bin/ls -slh /images/vol* | grep -v "\.\." | /bin/grep .img | /usr/bin/awk -F "[ .]" '{print $(NF-1)}' | /usr/bin/sort -u
}

userdskchk()
{
	UDS=`/bin/ls -sl /images/vol* | grep -v "\.\." | /bin/grep " "$C_USER.img | /usr/bin/awk '{x=x+$6} END {printf "%.0f\n",x/1024/1024/1024}'`
    UDU=`/bin/ls -sl /images/vol* | grep -v "\.\." | /bin/grep " "$C_USER.img | /usr/bin/awk '{x=x+$1} END {printf "%.0f\n",x/1024/1024}'`
}

mainfunc()
{
    /bin/echo -e "\nQuota\tUsed\tUser info"
    for C_HTP in `userlist`; do
        OPLINE=""
        C_MGR=""
        C_USER=$C_HTP
        userdskchk
        # /bin/echo DBG_main0a C_USER=$C_USER C_HTP=$C_HTP C_MGR=$C_MGR
        chkhtp=`/bin/grep $C_HTP $basepath/mgrlist`
        # /bin/echo DBG_main0c chkhtp=$chkhtp
        while [ ! -n "$chkhtp" ] ; do
            getmgr
            # /bin/echo DBG_main1a C_HTP=$C_HTP C_MGR=$C_MGR
            OPLINE="$C_MGR <---- $OPLINE"
            # /bin/echo DBG_main1b OPLINE=$OPLINE
            C_HTP=$C_MGR
            chkhtp=`/bin/grep $C_HTP $basepath/mgrlist`
            # /bin/echo DBG_main1c C_HTP=$C_HTP C_MGR=$C_MGR chkhtp=$chkhtp
        done
        /bin/echo -e "$UDS\t$UDU\t$OPLINE$C_USER"
    done | /usr/bin/sort -k3
    STAT_MAIN=done
}

dots()
{
    while [ ! -n "$STAT_MAIN" ]
    do
        /bin/echo -n . &
        /usr/bin/sleep 1
    done
    /bin/echo
}


/bin/df -h | /bin/grep -E " Use% | /images"
TTS=`/bin/df | /bin/grep " /images" | /usr/bin/awk '{x=x+$2} END {printf "%.0f\n",x/1024/1024}'`
TTU=`/bin/df | /bin/grep " /images" | /usr/bin/awk '{x=x+$3} END {printf "%.0f\n",x/1024/1024}'`
SUP=`/usr/bin/printf %.$2f $(/bin/echo -e  "scale=2; 100 * $TTU / $TTS " | /usr/bin/bc )`
AAS=`/bin/ls -sl /images/vol*/* | grep -v "\.\." | /usr/bin/awk '{x=x+$6} END {printf "%.0f\n",x/1024/1024/1024}'`
AUS=`/bin/ls -sl /images/vol*/* | grep -v "\.\." | /usr/bin/awk '{x=x+$1} END {printf "%.0f\n",x/1024/1024}'`
SVS=`/usr/bin/printf %.$2f $(/bin/echo -e  "scale=0; $TTU - $AUS " | /usr/bin/bc )`
/bin/echo -e "\nTotal disk space(G)= $TTS\tLogical used space(G)= $TTU\t$SUP% used"
/bin/echo -e "\nTotal assigned quota(G)= $AAS\tPhysical used space(G)= $AUS\tSpace saved by compress\\dedup(G)= $SVS\n"

/bin/echo -e "Gathering user space detail, please wait...\n\n"

fulllist=$(mainfunc)
# /bin/echo -e "RAWlist:\n$fulllist\n"
for mgr in `cat $basepath/mgrlist`; do
    TDS=`/bin/echo "$fulllist" | /bin/grep $mgr | /usr/bin/awk '{x=x+$1} END {printf "%.0f\n",x}'`
    TDU=`/bin/echo "$fulllist" | /bin/grep $mgr | /usr/bin/awk '{x=x+$2} END {printf "%.0f\n",x}'`
    /bin/echo -e "$mgr\tTotal Quota = $TDS G\tTotal used = $TDU G\n"
    /bin/echo "$fulllist" | /bin/grep $mgr
    /bin/echo -e "\n"
done

/bin/echo -e "\n\n"
/bin/date +%Y-%m%d-%H%M-%S
