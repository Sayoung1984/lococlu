#! /bin/bash
# Tool of user self service code images deleter
# Or run with -u parameter like:
# /receptionist/lococlu/tools/imgdel.sh -i "$TgtHitList"

COLUMNS=512
endline="###---###---###---###---###"
opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
source $lococlu/lcc.conf

# Define the globle IMGoN mount root $MOUNTROOT
CURDOM=`/bin/hostname -d`
while [ ! -n "$MOUNTROOT" ];
do
  case $CURDOM in
    28.sap|28.SAP)
      MOUNTROOT="/home/28/"
      break
      ;;
    ap.qualcomm.com|AP.QUALCOMM.COM|qualcomm.com|QUALCOMM.COM)
      MOUNTROOT="/local/mnt/workspace/"
      # /bin/cat /var/adm/gv/user > $lococlu/user.conf
      break
      ;;
    *)
    /bin/echo -e "\nUnknown domain, please choose define the image mount root:\n"
    read MOUNTROOT
    break
    ;;
  esac
done
MOUNTROOT=`/bin/echo $MOUNTROOT | /bin/sed '/\/$/!  s/^.*$/&\//'`

# Secure Realtime Text Send v2, check text integrity, then drop real time text to NFS at this last step, with endline
# /bin/sed -i '$d' $REPLX # To cat last line, on receive side
secrtsend()
{
    for REPLX in `/bin/ls /var/log/rt.*`
    do
      CheckLineL1=`/usr/bin/tac $REPLX | /bin/sed -n '1p'`
      CheckLineL2=`/usr/bin/tac $REPLX | /bin/sed -n '2p'`
      if [ "$CheckLineL1"  == "$endline `/bin/hostname`" -a "$CheckLineL2"  != "$endline `/bin/hostname`" ]
      then
        REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
        /bin/cp $REPLX `/bin/echo -e "$opstmp/sec$REPLXNAME"`
        /bin/chmod 666 `/bin/echo -e "$opstmp/sec$REPLXNAME"`
      else
        # /bin/mv $REPLX.fail  #DBG
        /bin/rm $REPLX
      fi
    done
}


# Subfunction to send image delete ticket:
# 0. Got $TGTUSER, $TGTNode from $TgtHitList, then send ticket of:
# 1. Restart samba service while unmount items of $TgtHitList from $TGTNode
# 2. rm $MTPOINT folder if there's any
# 3. rm items of $TgtHitList
delimg()
{
    TGTUSER=`/bin/echo -e $TgtHitList |/usr/bin/awk  -F ".img" '{print $NR}' |/usr/bin/awk  -F "." '{print $NF}'`
    TGTNode=`/bin/cat /receptionist/opstmp/secrt.sitrep.unirep.* | /bin/grep log=imgon | /bin/grep /$TGTUSER.img |/usr/bin/awk  '{print $NR}'`
    # /bin/echo -e "TGTUSER=$TGTUSER; TGTNode=$TGTNode; \nTgtHitList=$TgtHitList"
    if [ ! -n "$TGTNode" ]
    then
        TGTNode=`/bin/cat /receptionist/opstmp/secrt.sitrep.unirep.* | /bin/grep load | /usr/bin/sort -r -k 11 | /usr/bin/head -n 1 |/usr/bin/awk  '{print $NR}'`
    fi
    /bin/echo -e "#! /bin/bash\nMOUNTROOT=\"$MOUNTROOT\"\nTGTUSER=\"$TGTUSER\"\nTGTNode=\"$TGTNode\"\nTgtHitList=\"$TgtHitList\"" > $opstmp/draft.rt.ticket.geoexec
    /bin/cat >> $opstmp/draft.rt.ticket.geoexec << "MAINFUNC"
    # Ticket of delete user code image
    for TGTIMG in $TgtHitList
    do
        TGTIMGPATH=`/usr/bin/find /images/vol00/*.img -type f | /bin/grep $TGTIMG$`
        MountPath=`/bin/cat /receptionist/opstmp/secrt.sitrep.unirep.* | /bin/grep log=imgon | /bin/grep $TGTIMG |/usr/bin/awk  '{print $4}'`
        if [ -n $MountPath ];
        then
            LoopDev=`/sbin/losetup -a | /bin/grep $MountPath |/usr/bin/awk  -F ":" '{print $NR}'`
            while [ -n "$MountPath" ]
            do
              /usr/sbin/service smbd restart
              /usr/sbin/service nmbd restart
              /bin/umount -l $MountPath
              /bin/sleep 1
              MountPath=`/bin/cat /receptionist/opstmp/secrt.sitrep.unirep.* | /bin/grep log=imgon | /bin/grep $TGTIMG |/usr/bin/awk  '{print $4}'`
            done
            /usr/sbin/service smbd restart
            /usr/sbin/service nmbd restart
            /bin/rm -f /dev/$LoopDev
            /bin/rm -fr $MountPath &
        fi
        /bin/rm -f $TGTIMGPATH &
    done

MAINFUNC
/bin/echo -e "$endline $TGTNode" >> $opstmp/draft.rt.ticket.geoexec
/bin/chmod 666 $opstmp/draft.rt.ticket.geoexec
/bin/mv $opstmp/draft.rt.ticket.geoexec $opstmp/secrt.ticket.geoexec.$TGTNode

LongTgtHitList=`/bin/echo  \($TgtHitList\) | tr " " "|"`
/bin/echo -e "\nDeleteing images on $TGTNode...\c"
/bin/sleep 1
delcheck=`/usr/bin/find /images/vol00/*.img -type f 2>/dev/null | /bin/grep "\.\.$LOGNAME\.img$" | /bin/egrep "$LongTgtHitList"`
while [ -n "$delcheck" ]
do
    /bin/echo -n .
    delcheck=`/usr/bin/find /images/vol00/*.img -type f 2>/dev/null | /bin/grep "\.\.$LOGNAME\.img$" | /bin/egrep "$LongTgtHitList"`
    # /bin/echo $delcheck
    /bin/sleep 1
done
/bin/echo -e "\n\nDeleteing complete, please check."
    # /bin/cat $opstmp/draft.rt.ticket.geoexec
}

# The Silence mode without warning
while [ -n "$1" ]
do
  case "$1" in
    -i)
        /bin/echo "Found -i option"
        /bin/echo -e "value=$2"
        TgtHitList=`/bin/echo  -e "$2"`
        shift
        delimg
        exit
        ;;
    *)
        ;;
esac
shift
done


# Open warning
read -p "Deleted image won't be restorable, continue? (Y/N)" USER_OPS
    case $USER_OPS in
        Y|y|YES|Yes|yes)
            /bin/echo -e "\nProceeding to image deleter now...\n"
            ;;
        N|n|NO|No|no)
            /bin/echo -e "\nYou've exit the image deleter.\n"
            exit
            ;;
        *)
            /bin/echo -e "\nInvalid choice, please choose Yes or No, exiting image deleter now.\n"
            exit
            ;;
    esac

# List of images to delete

# $lococlu/tools/UCIL.sh
# derliste=`/bin/cat $opstmp/ucdimglst.$LOGNAME |/usr/bin/awk  '{print $0, "OFF"}'`
# # /bin/echo -e "$derliste"
# lstlenth=$(echo -e "$derliste" | /usr/bin/wc -l)
# height=`/bin/echo -e "scale=1; $lstlenth + 7 " | /usr/bin/bc`
# lstheight=`/bin/echo -e "scale=1; $lstlenth " | /usr/bin/bc`

read -ra wtitem <<< $(for CODEIMG in `ls -lahs /images/vol* | /bin/grep -E "\.\."$LOGNAME |/usr/bin/awk  '{print $NF}'`
do
    /bin/echo -en $CODEIMG
    /bin/echo -en "\t\t"
    MTNODE=`/bin/cat /receptionist/opstmp/secrt.sitrep.unirep.* | /bin/grep $CODEIMG |/usr/bin/awk  '{printf $1}'`
    if [ -n "$MTNODE" ]
    then
        /bin/echo -en $MTNODE
    else
        /bin/echo -en Unmount!
    fi
#    /bin/echo -en `/bin/cat /receptionist/opstmp/secrt.sitrep.unirep.* | /bin/grep $CODEIMG |/usr/bin/awk  '{printf $1}'`
    /bin/echo -e "\t\t"OFF
done)
# /bin/echo ${wtitem[@]}

lstlenth=$(for v in ${wtitem[@]}
do
/bin/echo $v;
done | /bin/grep .img | /usr/bin/wc -l)
height=`/bin/echo -e "scale=1; $lstlenth + 7 " | /usr/bin/bc`
lstheight=`/bin/echo -e "scale=1; $lstlenth " | /usr/bin/bc`

TgtHitList=$(/bin/whiptail --title "Code Image list"  --checklist --separate-output \
"       Image name                                Mount node" $height 80 $lstheight \
${wtitem[@]} 3>&1 1>&2 2>&3)
# List operations

exitstatus=$?
if [ $exitstatus = 1 ];
then
    /bin/echo "Image delete canceled."
elif [[ $exitstatus = 0 && -n $TgtHitList ]]
then
    /bin/echo -e "You chose these images to be destroyed:"
    /bin/echo -e "$TgtHitList\n"
    read -p "Last warning, continue? (Y/N)" USER_OPS
        case $USER_OPS in
            Y|y|YES|Yes|yes)
                /bin/echo -e "\nProceeding to delete now...\n"
                ;;
            N|n|NO|No|no)
                /bin/echo -e "\nGood choice, exiting image deleter.\n"
                exit
                ;;
            *)
                /bin/echo -e "\nInvalid choice, please choose Yes or No, exiting image deleter now.\n"
                exit
                ;;
        esac

    delimg
    # for imgdel in $TgtHitList
    # do
    #     /bin/echo -e "Kill $imgdel !!!!"
    # done

elif [[ $exitstatus = 0 && ! -n $TgtHitList ]]
then
    /bin/echo -e "No image to delete, exit."
else [ $exitstatus = 255 ]
    /bin/echo -e "Image delete tool exit."
fi
# /bin/echo -e "$? $0 $1 $2"
