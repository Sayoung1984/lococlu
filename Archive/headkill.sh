#! /bin/bash
lccsl=`/bin/ps -aux | /bin/grep lccmain.sh | /usr/bin/awk '{print $3 "\t" $10 "\t" $1 "\t" $2}' | /usr/bin/sort -n | /bin/grep -Ev "^0"`
# /bin/echo "$lccsl"
OLDIFS="$IFS"
IFS=$'\n'
for lccs in `/bin/echo "$lccsl"`
do
	# /bin/echo "$lccs\n"
	lccs_cpu=`/bin/echo "$lccs" | /usr/bin/awk -F "." '{print $1}'`
	# /bin/echo "$lccs_cpu"

	if [[ "$lccs_cpu" -ge 5 ]]
	then
		lccs_time=`/bin/echo "$lccs" | /usr/bin/awk -F "\t|:" '{print $2}'`
		# /bin/echo "$lccs_time"
		/bin/echo "$lccs"
		if [[ "$lccs_time" -ge 30 ]]
		then
			lccs2k=`/bin/echo "$lccs" | /usr/bin/awk -F "\t|:" '{print $NF}'`
			/bin/echo $lccs2k
			# /bin/kill -9 $lccs2k &
		fi
	fi
done
IFS="$OLDIFS"

# for i in `seq 1 100` 
# do 
#   /bin/echo "$i\n"
# done