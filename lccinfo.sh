#! /bin/bash
# Head cluster info generator HP revision block 2, execute sequence structure renewed and dedicated performance debug module added.

# lccrep_info.sh single instance lock

pidpath=/tmp/CR_PID
if [ -f "$pidpath" ]
then
	for ktgt in `/bin/ps -aux | /bin/grep -vE "$$|grep" | /bin/grep lccinfo.sh | /usr/bin/awk '{print $2}'`
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
loglatency=3
opstmp=/LCC/opstmp
lococlu=/LCC/bin
source /LCC/bin/lcc.conf

HOSTNAME=`/bin/hostname`

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


sitrep_2tmp()
{
	# for i in $opstmp/secrt.sitrep.*
	# do
	# 	checkline=`tail -n 1 $i | grep -e "###---###---###---###---###"`
	# 	if [ -n "$checkline" ]
	# 	then
	# 		cp $i /tmp
	# 	fi
	# done
	sitreptmsp=`/bin/ls --full-time /LCC/opstmp/secrt.sitrep.*`
	# eval /tmp/CR_sitrep_ctime
	# echo "export sitreptmspl=$sitreptmsp" > /tmp/CR_sitrep_ctime &
	for i in `/usr/bin/diff <(/bin/echo "$sitreptmsp") /tmp/CR_sitrep_ctime -n | /bin/grep  "/LCC/" | awk '{print $NF}'`
	do
		checkline=`/usr/bin/tail -n 1 $i | /bin/grep -e "###---###---###---###---###"`
		if [ -n "$checkline" ]
		then
			/bin/cp $i /tmp
		fi
	done
	/bin/echo "$sitreptmsp" > /tmp/CR_sitrep_ctime
}

lag_checker()
{
	/bin/echo "$lccrep_lag" | while read lag_line
	do
		lag=`/bin/echo "$lag_line" | /usr/bin/awk '{print $NF}'`	
		# /bin/echo -e "$lag_line\n$lag" > /tmp/lccrep_lag # DBG_lag
		if [[ "$lag" -gt 5 ]]
		then
			lag_node=`/bin/echo "$lag_line" | /usr/bin/awk '{print $1}'`
			/bin/rm -f /tmp/secrt.sitrep.$lag_node
		fi
	done
}

# Payload fast ring, format sitrep into JS array, updates load and gen info in asynchronous way
payload_fast()
{
	lccrep_stack=`/bin/cat /tmp/secrt.sitrep.* | /bin/grep -v "###" | /usr/bin/sort -k 2,2`
	lccrep_lag=`/bin/echo "$lccrep_stack" | /bin/grep "log=load" | /usr/bin/awk '{now=systime();printf $0 "\t" now-$(NF)"\n"}'`
	sitrep_gen=`/bin/echo "$lccrep_stack"| /bin/grep -v "log=load" | /usr/bin/awk '{$NF="";print}'`
	lccrep_load=`/bin/echo -e "var lcc_load = [\n\t['node_name', 'Load_C', 'Perf_R', 'CPU', 'IO', 'RAM', 'SWAP', 'USER', 'AR', 'uptm', 'tmsp', 'lag'],";\
				/bin/echo "$lccrep_lag" | /bin/sed "s/^/'/; s/\t/ /g;  s/[ \t]/'\t/" \
				| /bin/sed 's/$/],/g; s/[ ][ ]*/\t/g; s/\t/, /g; s/log=load, //g' \
				| /bin/sed 's/^/\t[/g; $s/,$//g' ; /bin/echo "];"`
	/bin/echo -e "$lccrep_load\n//\n" > /tmp/lccrep_load
	/bin/cp /tmp/lccrep_load $opstmp &
	gen_sitrep_diff=`/usr/bin/diff <(/bin/echo "$sitrep_gen") /tmp/CR_sitrep_gen -n`
	if [ -n "$gen_sitrep_diff" ]
	then
		lccrep_imgon=`/bin/echo -e "var lcc_imgon = [\n\t['node_name', 'img_path', 'mnt_path', 'tmsp'],";\
		/bin/echo "$lccrep_stack" | /bin/grep  "log=imgon" | /usr/bin/awk '{print "'\''"$1"'\''\t'\''" $3"'\''\t'\''"$4"'\''\t"$5}'  | /bin/sed "s/\t/ /g" \
		| /bin/sed "s/$/],/g; s/[ ][ ]*/\t/g; s/\t/, /g" | /bin/sed 's/^/\t[/g; $s/,$//g' ; /bin/echo "];"`
		lccrep_ulsc=`/bin/echo -e "var lcc_ulsc = [\n\t['node_name', 'user', 'log_from', 'log_time', 'tmsp'],";\
		/bin/echo "$lccrep_stack" | /bin/grep  "log=ulsc" | /usr/bin/awk '{print "'\''"$1"'\''\t'\''" $4"'\''\t'\''" $5"'\''\t'\''"$3"'\''\t"$6}'  | /bin/sed "s/\t/ /g"  \
		| /bin/sed "s/$/],/g; s/[ ][ ]*/\t/g; s/\t/, /g" | /bin/sed 's/^/\t[/g; $s/,$//g' ; /bin/echo "];"`
		/bin/echo -e "$lccrep_imgon\n$lccrep_ulsc\n//\n" > /tmp/lccrep_gen
		/bin/cp /tmp/lccrep_gen $opstmp &
	fi
	/bin/echo "$sitrep_gen" > /tmp/CR_sitrep_gen &
	lag_checker &



}

#Payload slow ring, 1/10 speed of fast ring, update head ram/swap/uptime and node names.
payload_slow()
{
	uptm=`/bin/cat /proc/uptime | /usr/bin/awk -F "." '{print $1}'`
	free_opt=`/usr/bin/free`
	ram_all=`/bin/echo "$free_opt" | /bin/grep "Mem:" | /usr/bin/awk '{print $2}'`
	free_verchk=`/bin/echo "$free_opt" | /bin/grep " available"`
	if [ ! -n "$free_verchk" ]
	then
		ram_used=`/bin/echo "$free_opt" | /bin/grep "cache:" | /usr/bin/awk '{print $3}'`
	else
		ram_used=`/bin/echo "$free_opt" | /bin/grep "Mem:" | /usr/bin/awk '{print ($2-$7)}'`
	fi
	swap_all=`/bin/echo "$free_opt" | /bin/grep "Swap:" | /usr/bin/awk '{print $2}'`
	swap_used=`/bin/echo "$free_opt" | /bin/grep "Swap:" | /usr/bin/awk '{print $3}'`
	ram_pct=`/bin/echo -e "scale=2; 100 * $ram_used / $ram_all " | /usr/bin/bc`
	swap_pct=`/bin/echo -e "scale=2; 100 * $swap_used / $swap_all " | /usr/bin/bc`

	# node_names=`/bin/echo "$lccrep_stack" | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
	
	node_names=`/bin/grep "log=load" /tmp/secrt.sitrep.* | /usr/bin/awk -F ":|\t" '{print $2}'`
	node_count=`/bin/echo "$node_names" | /usr/bin/wc -l`
	/bin/echo -e "var head_name = \"$HOSTNAME\";\nvar head_uptm = $uptm;\nvar head_rpct = $ram_pct;\nvar head_spct = $swap_pct;\nvar node_count = $node_count;" > /tmp/lccrep_info
	x=1
	for node_name in `/bin/echo "$node_names"`
	do
		/bin/echo -e "var node_name_$x = \"$node_name\";" >> /tmp/lccrep_info
		x=$(($x+1))
	done
	/bin/echo -e "//\n" >> /tmp/lccrep_info
	/bin/cp /tmp/lccrep_info $opstmp &
}

# Payload static ring, only run once per instance, check and kill unexpectedly disconnected user sessions.
payload_static()
{
	lccsl=`/bin/ps -aux | /bin/grep lccmain.sh | /usr/bin/awk '{print $3 "\t" $10 "\t" $1 "\t" $2}' | /bin/grep -Ev "^0" | /usr/bin/sort -n`
	# /bin/echo "$lccsl"
	OLDIFS="$IFS"
	IFS=$'\n'
	for lccs in `/bin/echo "$lccsl"`
	do
		# /bin/echo "$lccs\n"
		lccs_cpu=`/bin/echo "$lccs" | /usr/bin/awk -F "." '{print $1}'`
		# /bin/echo "$lccs_cpu"

		if [[ "$lccs_cpu" -ge 15 ]]
		then
			lccs_time=`/bin/echo "$lccs" | /usr/bin/awk -F "\t|:" '{print $2}'`
			# /bin/echo "$lccs_time"
			# /bin/echo "$lccs"
			if [[ "$lccs_time" -ge 10 ]]
			then
				lccs2k=`/bin/echo "$lccs" | /usr/bin/awk -F "\t|:" '{print $NF}'`
				lccs_user=`/bin/echo "$lccs" | /usr/bin/awk -F "\t|:" '{print $4}'`
				echo -e "\n`/bin/date +%Y-%m%d-%H%M-%S`\t User= $lccs_user\n$lccs\n">/var/log/lcc/kill_log.`/bin/date +%y%m%d-%H%M%S`.$lccs_user
				# /bin/echo $lccs2k
				/bin/kill -9 $lccs2k &
			fi
		fi
	done
	IFS="$OLDIFS"
}

# Main function loop
payload_static &
step=0.1
while true
do
	for (( g = 0; g < 10; g=$((g+1)) ))
	do
		sitrep_2tmp
		payload_fast &
		geoexec &
		/bin/sleep $step
	done
	payload_slow &
done
exit 0

