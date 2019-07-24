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
	/bin/echo "$lccrep_stack" > /tmp/lccrep_stack &
	node_names=`/bin/echo "$lccrep_stack" | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
	node_count=`/bin/echo "$node_names" | /usr/bin/wc -l`
	/bin/echo -e "var head_name = \"$head_name\";\nvar node_count = $node_count;" > /tmp/CR_lccinfo
	x=1
	for node_name in `/bin/echo "$node_names"`
	do
		/bin/echo -e "var node_name_$x = \"$node_name\";" >> /tmp/CR_lccinfo
		x=$(($x+1))
	done
	/bin/cp /tmp/lccrep_stack $opstmp/lccrep_stack &
	/bin/cp /tmp/CR_lccinfo $opstmp/lccinfo &
}

# Main function loop
step=0.1
while true
do
	payload_lccinfo &
	/bin/sleep $step
done
exit 0
