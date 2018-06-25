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

# Calculate rounded CPU usage percentage (0~100) $CPULoad via /proc/stat, must be a time interval between cputick and cputock
cputick()
{
  LineTick=`/bin/cat /proc/stat | grep '^cpu ' | sed 's/^cpu[ \t]*//g'`
  SumTick=`/bin/echo $LineTick | /usr/bin/tr " " "+" | /usr/bin/bc`
  IdleTick=`/bin/echo $LineTick | awk '{print $4}'`
}

# Do the math and output $CPULoad
cputock()
{
  LineTock=`/bin/cat /proc/stat | grep '^cpu ' | sed 's/^cpu[ \t]*//g'`
  SumTock=`/bin/echo $LineTock | /usr/bin/tr " " "+" | /usr/bin/bc`
  IdleTock=`/bin/echo $LineTock | awk '{print $4}'`
  DiffSum=`/usr/bin/expr $SumTock - $SumTick`
  DiffIdle=`/usr/bin/expr $IdleTock - $IdleTick`
  CPULoad=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2; 100 * ( $DiffSum - $DiffIdle ) / $DiffSum " | /usr/bin/bc)`
}

# System load info structure in "Hostname"  "PerfIndex" "CPULoad" "Timestamp human" "Timestamp machine"
# Current perfIndex = (10*liveUsers + 100*Loadavg / PhysicCores) / PerfScore
# Current perfIndex = 10*liveUsers / PerfScore + 100*Loadavg / CPUFREQ
loadrep()
{
    SHORTLOAD=`/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'`
    USERCOUNT=`/usr/bin/w -h | grep -v "sshd" | /usr/bin/awk '{print $1}' | /usr/bin/sort | /usr/bin/uniq | /usr/bin/wc -l`
    /bin/echo -ne `/bin/hostname`"\t"
    /bin/echo -e "scale=2; 10 * $USERCOUNT / $PerfScore + 100 * $SHORTLOAD / $CPUFREQ " | /usr/bin/bc | /usr/bin/tr "\n" "\t"
    # /bin/echo -ne "#DBG_loadrep PHYSICORE=$PHYSICORE CPUFREQ=$CPUFREQ PerfScore=$PerfScore\t"
    /bin/echo -ne $CPULoad"\t"
    /bin/echo -ne $USERCOUNT"\t"
    /bin/echo -e "\t"`/bin/date +%s`
    /bin/echo -e "$endline" `hostname`
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
  /bin/echo -e "$endline" `hostname`
}

# User Live Scan info structure in "Hostname"  "Last Login Time" "UID" "Login From" "Timestamp machine"
ulscrep()
{
    for LIVEUSER in `COLUMNS=512 /usr/bin/w -h | /bin/grep -v sshd | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
    do
        /bin/echo -en `/bin/hostname`"\t"
        /usr/bin/w -h | /usr/bin/awk '{print $4"\t"$1"\t"$3}' | /usr/bin/sort | /usr/bin/uniq -f 1 | /bin/grep $LIVEUSER | /usr/bin/head -n 1 | /usr/bin/tr "\n" "\t"
        /bin/echo -e "\t"`/bin/date +%s`
    done
    /bin/echo -e "$endline" `hostname`
}

# Secure Realtime Text Copy v2, check text integrity, then drop real time text to NFS at this last step, with endline
# /bin/sed -i '$d' $REPLX # To cut last line, on receive side
secrtsend()
{
  for REPLX in `/bin/ls /var/log/rt.* 2>/dev/null`
  do
    CheckLineL1=`/usr/bin/tac $REPLX | sed -n '1p'`
    CheckLineL2=`/usr/bin/tac $REPLX | sed -n '2p'`
    if [ "$CheckLineL1"  == "$endline `hostname`" -a "$CheckLineL2"  != "$endline `hostname`" ]
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
  ls $opstmp/secrt.ticket.geoexec.*
  HTKT=$opstmp/secrt.ticket.geoexec.`hostname`
  if [ -f "$HTKT" ]
    then
      exectime=`/bin/date +%Y-%m%d-%H%M-%S`
      tickettail=`/usr/bin/tac $HTKT | sed -n '1p'`
      tickettail2=`/usr/bin/tac $HTKT | sed -n '2p'`
      if [ "$endline `hostname`" == "$tickettail" -a "$endline `hostname`" != "$tickettail2" ]
      then
        # echo -e "#DBG\n tickettail=$tickettail\n tickettail2=$tickettail2" >> $HTKT
        /bin/mv $HTKT /var/log/ticket.$exectime.sh
        /bin/chmod u+x /var/log/ticket.$exectime.sh
        /var/log/ticket.$exectime.sh
        mv /var/log/ticket.$exectime.sh /var/log/done.$exectime.sh
        # cp /var/log/done.$exectime.sh $opstmp/../dbgtmp #DBG
      fi
  fi
}

# Main function loop
step=1 #Execution time interval, MUST UNDER 3600!!!
for (( i = 0; i < 3600; i=(i+step) ))
do
  cputock
  loadrep > /var/log/rt.sitrep.load.`hostname`
  imgonrep > /var/log/rt.sitrep.imgon.`hostname`
  ulscrep > /var/log/rt.sitrep.ulsc.`hostname`      #User live scan report
  secrtsend
  geoexec
  cputick
  sleep $step
done
exit 0
