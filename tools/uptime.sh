#! /bin/bash
upt=`/bin/cat /proc/uptime | /usr/bin/awk -F "." '{print $1}'`
# hour=$(( $upt/3600 ))
# min=$(( ($upt-${hour}*3600)/60 ))
# sec=$(( $upt-${hour}*3600-${min}*60 ))
# /bin/echo $hour"h."$min"m."$sec"s"

# /bin/echo -e "init, upt=$upt"
if [ "$1" != "-h" ]
then
	/bin/echo $upt
else
	if [ "$upt" -ge 604800 ]
	then
		week=‬$(( $upt/604800 ))
		upt=$(( $upt%604800 ))
		opstr=`/bin/echo $week"w."`
	fi
	if [ "$upt" -ge 86400 ]
	then
		day=$(( $upt/86400 ))
		upt=$(( $upt%86400 ))
		opstr=`/bin/echo $opstr$day"d."`
	fi
	if [ "$upt" -ge 3600 ]
	then
		hour=$(( $upt/3600 ))
		upt=$(( $upt%3600 ))
		opstr=`/bin/echo $opstr$hour"h."`
	fi
	if [ "$upt" -ge 60 ]
	then
		min=$(( $upt/60 ))
		upt=$(( $upt%60 ))
		opstr=`/bin/echo $opstr$min"m."`
	fi
	if [ "$upt" -gt 0 ]
	then
		sec=$upt
		opstr=`/bin/echo $opstr$sec"s"`
	fi
	/bin/echo "$opstr"
fi

free_opt=`free`
# echo "$free_opt"
ram_all=`/bin/echo "$free_opt" | /bin/grep "Mem:" | /usr/bin/awk '{print $2}'`
ram_used=`/bin/echo "$free_opt" | /bin/grep "cache:" | /usr/bin/awk '{print $3}'`
swap_all=`/bin/echo "$free_opt" | /bin/grep "Swap:" | /usr/bin/awk '{print $2}'`
swap_used=`/bin/echo "$free_opt" | /bin/grep "Swap:" | /usr/bin/awk '{print $3}'`

# echo -e "$ram_all\n$ram_used"
# echo -e "$swap_all\n$swap_used"
ram_pct=`/bin/echo -e "scale=2; 100 * $ram_used / $ram_all " | /usr/bin/bc`
swap_pct=`/bin/echo -e "scale=2; 100 * $swap_used / $swap_all " | /usr/bin/bc`
echo -e "$ram_pct\n$swap_pct"