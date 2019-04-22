#! /bin/bash

# noderep.sh single instance lock
pidpath=/tmp/noderep.pid
if [ -f "$pidpath" ]
    then
        kill `/bin/cat $pidpath`>/dev/null 2>&1
        /bin/rm -f $pidpath
fi
echo $$ >$pidpath

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
    /usr/bin/pkill -KILL -t  $PTSK
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
  DiffSum=`/usr/bin/expr $SumTock - $SumTick`
  DiffIdle=`/usr/bin/expr $IdleTock - $IdleTick`
  CPULoad=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2; 100 * ( $DiffSum - $DiffIdle ) / $DiffSum " | /usr/bin/bc)`
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
    GapT=`/bin/echo -e " $TockT - $TickT " | /usr/bin/bc`
    IOIndex=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2; 0 + 100 * $IOTock / $GapT - 100 * $IOTick / $GapT " | /usr/bin/bc)`
    LagT=`/bin/echo -e " $GapT - 1000 " | /usr/bin/bc`
}
# System load info structure in "Hostname"  "PerfIndex" "CPULoad" "Timestamp human" "Timestamp machine"
# Current perfIndex = (10*liveUsers + 100*Loadavg / PhysicCores) / PerfScore
# Current perfIndex = 10*liveUsers / PerfScore + 100*Loadavg / PhysicCores^2 / CPUFREQ
loadrep()
{
    SHORTLOAD=`/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'`
    USERCOUNT=`/usr/bin/w -h | /bin/grep -v root | /usr/bin/awk '{print $1}' | /usr/bin/sort | /usr/bin/uniq | /usr/bin/wc -l`
    PerfIndex=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2;  $IOIndex + $CPULoad " | /usr/bin/bc)`
    LoadIndex=`/bin/echo -e "scale=2; $IOIndex / 100 + 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE " | /usr/bin/bc`
    # USERCOUNT=`/usr/bin/w -h | /usr/bin/awk '{print $1}' | /usr/bin/sort | /usr/bin/uniq | /usr/bin/wc -l`
    /bin/echo -ne `/bin/hostname`"\t"
    #/bin/echo -e "scale=2; $IOIndex / 100 + 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE " | /usr/bin/bc | /usr/bin/tr "\n" "\t"
    /bin/echo -ne $LoadIndex"\t"$PerfIndex"\t"
    /bin/echo -ne "Load_C=$LoadIndex\tPerf_R=$PerfIndex\tCPU_RT=$CPULoad\tIOB_RT=$IOIndex\tNR=$LagT\tUSERC=$USERCOUNT"
    # /bin/echo -e "scale=2; $IOTock / 1000 - $IOTick / 1000 " | /usr/bin/bc | /usr/bin/tr "\n" "\t"
    # /bin/echo -ne "USERCOUNT=$USERCOUNT\t"
    # /bin/echo -ne "#DBG_loadrep 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE\t"
    /bin/echo -e "\t"`/bin/date +%s`
    /bin/echo -e "$endline" `/bin/hostname`
}

# IMGoN mount info structure v2 in "Hostname"  "Image Path" "Mount Point" "Timestamp human" "Timestamp machine"
imgonrep()
{
  for LOOPIMG in `COLUMNS=300 /sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}'`
  do
    /bin/echo -ne `/bin/hostname`"\t"
    /bin/echo -ne $LOOPIMG"\t"
    /bin/mount | /bin/grep $LOOPIMG | /usr/bin/awk -F " " '{printf $3}'
    # /bin/echo -e "\t"`/bin/date +%Y-%m%d-%H%M-%S`"\t"`/bin/date +%s`
    /bin/echo -e "\t"`/bin/date +%s`
  done
  /bin/echo -e "$endline" `/bin/hostname`
}

# User Live Scan info structure in "Hostname"  "Last Login Time" "UID" "Login From" "Timestamp machine"
ulscrep()
{
    for LIVEUSER in `COLUMNS=512 /usr/bin/w -h | /bin/grep -v root | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
    # for LIVEUSER in `COLUMNS=512 /usr/bin/w -h | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
    do
        /bin/echo -en `/bin/hostname`"\t"
        /usr/bin/w -h | /usr/bin/awk '{print $4"\t"$1"\t"$3}' | /usr/bin/sort | /usr/bin/uniq -f 1 | /bin/grep $LIVEUSER | /usr/bin/head -n 1 | /usr/bin/tr "\n" "\t"
        /bin/echo -e "\t"`/bin/date +%s`
    done
    /bin/echo -e "$endline" `/bin/hostname`
}

unirep.loadrep()
{
    SHORTLOAD=`/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'`
    USERCOUNT=`/usr/bin/w -h | /bin/grep -v root | /usr/bin/awk '{print $1}' | /usr/bin/sort | /usr/bin/uniq | /usr/bin/wc -l`
    PerfIndex=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2;  $IOIndex + $CPULoad " | /usr/bin/bc)`
    LoadIndex=`/bin/echo -e "scale=2; $IOIndex / 100 + 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE " | /usr/bin/bc`
    # USERCOUNT=`/usr/bin/w -h | /usr/bin/awk '{print $1}' | /usr/bin/sort | /usr/bin/uniq | /usr/bin/wc -l`
    /bin/echo -ne `/bin/hostname`"\t"
    /bin/echo -en "log=load\t"
    #/bin/echo -e "scale=2; $IOIndex / 100 + 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE " | /usr/bin/bc | /usr/bin/tr "\n" "\t"
    /bin/echo -ne $LoadIndex"\t"$PerfIndex"\t"
    /bin/echo -ne "Load_C=$LoadIndex\tPerf_R=$PerfIndex\tCPU=$CPULoad IO=$IOIndex\tNR=$LagT USERC=$USERCOUNT"
    # /bin/echo -e "scale=2; $IOTock / 1000 - $IOTick / 1000 " | /usr/bin/bc | /usr/bin/tr "\n" "\t"
    # /bin/echo -ne "USERCOUNT=$USERCOUNT\t"
    # /bin/echo -ne "#DBG_loadrep 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $PerfScore / $PHYSICORE\t"
    /bin/echo -e "\t"`/bin/date +%s`
}

# IMGoN mount info structure v2 in "Hostname"  "Image Path" "Mount Point" "Timestamp human" "Timestamp machine"
unirep.imgonrep()
{
  for LOOPIMG in `COLUMNS=300 /sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}'`
  do
    /bin/echo -ne `/bin/hostname`"\t"
    /bin/echo -en "log=imgon\t"
    /bin/echo -ne $LOOPIMG"\t"
    /bin/mount | /bin/grep $LOOPIMG | /usr/bin/awk -F " " '{printf $3}'
    # /bin/echo -e "\t"`/bin/date +%Y-%m%d-%H%M-%S`"\t"`/bin/date +%s`
    /bin/echo -e "\t"`/bin/date +%s`
  done
}

# User Live Scan info structure in "Hostname"  "Last Login Time" "UID" "Login From" "Timestamp machine"
unirep.ulscrep()
{
    for LIVEUSER in `COLUMNS=512 /usr/bin/w -h | /bin/grep -v root | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
    # for LIVEUSER in `COLUMNS=512 /usr/bin/w -h | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
    do
        /bin/echo -en `/bin/hostname`"\t"
        /bin/echo -en "log=ulsc\t"
        /usr/bin/w -h | /usr/bin/awk '{print $4"\t"$1"\t"$3}' | /usr/bin/sort | /usr/bin/uniq -f 1 | /bin/grep $LIVEUSER | /usr/bin/head -n 1 | /usr/bin/tr "\n" "\t"
        /bin/echo -e "\t"`/bin/date +%s`
    done
}




# Secure Realtime Text Copy v2, check text integrity, then drop real time text to NFS at this last step, with endline
# /bin/sed -i '$d' $REPLX # To cut last line, on receive side
secrtsend()
{
  for REPLX in `/bin/ls /var/log/rt.* 2>/dev/null`
  do
    CheckLineL1=`/usr/bin/tac $REPLX | /bin/sed -n '1p'`
    CheckLineL2=`/usr/bin/tac $REPLX | /bin/sed -n '2p'`
    if [ "$CheckLineL1"  == "$endline `/bin/hostname`" -a "$CheckLineL2"  != "$endline `/bin/hostname`" ]
    then
      REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
      cp $REPLX `/bin/echo -e "$opstmp/sec$REPLXNAME"`
      chmod 666 `/bin/echo -e "$opstmp/sec$REPLXNAME"`
    else
      # /bin/mv $REPLX.fail  #DBG
      /bin/rm $REPLX
    fi
  done
}

# General Operation Executor v2, run command in tickets with checkline as root
geoexec()
{
  /bin/ls $opstmp/secrt.ticket.geoexec.* 2>/dev/null
  HTKT=$opstmp/secrt.ticket.geoexec.`/bin/hostname`
  if [ -f "$HTKT" ]
    then
      exectime=`/bin/date +%Y-%m%d-%H%M-%S`
      tickettail=`/usr/bin/tac $HTKT | /bin/sed -n '1p'`
      tickettail2=`/usr/bin/tac $HTKT | /bin/sed -n '2p'`
      if [ "$endline `/bin/hostname`" == "$tickettail" -a "$endline `/bin/hostname`" != "$tickettail2" ]
      then
        # echo -e "#DBG\n tickettail=$tickettail\n tickettail2=$tickettail2" >> $HTKT
        /bin/mv $HTKT /var/log/ticket.$exectime.sh
        /bin/chmod 755 /var/log/ticket.$exectime.sh
        /var/log/ticket.$exectime.sh
        mv /var/log/ticket.$exectime.sh /var/log/done.$exectime.sh
        # cp /var/log/done.$exectime.sh $opstmp/../dbgtmp #DBG
      fi
  fi
}

# Main function loop
step=1 #Execution time interval, MUST UNDER 3600!!!
darwinawards
for (( i = 0; i < 3600; i=(i+step) ))
do
    cputick
    iotick
    sleep $step
    cputock
    iotock
    # loadrep > /var/log/rt.sitrep.load.`/bin/hostname`        #System load report
    # imgonrep > /var/log/rt.sitrep.imgon.`/bin/hostname`      #ImgON mount scan report
    # ulscrep > /var/log/rt.sitrep.ulsc.`/bin/hostname`        #User live scan report
    unirep.loadrep > /var/log/rt.sitrep.unirep.`/bin/hostname`        #System load report
    unirep.imgonrep >> /var/log/rt.sitrep.unirep.`/bin/hostname`      #ImgON mount scan report
    unirep.ulscrep >> /var/log/rt.sitrep.unirep.`/bin/hostname`
    /bin/echo -e "$endline" `/bin/hostname` >> /var/log/rt.sitrep.unirep.`/bin/hostname`
    secrtsend
    geoexec &

done
exit 0
