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
	lccrep_stack=`/bin/cat /LCC/opstmp/secrt.sitrep.* | /bin/grep -v "###" | /usr/bin/sort -k 2,2`
	# /bin/echo "$lccrep_stack" > /tmp/lccrep_stack
	lccrep_load=`/bin/echo -e "var lcc_load = [\n\t['node_name', 'Load_C', 'Perf_R', 'CPU', 'IO', 'USER', 'AR', 'tmsp'],";\
				/bin/echo "$lccrep_stack" | /bin/grep  "log=load" | /bin/sed "s/^/'/; s/\t/ /g;  s/[ \t]/'\t/" \
				| /bin/sed 's/$/],/g; s/[ ][ ]*/\t/g; s/\t/, /g; s/log=load, //g; s/Load_C=.*CPU=//g; s/IO=//g; s/IO=//g; s/IO=//g; s/USER=//g; s/AR=//g' | /bin/sed 's/^/\t[/g; $s/,$/\n];/g'`
	lccrep_imgon=`/bin/echo -e "var lcc_imgon = [\n\t['node_name', 'img_path', 'mnt_path', 'tmsp'],";\
				/bin/echo "$lccrep_stack" | /bin/grep  "log=imgon" | awk '{print "'\''"$1"'\''\t'\''" $3"'\''\t'\''"$4"'\''\t"$5}'  | /bin/sed "s/\t/ /g" \
				| /bin/sed "s/$/],/g; s/[ ][ ]*/\t/g; s/\t/, /g" | /bin/sed 's/^/\t[/g; $s/,$/\n];/g'`
	lccrep_ulsc=`/bin/echo -e "var lcc_ulsc = [\n\t['node_name', 'user', 'log_from', 'log_time', 'tmsp'],";\
				/bin/echo "$lccrep_stack" | /bin/grep  "log=ulsc" | awk '{print "'\''"$1"'\''\t'\''" $4"'\''\t'\''" $5"'\''\t'\''"$3"'\''\t"$6}'  | /bin/sed "s/\t/ /g"  \
				| /bin/sed "s/$/],/g; s/[ ][ ]*/\t/g; s/\t/, /g" | /bin/sed 's/^/\t[/g; $s/,$/\n];/g'`
	/bin/echo -e "$lccrep_load\n$lccrep_imgon\n$lccrep_ulsc\n" > /tmp/lccrep_ary

	node_names=`/bin/echo "$lccrep_stack" | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
	node_count=`/bin/echo "$node_names" | /usr/bin/wc -l`
	/bin/echo -e "var head_name = \"$head_name\";\nvar node_count = $node_count;" > /tmp/CR_lccinfo
	x=1
	for node_name in `/bin/echo "$node_names"`
	do
		/bin/echo -e "var node_name_$x = \"$node_name\";" >> /tmp/CR_lccinfo
		x=$(($x+1))
	done
	/bin/cp /tmp/lccrep_ary $opstmp/lccrep_ary &
	/bin/cp /tmp/CR_lccinfo $opstmp/lccinfo &
}

# Main function loop
step=0.1
while true
do
	payload_lccinfo
	/bin/sleep $step
done
exit 0
