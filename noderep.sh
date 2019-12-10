#! /bin/bash

# Node Sitrep generator HP revision block 2, execute sequence structure renewed and dedicated performance debug module added.

# noderep.sh single instance lock
pidpath=/tmp/NR_PID
selfname=`/bin/echo $0 | /usr/bin/awk -F "/" '{print $NF}'`
if [ -f "$pidpath" ]
then
	for ktgt in `/bin/ps -aux | /bin/grep -vE "$$|grep" | /bin/grep $selfname | /usr/bin/awk '{print $2}'`
	do
	{
		kill -9 $ktgt 2>/dev/null
	}&
	done
	# kill -9 `/bin/cat $pidpath` > /dev/null 2>&1
	/bin/rm -f $pidpath
fi
echo $$ >$pidpath

/usr/bin/renice -n -18 -p $$

COLUMNS=512
endline="###---###---###---###---###"
opstmp=/LCC/opstmp
lococlu=/LCC/bin
source /LCC/bin/lcc.conf

# /bin/echo -e "#DBG_lcc.conf \nCOLUMNS=$COLUMNS\nendline=$endline\nopstmp=$opstmp\nlococlu=$lococlu\ndskinitsz=$dskinitsz\n#\n" > /root/DBG_lcc.conf
# /bin/cat /LCC/bin/lcc.conf >> /root/DBG_lcc.conf #DBG

HOSTNAME=`/bin/hostname`

# For Ubuntu 16.04=+, filter local snap loop devices
SNAP=`/bin/lsblk | /bin/grep "loop.* /snap/" | /usr/bin/awk '{printf $1 "|"}' | /bin/sed 's/[|]$//g'`
if [ ! -n "$SNAP" ]
then
	SNAP="No Snap Loop Device!"
fi

# Output target for unirep
localsitrep=/tmp/draft.rt.sitrep

# Auto umount offline user images
# $lococlu/tools/nodewring.sh 2>/dev/null &

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

free_opt=`/usr/bin/free`
ram_all=`/bin/echo "$free_opt" | /bin/grep "Mem:" | /usr/bin/awk '{print $2}'`
ram_used=`/bin/echo "$free_opt" | /bin/grep "buffers/cache:" | /usr/bin/awk '{print $3}'`
if [ ! -n "$ram_used" ]
then
	ram_used=`/bin/echo "$free_opt" | /bin/grep "Mem:" | /usr/bin/awk '{print ($2-$7)}'`
fi
swap_all=`/bin/echo "$free_opt" | /bin/grep "Swap:" | /usr/bin/awk '{print $2}'`
swap_used=`/bin/echo "$free_opt" | /bin/grep "Swap:" | /usr/bin/awk '{print $3}'`
ram_pct=`/bin/echo -e "scale=2; 100 * $ram_used / $ram_all " | /usr/bin/bc`
swap_pct=`/bin/echo -e "scale=2; 100 * $swap_used / $swap_all " | /usr/bin/bc`


# Darwin awards for imbeciles not connecting via cluster head
darwinawards()
{
for PTSK in `/usr/bin/who | /bin/grep -Ev "head|root|sactual|:0 |10.231.215.243|tmux|:pts/" | /usr/bin/awk '{print $2}'`
do
	/usr/bin/pkill -KILL -t $PTSK
done
}

userlimit()
{
OLD_IFS="$IFS"
IFS=$'\n'
tgtnice=6
for i in `/bin/ps -axeo uid,user,pid,ni | /usr/bin/sort -n`
do
	i_uid=`echo $i | awk '{print $1}'`
	i_pid=`echo $i | awk '{print $3}'`
	i_ni=`echo $i | awk '{print $4}'`
	if [[ "$i_uid" -gt 65534 && "$i_ni" -ne "$tgtnice" ]]
	then
		/usr/bin/renice -n $tgtnice $i_pid
	fi
done
IFS="$OLD_IFS"
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

loopmount()
{
	/bin/mount | /bin/grep "\.img " | /usr/bin/awk '{print $1"\t"$3}' | /usr/bin/sort -k 2 | /bin/sed "s/^/$HOSTNAME\tlog=imgon\t&/g"
	/bin/echo -e "$endline" $HOSTNAME
}

calcmain()
{
	TmC_0=$[$(/bin/date +%s%N)/1000000] #DBG_calcmain	   #lagcalc basic
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
	# CKUserCount=`/bin/grep " UserCount=" /tmp/NR_LastRep | /usr/bin/awk -F "=" '{print $2}'`
	TmC_1=$[$(/bin/date +%s%N)/1000000] #DBG_calcmain
	#
	# TimeTable=`/bin/cat /tmp/NR_LastRep | /bin/grep "export Tm" | /usr/bin/sort -r`
	#
	/bin/echo -e "export TmM_S=$TmM_0" > /tmp/NR_LastRep #!!! The start of NR_LastRep loop !!!
	# /bin/echo -e "# DBG Got CKUserCount=$CKUserCount" >> /tmp/NR_LastRep & #DBG_allrange

	TmC_2=$[$(/bin/date +%s%N)/1000000] #DBG_calcmain

	AR=$(($TmM_0 - $TmM_S - 1000)) #DBG_allrange
	# /bin/echo -e "export AR=$AR" >> /tmp/NR_LastRep & #DBG_allrange

	RR=$(($TmR_1 - $TmM_S))  #DBG_reallenth	   #lagcalc basic
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
	# LoadIndex=`/bin/echo -e "scale=2; $IOIndex / 100 + 10 * $UserCount / $PERFScore + 100 * $ShortLoad / $PERFScore / $PHYSICORE " | /usr/bin/bc`
	LoadIndex=`/bin/echo -e "scale=2; $IOIndex / 10 + 100 * $UserCount / $PERFScore + 100 * $ShortLoad / $PERFScore " | /usr/bin/bc`
	uptm=`/bin/cat /proc/uptime | /usr/bin/awk -F "." '{print $1}'`

	# free_verchk=`/bin/echo "$free_opt" | /bin/grep " available"`
	# if [ ! -n "$free_verchk" ]
	# then
	# 	ram_used=`/bin/echo "$free_opt" | /bin/grep "buffers/cache:" | /usr/bin/awk '{print $3}'`
	# else
	# 	ram_used=`/bin/echo "$free_opt" | /bin/grep "Mem:" | /usr/bin/awk '{print ($2-$7)}'`
	# fi

	TmC_3=$[$(/bin/date +%s%N)/1000000] #DBG_calcmain	   #lagcalc basic

	{
	CPU_SumTick=`/bin/echo $CPU_LineTickEx | /usr/bin/tr " " "+" | /usr/bin/bc`
	CPU_IdleTick=`/bin/echo $CPU_LineTickEx | /usr/bin/awk '{print $4}'`
	/bin/echo -e "export CPU_SumTick=$CPU_SumTick" >> /tmp/NR_LastRep &
	/bin/echo -e "export CPU_IdleTick=$CPU_IdleTick" >> /tmp/NR_LastRep &
	}&

	/bin/echo -e "export IO_TTick=$IO_TTickEx" >> /tmp/NR_LastRep &
	/bin/echo -e "export IO_DTick=$IO_DTickEx" >> /tmp/NR_LastRep &
	/bin/echo -e "export UserCount=`/usr/bin/who | /bin/grep -vE "root|unknown" | /usr/bin/awk '{print $1}' | /usr/bin/sort -u | /usr/bin/wc -l`" >> /tmp/NR_LastRep &
	/bin/echo -e "export ShortLoad=`/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'`" >> /tmp/NR_LastRep &
}

unirep()
{
	MarkT=`/bin/date +%s`
	# declare -A loop_mount
	# declare -A loop_image
	# loop_mount_raw=`/bin/echo -n "loop_mount=(";/bin/grep /dev/loop /proc/mounts | /usr/bin/awk '{printf "["$1"]=\""$2"\" "}';/bin/echo ")"`
	# eval $(/bin/echo $loop_mount_raw)
	# loop_image_raw=`/bin/echo -n "loop_image=(";/bin/cat /tmp/NR_loop | /usr/bin/awk '{printf "["$1"]=\""$2"\" "}';/bin/echo ")"`
	# eval $(/bin/echo $loop_image_raw)
	# for key in $(echo ${!loop_mount[*]}); do echo -e "${loop_image[$key]}\t${loop_mount[$key]}"; done | /usr/bin/sort -k 2 | /bin/sed "s/^/$HOSTNAME\tlog=imgon\t&/g" | /bin/sed "s/$/&\t$MarkT/g"
	# /bin/mount | /bin/grep "\.img " | /usr/bin/awk '{print $1"\t"$3}' | /usr/bin/sort -k 2 | /bin/sed "s/^/$HOSTNAME\tlog=imgon\t&/g" | /bin/sed "s/$/&\t$MarkT/g"
	if [ ! -f "/tmp/NR_LastMount" -o -n "$(/bin/grep $endline /tmp/.NR_LastMount)" -a -n "$(/usr/bin/diff /tmp/.NR_LastMount /tmp/NR_LastMount)" ]
	then
		/bin/cp /tmp/.NR_LastMount /tmp/NR_LastMount
	fi 
	/bin/grep -v $endline /tmp/NR_LastMount | /bin/sed "s/$/&\t$MarkT/g"
	/usr/bin/who | /bin/grep -v -vE "root|unknown" | /usr/bin/awk -F "[()]" '{print $1"\t"$2}' | /usr/bin/awk '{print $3"_"$4"\t"$1"\t\t"$5}' | /usr/bin/awk -F ".ap.|:S" '{print $1}' | /usr/bin/sort -k 2 -u | /bin/sed "s/^/$HOSTNAME\tlog=ulsc\t&/g" | /bin/sed "s/$/&\t$MarkT/g"

	if [ -n "$LoadIndex" -a -n "$PerfIndex" ]
	then
		/bin/echo -e "$HOSTNAME\tlog=load\t$LoadIndex\t$PerfIndex\t$CPULoad\t$IOIndex\t$ram_pct\t$swap_pct\t$UserCount\t$AR\t$uptm\t$MarkT"
	fi

	/bin/echo -e "$endline" $HOSTNAME
	loopmount > /tmp/.NR_LastMount &
}

# Secure Realtime Text Copy v3, check text integrity, then push real time text to NFS at this last step, with endline and lag check
secrtsend_sitrep()
{
	TmS_2a=$[$(/bin/date +%s%N)/1000000] #DBG_secrtsend_sitrep	   #lagcalc basic
	/bin/echo -e "export TmS_2a=$TmS_2a" >> /tmp/NR_LastRep & #DBG_secrtsend_sitrep	   #lagcalc basic
	if [ -f "/tmp/rt.sitrep.$HOSTNAME" ]
	then
		REPLX=/tmp/rt.sitrep.$HOSTNAME
		CheckLineL1=`/usr/bin/tail -n 1 $REPLX`
		CheckLineL2=`/usr/bin/tail -n 2 $REPLX | /usr/bin/head -n 1`
		RepLag=$((`/bin/date +%s`-${CheckLineL2:(-10)})) 2>/dev/null
		# /bin/echo -e "export TmS_2b=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_secrtsend_sitrep
		# /bin/echo -e "# DBG RepLag=$RepLag   loglatency=$loglatency" >> /tmp/NR_LastRep & #DBG_secrtsend_sitrep
		if [ "$CheckLineL1"  == "$endline $HOSTNAME" -a "$CheckLineL2"  != "$endline $HOSTNAME" -a -n "$(/bin/grep log=load $REPLX)" -a "$RepLag" -lt "$loglatency" ]
		then
			FREPNAME=`/bin/echo $REPLX | /bin/sed 's/^\/tmp\//sec/g'`
			# /bin/echo -e "export TmS_2c=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_secrtsend_sitrep
			/bin/mv $REPLX $opstmp/.$FREPNAME
			/bin/mv $opstmp/.$FREPNAME $opstmp/$FREPNAME
			# /bin/echo -e "export TmS_2d=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_secrtsend_sitrep
			# /bin/chmod 666 $opstmp/$FREPNAME
			# /bin/echo -e "export TmS_2e=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_secrtsend_sitrep
		else
			# /bin/mv $REPLX.fail  #DBG
			/bin/rm -f $REPLX
		fi
	fi


	TmS_2z=$[$(/bin/date +%s%N)/1000000] #DBG_secrtsend_sitrep	   #lagcalc basic
	/bin/echo -e "export TmS_2z=$TmS_2z\nexport TmR_1=$TmS_2z" >> /tmp/NR_LastRep & #DBG_secrtsend_sitrep #DBG_reallenth	   #lagcalc basic
}

# General Operation Executor v3, run command in tickets with checkline as root, and with lag check
geoexec()
{
	# Checkpath for geoexec
	HTKT=`/bin/ls $opstmp/secrt.geoexec.*.$HOSTNAME 2>/dev/null`
	# echo "$HTKT" > /tmp/DBG_geoexec.log #DBG_geoexec
	if [ -n "$HTKT" ]
	then
		for TgtTicket in `/bin/echo "$HTKT"`
		do
			# echo "$TgtTicket" >> /tmp/DBG_geoexec.log #DBG_geoexec
			LTN=`/bin/echo $TgtTicket | /bin/sed 's/^.*.geoexec/lcctkt/g'`
			# echo "$LTN" >> /tmp/DBG_geoexec.log #DBG_geoexec
			extm=`/bin/date +%y%m%d-%H%M%S`
			TktTail=`/usr/bin/tail -n 1 $TgtTicket`
			TktTail2=`/usr/bin/tail -n 2 $TgtTicket | /usr/bin/head -n 1`
			if [ "$endline $HOSTNAME" == "$TktTail" -a "$endline $HOSTNAME" != "$TktTail2" ]
			then
				# echo -e "#DBG\n TktTail=$TktTail\n TktTail2=$TktTail2" >> $HTKT #DBG_geoexec
				/bin/mv $TgtTicket /var/log/$LTN.$extm.sh
				/bin/chmod a+x /var/log/$LTN.$extm.sh
				/var/log/$LTN.$extm.sh
				/bin/mv /var/log/$LTN.$extm.sh /var/log/done.$LTN.$extm.sh
				# cp /var/log/done.$extm.sh $opstmp/../dbgtmp #DBG_geoexec
			else
				/bin/mv $TgtTicket /var/log/dropped.$LTN.$extm.sh
			fi
		done
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
	C1=$(($TmC_1 - $TmC_0)) #DBG_calcmain
	C2=$(($TmC_2 - $TmC_1)) #DBG_calcmain
	C3=$(($TmC_3 - $TmC_2)) #DBG_calcmain
	CR=$(($TmC_3 - $TmC_0)) #DBG_calcmain
	# /bin/echo -e "# DBG CR=$CR\t C1=$C1\t C2=$C2\t C3=$C3\t C4=$C4" >> /tmp/NR_LastRep & #DBG_lagcalc
	# S1=$(($TmS_1 - $TmS_0)) #DBG_secrtsend_sitrep
	# S2a=$(($TmS_2b - $TmS_2a)) #DBG_secrtsend_sitrep
	# S2b=$(($TmS_2c - $TmS_2b)) #DBG_secrtsend_sitrep
	# S2c=$(($TmS_2d - $TmS_2c)) #DBG_secrtsend_sitrep
	# S2d=$(($TmS_2e - $TmS_2d)) #DBG_secrtsend_sitrep
	S2=$((${TmS_2z:-$TmS_2a} - $TmS_2a)) #DBG_secrtsend_sitrep
	if [ "$S2" == 0 ]; then S2="999+" ;fi #DBG_secrtsend_sitrep
	SR=$(($TmL_0 - $TmS_0)) #DBG_secrtsend_sitrep
	# /bin/echo -e "# DBG TmS_1=$TmS_1 \tTmS_2z=$TmS_2z" >> /tmp/NR_LastRep & #DBG_lagcalc
	# /bin/echo -e "# DBG SR=$SR\t S1=$S1\t S2=$S2" >> /tmp/NR_LastRep & #DBG_secrtsend_sitrep
	# XR=$(($TmX_1 - $TmM_0)) #DBG_geoexec
	# /bin/echo -e "# DBG TmC_0=$TmC_0\n# DBG TmX_1=$TmX_1" >> /tmp/NR_LastRep & #DBG_lagcalc
	# ER=$((($TmE_3 - $TmE_0 ) / 3)) #DBG_lagcalc
	# /bin/echo -e "# DBG XR=$XR\tER=$ER\tAR=$AR" >> /tmp/NR_LastRep & #DBG_lagcalc
	TmL_1=`/bin/echo $[$(/bin/date +%s%N)/1000000]`
	LR=$(($TmL_1 - $TmL_0))
	/bin/echo -e "$HOSTNAME\t MR=$MR\t=$M1+$M2\t CR=$CR\t=$C1+$C2+$C3 GR=$GR\t SR=$SR\t S2=$S2\t LR=$LR\tRR=$RR\tAR=$AR\tCPU=$CPULoad IO=$IOIndex\t"`/bin/date +%s` >> /tmp/NR_DBG_lag.log
	# /bin/echo -e "export LR=$LR" >> /tmp/NR_LastRep & #DBG_lagcalc
	# /bin/echo -e "# DBG TmL_1=$TmL_1\n# DBG TmL_0=$TmL_0" >> /tmp/NR_LastRep & #DBG_lagcalc
	/bin/echo -e "export TmR_1=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_reallenth	   #lagcalc basic
}


# Main payload sequence
payload()
{
	cpuiotick #M1
	calcmain #CR
				TmG_0=$[$(/bin/date +%s%N)/1000000] #DBG_genrep	   #lagcalc basic
	unirep > $localsitrep #GR
	# unirep | tee $localsitrep | grep =load | wc -l >> $opstmp/DBG_unirep.$HOSTNAME #DBG_unirep
				TmS_0=$[$(/bin/date +%s%N)/1000000] #DBG_secrtsend_sitrep	   #lagcalc basic
	/bin/mv $localsitrep /tmp/rt.sitrep.$HOSTNAME #S1
				# TmS_1=$[$(/bin/date +%s%N)/1000000] #DBG_secrtsend_sitrep
	secrtsend_sitrep & #S2
				TmL_0=$[$(/bin/date +%s%N)/1000000] #DBG_lagcalc	   #lagcalc basic
	lagcalc & #LR for latency debug	   #lagcalc basic
}

# Main function loop
step=1 #Execution time interval, MUST UNDER 3600!!!
darwinawards &
# $lococlu/tools/fixgit.sh > /var/log/fixgit.log &
/bin/echo -n > /tmp/NR_DBG_lag.log &  #DBG_lagcalc
userlimit &
# /bin/echo -n > $opstmp/DBG_unirep.$HOSTNAME #DBG_unirep
for (( i = 0; i < 3600; i=(i+step) ))
do
		TmM_0=$[$(/bin/date +%s%N)/1000000] # !!! Used by $AR calc !!!
	payload &
	geoexec & #XR
	/bin/sleep $step
		/bin/echo -e "export TmM_2=$[$(/bin/date +%s%N)/1000000]" >> /tmp/NR_LastRep & #DBG_marktime	   #lagcalc basic
	cpuiotock #M1
done
exit 0
