#! /bin/bash

# Node Sitrep generator HP revision block 2, execute sequence structure renewed and dedicated performance debug module added.

# noderep.sh single instance lock
pidpath=/tmp/NR_PID
if [ -f "$pidpath" ]
then
    for ktgt in `/bin/ps -aux | /bin/grep -vE "$$|grep" | /bin/grep noderep.sh | /usr/bin/awk '{print $2}'`
    do
    {
        kill -9 $ktgt 2>/dev/null
    }&
    done
    # kill -9 `/bin/cat $pidpath` > /dev/null 2>&1
    /bin/rm -f $pidpath
fi
echo $$ >$pidpath

/usr/bin/renice -n -4 -p $$

COLUMNS=512
endline="###---###---###---###---###"
opstmp=/receptionist/opstmp
lococlu=/receptionist/lococlu
source $lococlu/lcc.conf

# /bin/echo -e "#DBG_lcc.conf \nCOLUMNS=$COLUMNS\nendline=$endline\nopstmp=$opstmp\nlococlu=$lococlu\ndskinitsz=$dskinitsz\n#\n" > /root/DBG_lcc.conf
# /bin/cat $lococlu/lcc.conf >> /root/DBG_lcc.conf #DBG

HOSTNAME=`/bin/hostname`

# For Ubuntu 1.04=+, filter local snap loop devices
SNAP=`/bin/lsblk | grep "loop.* /snap/" |  awk '{printf $1 "|"}' | sed 's/[|]$//g'`
if [ ! -n "$SNAP" ]
then
    SNAP="No Snap Loop Device!"
fi

# Checkpath for geoexec
HTKT=$opstmp/secrt.ticket.geoexec.$HOSTNAME

# Output target for unirep
localsitrep=/tmp/lsr.rt.sitrep.unirep

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

PERFScore=`/bin/echo -e "scale=1; $CPUFREQ * $PHYSICORE " | /usr/bin/bc`

# Darwin awards for imbeciles not connecting via cluster head
darwinawards()
{
for PTSK in `/usr/bin/who | /bin/grep -Ev "head|root|sayoungh|ziyij|evenye|:0 " | /usr/bin/awk '{print $2}'`
do
    /usr/bin/pkill -KILL -t $PTSK
done
}

# Tick signal generator, generate ( $CPU_LineTickEx $IO_DTickEx $IO_TTickEx )
cpuiotick()
{
    CPU_LineTickEx=`/bin/grep "^cpu " /proc/stat | /bin/sed 's/^cpu[ \t]*//g'`
    IO_DTickEx=`/bin/grep loop /proc/diskstats | /bin/grep -vE "$SNAP" | /usr/bin/awk '{x=x+$(NF-1)} END {print x}'`
    IO_TTickEx=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
}


# Tock signal generator, concurrently write below data into /tmp/NR_LastRep:
# $CPU_SumTock $CPU_IdleTock $IO_DTock $IO_TTock $CPU_SumTick $CPU_IdleTick $IO_TTick $IO_DTickEx $UserCount $ShortLoad
cpuiotock()
{
    # CPU_LineTock=`/bin/grep "^cpu " /proc/stat | /bin/sed 's/^cpu[ \t]*//g'`
    /bin/echo -e "export CPU_LineTock=\"`/bin/grep "^cpu " /proc/stat | /bin/sed 's/^cpu[ \t]*//g'`\"" >> /tmp/NR_LastRep &
    /bin/echo -e "export IO_DTock=`/bin/grep loop /proc/diskstats | /bin/grep -vE "$SNAP" | /usr/bin/awk '{x=x+$(NF-1)} END {print x}'`" >> /tmp/NR_LastRep &
    /bin/echo -e "export IO_TTock=`/bin/echo $[$(/bin/date +%s%N)/1000000]`" >> /tmp/NR_LastRep
    # {
    # CPU_SumTock=`/bin/echo -e "$CPU_LineTock" | /usr/bin/tr " " "+" | /usr/bin/bc`
    # CPU_IdleTock=`/bin/echo -e "$CPU_LineTock" | /usr/bin/awk '{print $4}'`
    # /bin/echo -e "export CPU_SumTock=$CPU_SumTock\nexport CPU_IdleTock=$CPU_IdleTock" >> /tmp/NR_LastRep
    # }&


}

calcmain()
{
    TmC_0=$[$(/bin/date +%s%N)/1000000] #DBG_calcmain       #lagcalc basic
    # Fetch data

    # eval `/bin/grep CPU_SumTick= /tmp/NR_LastRep`
    # eval `/bin/grep CPU_IdleTick= /tmp/NR_LastRep`
    # eval `/bin/grep IO_DTick= /tmp/NR_LastRep`
    # eval `/bin/grep IO_TTick= /tmp/NR_LastRep`
    # eval `/bin/grep CPU_SumTock= /tmp/NR_LastRep`
    # eval `/bin/grep CPU_IdleTock= /tmp/NR_LastRep`
    # eval `/bin/grep IO_DTock= /tmp/NR_LastRep`
    # eval `/bin/grep IO_TTock= /tmp/NR_LastRep`
    #
    # eval `/bin/grep UserCount= /tmp/NR_LastRep`
    # eval `/bin/grep ShortLoad= /tmp/NR_LastRep`
    # eval `/bin/grep LR= /tmp/NR_LastRep`
    # eval `/bin/grep AR= /tmp/NR_LastRep`
    #
    # /bin/cat /tmp/NR_LastRep > /tmp/NR_LastRep2
    eval $(/usr/bin/sort /tmp/NR_LastRep)
    # CKUserCount=`/bin/grep " UserCount=" /tmp/NR_LastRep | awk -F "=" '{print $2}'`
    # TmC_1=$[$(/bin/date +%s%N)/1000000] #DBG_calcmain
    #
    # TimeTable=`/bin/cat /tmp/NR_LastRep | /bin/grep "export Tm" | /usr/bin/sort -r`
    #
    infowho=`/usr/bin/who`
    infomount=`/bin/mount`


    /bin/echo -e "export TmM_S=$TmM_0" > /tmp/NR_LastRep #!!! The start of NR_LastRep loop !!!
    # /bin/echo -e "# DBG Got CKUserCount=$CKUserCount" >> /tmp/NR_LastRep & #DBG_allrange

    # TmC_2=$[$(/bin/date +%s%N)/1000000] #DBG_calcmain

    AR=$(($TmM_0 - $TmM_S - 1000)) #DBG_allrange
    # /bin/echo -e "export AR=$AR" >> /tmp/NR_LastRep & #DBG_allrange

    RR=$(($TmR_1 - $TmM_S))  #DBG_reallenth       #lagcalc basic
    # CalcCPU
    CPU_SumTock=`/bin/echo -e "$CPU_LineTock" | /usr/bin/tr " " "+" | /usr/bin/bc`
    CPU_IdleTock=`/bin/echo -e "$CPU_LineTock" | /usr/bin/awk '{print $4}'`
    # CPULoad=$((100*($CPU_SumTock-$CPU_SumTick-$CPU_IdleTock+$CPU_IdleTick)/($CPU_SumTock-$CPU_SumTick)))
    CPULoad=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2; 100 * ( $CPU_SumTock - $CPU_SumTick - $CPU_IdleTock + $CPU_IdleTick ) / ( $CPU_SumTock - $CPU_SumTick ) / 1 " | /usr/bin/bc)`
    # CalcIO
    # IOIndex=$((100*$IO_DTock/($IO_TTock-$IO_TTick)-100*$IO_DTick/($IO_TTock-$IO_TTick)))
    IOIndex=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2; 0 + 100 * ( $IO_DTock - $IO_DTick ) / ( $IO_TTock - $IO_TTick ) / 1 " | /usr/bin/bc)`
    # CalcPerf
    PerfIndex=`/usr/bin/printf %.$2f $(/bin/echo -e "scale=2;  sqrt( ($IOIndex / 1.5) ^2 + $CPULoad ^2 ) " | /usr/bin/bc)`
    LoadIndex=`/bin/echo -e "scale=2; $IOIndex / 100 + 10 * $UserCount / $PERFScore + 100 * $ShortLoad / $PERFScore / $PHYSICORE " | /usr/bin/bc`

    TmC_3=$[$(/bin/date +%s%N)/1000000] #DBG_calcmain       #lagcalc basic

    {
    CPU_SumTick=`/bin/echo $CPU_LineTickEx | /usr/bin/tr " " "+" | /usr/bin/bc`
    CPU_IdleTick=`/bin/echo $CPU_LineTickEx | /usr/bin/awk '{print $4}'`
    /bin/echo -e "export CPU_SumTick=$CPU_SumTick" >> /tmp/NR_LastRep &
    /bin/echo -e "export CPU_IdleTick=$CPU_IdleTick" >> /tmp/NR_LastRep &
    }&

    /bin/echo -e "export IO_TTick=$IO_TTickEx" >> /tmp/NR_LastRep &
    /bin/echo -e "export IO_DTick=$IO_DTickEx" >> /tmp/NR_LastRep &
    /bin/echo -e "export UserCount=`/bin/echo "$infowho" | /bin/grep -v 'root\|unknown' | /usr/bin/awk '{print $1}' | /usr/bin/sort -u | /usr/bin/wc -l`" >> /tmp/NR_LastRep &
    /bin/echo -e "export ShortLoad=`/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'`" >> /tmp/NR_LastRep &
}

unirep()
{
    if [ -n "$LoadIndex" -a -n "$PerfIndex" ]
    then
        /bin/echo -e "$HOSTNAME\tlog=load\t$LoadIndex\t$PerfIndex\tLoad_C=$LoadIndex\tPerf_R=$PerfIndex\tCPU=$CPULoad IO=$IOIndex\tUSERC=$UserCount AR=$AR\t"`/bin/date +%s`
    fi
    MarkT=`/bin/date +%s`
    /bin/echo "$infomount" | /bin/grep ".img " |  /usr/bin/awk '{print $1"\t"$3}' | /usr/bin/sort -k 2 | /bin/sed "s/^/$HOSTNAME\tlog=imgon\t&/g" | /bin/sed "s/$/&\t$MarkT/g"
    /bin/echo "$infowho" | /bin/grep -v 'root\|unknown' | /usr/bin/awk -F "[()]" '{print $1"\t"$2}' | /usr/bin/awk '{print $3"_"$4"\t"$1"\t\t"$5}' | /bin/sed "s/head-sh-01.*/head-sh-01/g" | /usr/bin/sort -k 2 | /usr/bin/uniq -f 1 | /bin/sed "s/^/$HOSTNAME\tlog=ulsc\t&/g" | /bin/sed "s/$/&\t$MarkT/g"
}

# Secure Realtime Text Copy v3, check text integrity, then push real time text to NFS at this last step, with endline and lag check
secrtsend()
{
    TmS_2a=$[$(/bin/date +%s%N)/1000000] #DBG_secrtsend       #lagcalc basic
    /bin/echo -e "export TmS_2a=$TmS_2a" >> /tmp/NR_LastRep & #DBG_secrtsend       #lagcalc basic
    for REPLX in `/bin/ls /tmp/rt.* 2>/dev/null`
    do
        CheckLineL1=`/usr/bin/tail -n 1 $REPLX`
        CheckLineL2=`/usr/bin/tail -n 2 $REPLX | /usr/bin/head -n 1`
        RepLag=$((`/bin/date +%s`-${CheckLineL2:(-10)}))
        # /bin/echo -e "export TmS_2b=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_secrtsend
        # /bin/echo -e "# DBG RepLag=$RepLag   loglatency=$loglatency" >> /tmp/NR_LastRep & #DBG_secrtsend
        if [ "$CheckLineL1"  == "$endline $HOSTNAME" -a "$CheckLineL2"  != "$endline $HOSTNAME" -a "$RepLag" -lt "$loglatency" ]
        then
            REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/tmp/" '{print $2}'`
            # /bin/echo -e "export TmS_2c=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_secrtsend
            /bin/cp $REPLX `/bin/echo -e "$opstmp/sec$REPLXNAME"`
            # /bin/echo -e "export TmS_2d=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_secrtsend
            /bin/chmod 666 `/bin/echo -e "$opstmp/sec$REPLXNAME"`
            # /bin/echo -e "export TmS_2e=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_secrtsend
        else
            # /bin/mv $REPLX.fail  #DBG
            /bin/rm -f $REPLX
        fi
    done
    TmS_2z=$[$(/bin/date +%s%N)/1000000] #DBG_secrtsend       #lagcalc basic
    /bin/echo -e "export TmS_2z=$TmS_2z\nexport TmR_1=$TmS_2z" >> /tmp/NR_LastRep & #DBG_secrtsend #DBG_reallenth       #lagcalc basic
}

# General Operation Executor v3, run command in tickets with checkline as root, and with lag check
geoexec()
{
    # /bin/ls $opstmp/secrt.ticket.geoexec.* 2>/dev/null
    /bin/ls $HTKT 2>/dev/null
    if [ -f "$HTKT" ]
    then
        exectime=`/bin/date +%Y-%m%d-%H%M-%S`
        TicketTail=`/usr/bin/tail -n 1 $HTKT`
        TicketTail2=`/usr/bin/tail -n 2 $HTKT | /usr/bin/head -n 1`
        TicketLag=$((`/bin/date +%s`-${TicketTail2:(-10)}))
        if [ "$endline $HOSTNAME" == "$TicketTail" -a "$endline $HOSTNAME" != "$TicketTail2" -a "$TicketLag" -lt 30 ]
        then
            # echo -e "#DBG\n TicketTail=$TicketTail\n TicketTail2=$TicketTail2" >> $HTKT
            /bin/mv $HTKT /var/log/ticket.$exectime.sh
            /bin/chmod a+x /var/log/ticket.$exectime.sh
            /var/log/ticket.$exectime.sh
            /bin/mv /var/log/ticket.$exectime.sh /var/log/done.$exectime.sh
            # cp /var/log/done.$exectime.sh $opstmp/../dbgtmp #DBG
        else
            /bin/mv $HTKT /var/log/dropped.$exectime.sh
        fi
    fi
    # /bin/echo -e "export TmX_1=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_geoexec
}

# Latency debug module
lagcalc()
{

    # TmE_0=`/bin/echo $[$(/bin/date +%s%N)/1000000]` #DBG_lagcalc
    # TmE_1=`/bin/echo $[$(/bin/date +%s%N)/1000000]` #DBG_lagcalc
    # TmE_2=`/bin/echo $[$(/bin/date +%s%N)/1000000]` #DBG_lagcalc
    # TmE_3=`/bin/echo $[$(/bin/date +%s%N)/1000000]` #DBG_lagcalc
    # /bin/echo -e "export TL_X=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_lagcalc
    # /bin/echo -e "# DBG TmS_0=$TmS_0\t TmG_1=$TmG_1\t TmM_2=$TmM_2" >> /tmp/NR_LastRep & #DBG_lagcalc
    M1=$(($TmC_0 - $TmM_0)) #DBG_marktime
    M2=$(($TmM_0 - $TmM_2)) #DBG_marktime
    MR=$(($M1 + $M2)) #DBG_marktime
    # /bin/echo -e "# DBG MR=$MR\t M1=$M1\t M2=$M2" >> /tmp/NR_LastRep & #DBG_marktime
    # G1=$(($TmG_1 - $TmG_0)) #DBG_genrep
    # G2=$(($TmG_2 - $TmG_1)) #DBG_genrep
    # G3=$(($TmS_0 - $TmG_2)) #DBG_genrep
    GR=$(($TmS_0 - $TmG_0)) #DBG_genrep
    # /bin/echo -e "# DBG GR=$GR\t G1=$G1\t G2=$G2\t G3=$G3" >> /tmp/NR_LastRep & #DBG_genrep
    # C1=$(($TmC_1 - $TmC_0)) #DBG_calcmain
    # C2=$(($TmC_2 - $TmC_1)) #DBG_calcmain
    # C3=$(($TmC_3 - $TmC_2)) #DBG_calcmain
    CR=$(($TmC_3 - $TmC_0)) #DBG_calcmain
    # /bin/echo -e "# DBG CR=$CR\t C1=$C1\t C2=$C2\t C3=$C3\t C4=$C4" >> /tmp/NR_LastRep & #DBG_lagcalc
    # S1=$(($TmS_1 - $TmS_0)) #DBG_secrtsend
    # S2a=$(($TmS_2b - $TmS_2a)) #DBG_secrtsend
    # S2b=$(($TmS_2c - $TmS_2b)) #DBG_secrtsend
    # S2c=$(($TmS_2d - $TmS_2c)) #DBG_secrtsend
    # S2d=$(($TmS_2e - $TmS_2d)) #DBG_secrtsend
    S2=$((${TmS_2z:-$TmS_2a} - $TmS_2a)) #DBG_secrtsend
    if [ "$S2" == 0 ]; then S2="999+" ;fi #DBG_secrtsend
    SR=$(($TmL_0 - $TmS_0)) #DBG_secrtsend
    # /bin/echo -e "# DBG TmS_1=$TmS_1 \tTmS_2z=$TmS_2z" >> /tmp/NR_LastRep & #DBG_lagcalc
    # /bin/echo -e "# DBG SR=$SR\t S1=$S1\t S2=$S2" >> /tmp/NR_LastRep & #DBG_secrtsend
    # XR=$(($TmX_1 - $TmM_0)) #DBG_geoexec
    # /bin/echo -e "# DBG TmC_0=$TmC_0\n# DBG TmX_1=$TmX_1" >> /tmp/NR_LastRep & #DBG_lagcalc
    # ER=$((($TmE_3 - $TmE_0 ) / 3)) #DBG_lagcalc
    # /bin/echo -e "# DBG XR=$XR\tER=$ER\tAR=$AR" >> /tmp/NR_LastRep & #DBG_lagcalc
    TmL_1=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
    LR=$(($TmL_1 - $TmL_0))
    /bin/echo -e "$HOSTNAME\t MR=$MR\t= $M1+$M2\t CR=$CR\t GR=$GR\t SR=$SR\t S2=$S2\t LR=$LR\tRR=$RR\tAR=$AR\tCPU=$CPULoad IO=$IOIndex\t"`/bin/date +%s` >> /tmp/NR_DBG_lag.log
    # /bin/echo -e "export LR=$LR" >> /tmp/NR_LastRep & #DBG_lagcalc
    # /bin/echo -e "# DBG TmL_1=$TmL_1\n# DBG TmL_0=$TmL_0" >> /tmp/NR_LastRep & #DBG_lagcalc
    /bin/echo -e "export TmR_1=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_reallenth       #lagcalc basic
}


# Main payload sequence
payload()
{
    cpuiotick #M1
    calcmain #CR
                TmG_0=$[$(/bin/date +%s%N)/1000000] #DBG_genrep       #lagcalc basic
    unirep > $localsitrep #GR
                TmS_0=$[$(/bin/date +%s%N)/1000000] #DBG_secrtsend       #lagcalc basic
    /bin/echo -e "$endline" $HOSTNAME >> $localsitrep #S1
    /bin/mv $localsitrep /tmp/rt.sitrep.unirep.$HOSTNAME #S1
                # TmS_1=$[$(/bin/date +%s%N)/1000000] #DBG_secrtsend
    secrtsend & #S2
                TmL_0=$[$(/bin/date +%s%N)/1000000] #DBG_lagcalc       #lagcalc basic
    lagcalc & #LR for latency debug       #lagcalc basic
}

# Main function loop
step=1 #Execution time interval, MUST UNDER 3600!!!
darwinawards &
# /bin/echo -n > /tmp/NR_DBG_lag.log &  #DBG_lagcalc
for (( i = 0; i < 3600; i=(i+step) ))
do
        TmM_0=$[$(/bin/date +%s%N)/1000000] # !!! Used by $AR calc !!!
    payload &
    geoexec & #XR
    sleep $step
        /bin/echo -e "export TmM_2=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_marktime       #lagcalc basic
    cpuiotock #M1
done
exit 0
