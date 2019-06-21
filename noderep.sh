#! /bin/bash

# noderep.sh single instance lock
pidpath=/tmp/noderep.pid
if [ -f "$pidpath" ]
    then
        kill -9 `/bin/cat $pidpath`>/dev/null 2>&1
        /bin/rm -f $pidpath
fi
echo $$ >$pidpath

/usr/bin/renice -n -4 -p $$

COLUMNS=512
endline="###---###---###---###---###"
opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
source $lococlu/lcc.conf
# USERDIFF=$(diff -q $lococlu/user.conf /var/adm/gv/user)
# if [ "$USERDIFF" != "" ]
# then
#     cp $lococlu/user.conf /var/adm/gv/user
# fi

# /bin/echo -e "#DBG_lcc.conf \nCOLUMNS=$COLUMNS\nendline=$endline\nopstmp=$opstmp\nlococlu=$lococlu\ndskinitsz=$dskinitsz\n#\n" > /root/DBG_lcc.conf
# /bin/cat $lococlu/lcc.conf >> /root/DBG_lcc.conf #DBG

hostname=`/bin/hostname`

# Fixed parameters for CPU info
LOGICORE=`nproc --all`
TPCORE=`/usr/bin/lscpu | /bin/grep -e "Thread" | /usr/bin/awk -F " " '{print $4}'`
PHYSICORE=`/usr/bin/expr $LOGICORE / $TPCORE`

if [ -n "$(/usr/bin/lscpu | /bin/grep -i intel)" ]
then
	CPUFREQ=`/bin/cat /proc/cpuinfo | /bin/grep "model name" | /usr/bin/uniq | /bin/sed -r 's/.*@ (.*)GHz.*/\1/'`
else
	CPUFREQM=`/usr/bin/lscpu | /bin/grep "CPU MHz" | /usr/bin/awk -F " " '{print $3}'`
	CPUFREQ=`/bin/echo -e "scale=1; $CPUFREQM / 1000 " | /usr/bin/bc`
fi

PerfScore=`/bin/echo -e "scale=1; $CPUFREQ * $PHYSICORE " | /usr/bin/bc`

# Darwin awards to kill users not connecting via cluster head
darwinawards()
{
for PTSK in `/usr/bin/who | /bin/grep -Ev "head|root|sayoungh|ziyij|evenye|:0 " | /usr/bin/awk '{print $2}'`
do
    /usr/bin/pkill -KILL -t $PTSK
done
}

# Calculate rounded CPU usage percentage (0~100) $CPULoad via /proc/stat, must be a time interval between cputick and cputock
cputick()
{
  LineTick=`/bin/cat /proc/stat | /bin/grep '^cpu ' | /bin/sed 's/^cpu[ \t]*//g'`
  SumTick=`/bin/echo $LineTick | /usr/bin/tr " " "+" | /usr/bin/bc`
  IdleTick=`/bin/echo $LineTick | /usr/bin/awk '{print $4}'`
}

# Do the math and output $CPULoad
cputock()
{
  LineTock=`/bin/cat /proc/stat | /bin/grep '^cpu ' | /bin/sed 's/^cpu[ \t]*//g'`
  SumTock=`/bin/echo $LineTock | /usr/bin/tr " " "+" | /usr/bin/bc`
  IdleTock=`/bin/echo $LineTock | /usr/bin/awk '{print $4}'`
  # DiffSum=`/usr/bin/expr $SumTock - $SumTick`
  # DiffIdle=`/usr/bin/expr $IdleTock - $IdleTick`
  # CPULoad=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2; 100 * ( $DiffSum - $DiffIdle ) / $DiffSum " | /usr/bin/bc)`
  CPULoad=$((100*($SumTock-$SumTick-$IdleTock+$IdleTick)/($SumTock-$SumTick)))
}

iotick()
{
    TickT=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    IOTick=`/bin/cat /proc/diskstats | /bin/grep loop | /usr/bin/awk '{x=x+$(NF-1)} END {print x}'`
}

iotock()
{
    TockT=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    IOTock=`/bin/cat /proc/diskstats | /bin/grep loop | /usr/bin/awk '{x=x+$(NF-1)} END {print x}'`
    # GapT=`/bin/echo -e " $TockT - $TickT " | /usr/bin/bc`
    # IOIndex=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2; 0 + 100 * $IOTock / $GapT - 100 * $IOTick / $GapT " | /usr/bin/bc)`
    IOIndex=$((100*$IOTock/($TockT-$TickT)-100*$IOTick/($TockT-$TickT)))
}

unirep.loadrep()
{
    # SHORTLOAD=`/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'`
    # USERCOUNT=`/usr/bin/w -h | /bin/grep -v root | /usr/bin/awk '{print $1}' | /usr/bin/sort | /usr/bin/uniq | /usr/bin/wc -l`
    # PerfIndex=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2;  sqrt( ($IOIndex / 1.5) ^2 + $CPULoad ^2 ) " | /usr/bin/bc)`
    # LoadIndex=`/bin/echo -e "scale=2; $IOIndex / 100 + 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE " | /usr/bin/bc`
    # # USERCOUNT=`/usr/bin/w -h | /usr/bin/awk '{print $1}' | /usr/bin/sort | /usr/bin/uniq | /usr/bin/wc -l`
    # /bin/echo -ne `/bin/hostname`"\t"
    # /bin/echo -en "log=load\t"
    # #/bin/echo -e "scale=2; $IOIndex / 100 + 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE " | /usr/bin/bc | /usr/bin/tr "\n" "\t"
    # /bin/echo -ne $LoadIndex"\t"$PerfIndex"\t"
    # /bin/echo -ne "Load_C=$LoadIndex\tPerf_R=$PerfIndex\tCPU=$CPULoad IO=$IOIndex\tNR=$LagT USERC=$USERCOUNT"
    # # /bin/echo -e "scale=2; $IOTock / 1000 - $IOTick / 1000 " | /usr/bin/bc | /usr/bin/tr "\n" "\t"
    # # /bin/echo -ne "USERCOUNT=$USERCOUNT\t"
    # # /bin/echo -ne "#DBG_loadrep 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE\t"
    # /bin/echo -e "\t"`/bin/date +%s`
    #
    ## unirep.loadrep HP version
    SHORTLOAD=`/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'`
    USERCOUNT=`/usr/bin/who | /bin/grep -v 'root\|unknown' | /usr/bin/awk '{print $1}' | /usr/bin/sort | /usr/bin/uniq | /usr/bin/wc -l`
    PerfIndex=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2;  sqrt( ($IOIndex / 1.5) ^2 + $CPULoad ^2 ) " | /usr/bin/bc)`
    LoadIndex=`/bin/echo -e "scale=2; $IOIndex / 100 + 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE " | /usr/bin/bc`
    FR=`/bin/cat /tmp/FR`
    /bin/echo -e "$hostname\tlog=load\t$LoadIndex\t$PerfIndex\tLoad_C=$LoadIndex\tPerf_R=$PerfIndex\tCPU=$CPULoad IO=$IOIndex\tUSERC=$USERCOUNT FR=$FR\t"`/bin/date +%s`
}

# IMGoN mount info structure v2 in "Hostname"  "Image Path" "Mount Point" "Timestamp human" "Timestamp machine"
unirep.imgonrep()
{
    # for LOOPIMG in `COLUMNS=300 /sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}'`
    # do
    #   /bin/echo -ne `/bin/hostname`"\t"
    #   /bin/echo -en "log=imgon\t"
    #   /bin/echo -ne $LOOPIMG"\t"
    #   /bin/mount | /bin/grep $LOOPIMG | /usr/bin/awk -F " " '{printf $3}'
    #   # /bin/echo -e "\t"`/bin/date +%Y-%m%d-%H%M-%S`"\t"`/bin/date +%s`
    #   /bin/echo -e "\t"`/bin/date +%s`
    # done
    #
    ## unirep.imgonrep HP version
    MarkT=`/bin/date +%s`
    /bin/mount | /bin/grep ".img " |  /usr/bin/awk '{print $1"\t"$3}' | /usr/bin/sort -k 2 | /bin/sed "s/^/$hostname\tlog=imgon\t&/g" | /bin/sed "s/$/&\t$MarkT/g"
}

# User Live Scan info structure in "Hostname"  "Last Login Time" "UID" "Login From" "Timestamp machine"
unirep.ulscrep()
{
    # for LIVEUSER in `COLUMNS=512 /usr/bin/w -h | /bin/grep -v root | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
    # # for LIVEUSER in `COLUMNS=512 /usr/bin/w -h | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
    # do
    #     /bin/echo -en `/bin/hostname`"\t"
    #     /bin/echo -en "log=ulsc\t"
    #     /usr/bin/w -h | /usr/bin/awk '{print $4"\t"$1"\t"$3}' | /usr/bin/sort | /usr/bin/uniq -f 1 | /bin/grep $LIVEUSER | /usr/bin/head -n 1 | /usr/bin/tr "\n" "\t"
    #     /bin/echo -e "\t"`/bin/date +%s`
    # done
    #
    ## unirep.ulscrep HP version
    MarkT=`/bin/date +%s`
    /usr/bin/who | /bin/grep -v 'root\|unknown' | /usr/bin/awk -F "[()]" '{print $1"\t"$2}' | /usr/bin/awk '{print $3"_"$4"\t"$1"\t\t"$5}' | /bin/sed "s/head-sh-01.*/head-sh-01/g" | /usr/bin/sort -k 2 | /usr/bin/uniq -f 1 | /bin/sed "s/^/$hostname\tlog=ulsc\t&/g" | /bin/sed "s/$/&\t$MarkT/g"
}




# Secure Realtime Text Copy v2, check text integrity, then drop real time text to NFS at this last step, with endline
# /bin/sed -i '$d' $REPLX # To cut last line, on receive side
secrtsend()
{
  for REPLX in `/bin/ls /tmp/rt.* 2>/dev/null`
  do
    CheckLineL1=`/usr/bin/tac $REPLX | /bin/sed -n '1p'`
    CheckLineL2=`/usr/bin/tac $REPLX | /bin/sed -n '2p'`
    if [ "$CheckLineL1"  == "$endline $hostname" -a "$CheckLineL2"  != "$endline $hostname" ]
    then
      REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/tmp/" '{print $2}'`
      /bin/mv $REPLX `/bin/echo -e "$opstmp/sec$REPLXNAME"`
      /bin/chmod 666 `/bin/echo -e "$opstmp/sec$REPLXNAME"`
    else
      # /bin/mv $REPLX.fail  #DBG
      /bin/rm -f $REPLX
    fi
  done
}

# General Operation Executor v2, run command in tickets with checkline as root
geoexec()
{
#  /bin/ls $opstmp/secrt.ticket.geoexec.* 2>/dev/null
  HTKT=$opstmp/secrt.ticket.geoexec.$hostname
  /bin/ls $HTKT 2>/dev/null
  if [ -f "$HTKT" ]
    then
      exectime=`/bin/date +%Y-%m%d-%H%M-%S`
      tickettail=`/usr/bin/tac $HTKT | /bin/sed -n '1p'`
      tickettail2=`/usr/bin/tac $HTKT | /bin/sed -n '2p'`
      if [ "$endline $hostname" == "$tickettail" -a "$endline $hostname" != "$tickettail2" ]
      then
        # echo -e "#DBG\n tickettail=$tickettail\n tickettail2=$tickettail2" >> $HTKT
        /bin/mv $HTKT /var/log/ticket.$exectime.sh
        /bin/chmod a+x /var/log/ticket.$exectime.sh
        /var/log/ticket.$exectime.sh
        mv /var/log/ticket.$exectime.sh /var/log/done.$exectime.sh
        # cp /var/log/done.$exectime.sh $opstmp/../dbgtmp #DBG
      fi
  fi
}

# Main function loop
step=1 #Execution time interval, MUST UNDER 3600!!!
darwinawards &
/bin/echo -n > /tmp/nodereplag.log
for (( i = 0; i < 3600; i=(i+step) ))
do
    TickT0=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    cputick
    iotick
    sleep $step
    TockT0=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    cputock
    iotock
    TockT_=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    localsitrep=/tmp/lsr.rt.sitrep.unirep
    unirep.loadrep > $localsitrep
    TockT1=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    unirep.imgonrep >> $localsitrep
    TockT2=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    unirep.ulscrep >> $localsitrep
    TockT3=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    /bin/echo -e "$endline" $hostname >> $localsitrep
    /bin/mv $localsitrep /tmp/rt.sitrep.unirep.$hostname
    TockT4=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    secrtsend &
    TockT5=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    geoexec
    TockTE1=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    TockTE2=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    TockTE3=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    TockTEnd=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    M1=`/bin/echo -e " $TockT0 - $TickT0 - 1000 " | /usr/bin/bc`
    M2=`/bin/echo -e " $TockT_ - $TockT0 " | /usr/bin/bc`
    MR=`/bin/echo -e " $TockT_ - $TickT0- 1000 " | /usr/bin/bc`
    G1=`/bin/echo -e " $TockT1 - $TockT_ " | /usr/bin/bc`
    G2=`/bin/echo -e " $TockT2 - $TockT1 " | /usr/bin/bc`
    G3=`/bin/echo -e " $TockT3 - $TockT2 " | /usr/bin/bc`
    GR=`/bin/echo -e " $TockT3 - $TockT_ " | /usr/bin/bc`
    S1=`/bin/echo -e " $TockT4 - $TockT3 " | /usr/bin/bc`
    S2=`/bin/echo -e " $TockT5 - $TockT4 " | /usr/bin/bc`
    SR=`/bin/echo -e " $TockT5 - $TockT3 " | /usr/bin/bc`
    XR=`/bin/echo -e " $TockTE1 - $TockT5 " | /usr/bin/bc`
    ER=`/bin/echo -e " $TockTEnd / 3 - $TockTE1 / 3 " | /usr/bin/bc`
    FR=`/bin/echo -e " $TockTEnd - $TickT0 - 1000 " | /usr/bin/bc`
    /bin/echo -e "$hostname\t MR=$MR\t= $M1 + $M2\t GR=$GR\t=$G1 + $G2 + $G3\t\tSR=$SR\t=$S1+$S2\t\tXR=$XR\tER=$ER\tFR=$FR\tCPU=$CPULoad IO=$IOIndex\t"`/bin/date +%s` >> /tmp/nodereplag.log
    /bin/echo $FR > /tmp/FR
done
exit 0
