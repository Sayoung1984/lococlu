#! /bin/bash
# Head cluster info generator HP revision block 2, execute sequence structure renewed and dedicated performance debug module added.

# lccinfo.sh single instance lock

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

head_name=`/bin/hostname`

payload_lccinfo()
{
	lccrep_stack=`/bin/cat $opstmp/secrt.sitrep.* | /bin/grep -v "###" | /usr/bin/sort -k 2,2`
	# /bin/echo "$lccrep_stack" > /tmp/lccrep_stack
	lccrep_lag=`/bin/echo "$lccrep_stack" | /bin/grep "log=load" | /usr/bin/awk '{now=systime();printf $0 "\t" now-$(NF)"\n"}'`
	lccrep_load=`/bin/echo -e "var lcc_load = [\n\t['node_name', 'Load_C', 'Perf_R', 'CPU', 'IO', 'USER', 'AR', 'tmsp', 'lag'],";\
				/bin/echo "$lccrep_lag" | /bin/sed "s/^/'/; s/\t/ /g;  s/[ \t]/'\t/" \
				| /bin/sed 's/$/],/g; s/[ ][ ]*/\t/g; s/\t/, /g; s/log=load, //g; s/Load_C=.*CPU=//g; s/IO=//g; s/IO=//g; s/IO=//g; s/USER=//g; s/AR=//g' \
				| /bin/sed 's/^/\t[/g; $s/,$//g' ; /bin/echo "];"`
	lccrep_imgon=`/bin/echo -e "var lcc_imgon = [\n\t['node_name', 'img_path', 'mnt_path', 'tmsp'],";\
				/bin/echo "$lccrep_stack" | /bin/grep  "log=imgon" | /usr/bin/awk '{print "'\''"$1"'\''\t'\''" $3"'\''\t'\''"$4"'\''\t"$5}'  | /bin/sed "s/\t/ /g" \
				| /bin/sed "s/$/],/g; s/[ ][ ]*/\t/g; s/\t/, /g" | /bin/sed 's/^/\t[/g; $s/,$//g' ; /bin/echo "];"`
	lccrep_ulsc=`/bin/echo -e "var lcc_ulsc = [\n\t['node_name', 'user', 'log_from', 'log_time', 'tmsp'],";\
				/bin/echo "$lccrep_stack" | /bin/grep  "log=ulsc" | /usr/bin/awk '{print "'\''"$1"'\''\t'\''" $4"'\''\t'\''" $5"'\''\t'\''"$3"'\''\t"$6}'  | /bin/sed "s/\t/ /g"  \
				| /bin/sed "s/$/],/g; s/[ ][ ]*/\t/g; s/\t/, /g" | /bin/sed 's/^/\t[/g; $s/,$//g' ; /bin/echo "];"`
	/bin/echo -e "$lccrep_load\n$lccrep_imgon\n$lccrep_ulsc\n" > /tmp/lccrep_ary

	node_names=`/bin/echo "$lccrep_stack" | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
	node_count=`/bin/echo "$node_names" | /usr/bin/wc -l`
	/bin/echo -e "var head_name = \"$head_name\";\nvar node_count = $node_count" > /tmp/CR_lccinfo
	x=1
	for node_name in `/bin/echo "$node_names"`
	do
		/bin/echo -e "var node_name_$x = \"$node_name\";" >> /tmp/CR_lccinfo
		x=$(($x+1))
	done
	/bin/cp /tmp/lccrep_ary $opstmp/lccrep_ary
	/bin/cp /tmp/CR_lccinfo $opstmp/lccinfo
	/bin/echo "$lccrep_lag" | while read lag_line
	do
		lag=`/bin/echo "$lag_line" | /usr/bin/awk '{print $NF}'`	
		# /bin/echo -e "$lag_line\n$lag" > /tmp/lccrep_lag # DBG_lag
		if [ "$lag" -gt "$loglatency" ]
		then
			lag_node=`/bin/echo "$lag_line" | /usr/bin/awk '{print $1}'`
			/bin/rm -f $opstmp/secrt.sitrep.$lag_node
		fi
	done
}

# Main function loop
step=0.33
while true
do
	payload_lccinfo
	/bin/sleep $step
done
exit 0
