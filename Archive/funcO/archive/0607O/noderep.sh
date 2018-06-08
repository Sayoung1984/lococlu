#! /bin/bash

# noderep.sh single instance lock
pidpath=/tmp/noderep.pid
if [ -f "$pidpath" ]
    then
        kill `/bin/cat $pidpath`>/dev/null 2>&1
        rm -f $pidpath
fi
echo $$ >$pidpath

# Fixed parameters for CPU info
# LOGICORE=`/bin/cat /proc/cpuinfo | /bin/grep siblings | /usr/bin/uniq | /usr/bin/awk -F ": " '{print $2}'`
LOGICORE=`/usr/bin/lscpu | /bin/grep -v NUMA | /bin/grep -e "CPU(s):" | /usr/bin/awk -F " " '{print $2}'`
TPCORE=`/usr/bin/lscpu | /bin/grep -e "Thread" | /usr/bin/awk -F " " '{print $4}'`
# CPUFREQ=`cat /proc/cpuinfo | grep "model name" | uniq | sed -r 's/.*@ (.*)GHz.*/\1/'` # Not compatible with AMD CPU
# CPUFREQ=`lscpu | grep 'max' | awk -F " " '{print $4}'` # Not compatible with VM
# CPUFREQ=`lscpu | grep 'CPU MHz:' | awk -F " " '{print $3}'` # Dynamic value

# System load info structure
loadrep()
{
    /bin/echo -ne `/bin/hostname`"\t"
    SHORTLOAD=`/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'`
    USERCOUNT=`w -h |  awk '{print $1}' | sort | uniq | wc -l`
    /bin/echo -e "scale=2; 100 * $SHORTLOAD * $TPCORE / $LOGICORE " | /usr/bin/bc | /usr/bin/tr "\n" "\t"
#    /bin/echo -ne $USERCOUNT "live users\t"`/bin/cat /proc/loadavg`"\t"CPU: $(/usr/bin/expr $LOGICORE / $TPCORE) cores\@
#    /bin/echo -ne `/usr/bin/lscpu | /bin/grep 'CPU MHz:' | /usr/bin/awk -F " " '{print $3}'` Mhz"\t"
    /bin/echo -e `/bin/date +%Y-%m%d-%H%M-%S`"\t"`date +%s`
}

# IMGoN mount info structure
imgonrep()
{
    for IMGONMP in `COLUMNS=300 /bin/lsblk | /bin/grep -v snap | /bin/grep "loop" | /usr/bin/awk '{print $NF}'`
        do
            /bin/echo -e `/bin/hostname`"\t\c"
            /bin/echo -e $IMGONMP"\t\c"
            /bin/mount | /bin/grep $IMGONMP | /usr/bin/awk -F " on " '{printf $1}'
            /bin/echo -e "\t"`/bin/date +%Y-%m%d-%H%M-%S`"\t"`date +%s`
        done
}

# Unique finish tag to ensure report integrity
endline()
{
    /bin/echo -e "---###---###---###---###---"
}

# Secure Real Time Text Copy, check text integrity, then drop real time text to NFS at this last step
secrttcp()
{
    for REPLX in `ls /var/log/rt.*`
        do
            rpcheckline=`/usr/bin/tail -n 1 $REPLX`
            if [ "$rpcheckline"  != "---###---###---###---###---" ]
                then
                    rm $REPLX
                else
                    /bin/sed -i '$d' $REPLX
		    rpchecklineL2=`/usr/bin/tail -n 1 $REPLX`
		    if [ "$rpchecklineL2"  == "---###---###---###---###---" ]
		    	then
			     rm $REPLX
			else
			     REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
		    	     cp $REPLX `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
#                    	     cp $REPLX `echo $REPLX | sed 's/\/var\/log/\/receptionist/'`
					 chmod 666 `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
		    fi
            fi
        done
}

# User image maker
mkimg()
{
if [ ! -f /images/vol01/diskinfant ]
	then
		/bin/dd if=/dev/zero of=/images/vol01/diskinfant bs=1G count=0 seek=500
		/bin/chmod 666 /images/vol01/diskinfant
		/sbin/mkfs.ext4 -Fq /images/vol01/diskinfant 500G
		sleep 1
fi
MkImgUser=`/bin/cat /receptionist/opstmp/secrt.ticket.mkimg.* 2> /dev/null`
if [ -n "$MkImgUser" ]
	then
#		mv /receptionist/opstmp/secrt.ticket.mkimg.$MkImgUser /receptionist/opstmp/done.secrt.ticket.mkimg.$MkImgUser	#DBG
		rm -f /receptionist/opstmp/secrt.ticket.mkimg.$MkImgUser
		mv /images/vol01/diskinfant /images/vol01/$MkImgUser.img
		MkImgUser=""
fi
}

# General operation executor, run command in tickets as root
geoexec()
{
  if [ -f "/receptionist/opstmp/secrt.ticket.geoexec.$(hostname)" ]
    then
      eval $(/bin/cat /receptionist/opstmp/secrt.ticket.geoexec.$(hostname))
#      echo -e "#DBG\t"$(/bin/cat /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)) >> /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)
#      echo -e "#DBG\t$(hostname) got this secrt.ticket" >> /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)
#      mv /receptionist/opstmp/secrt.ticket.geoexec.$(hostname) /receptionist/opstmp/done.secrt.ticket.geoexec.$(hostname)
      rm -f /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)
  fi
}


# Main function loop
step=1 #Execution time interval, MUST UNDER 3600!!!
for (( i = 0; i < 3600; i=(i+step) ))
    do
        $(
        secrttcp
        loadrep > /var/log/rt.sitrep.load.`hostname`
        imgonrep > /var/log/rt.sitrep.imgon.`hostname`
        endline | /usr/bin/tee -a /var/log/rt.sitrep.load.`hostname` >> /var/log/rt.sitrep.imgon.`hostname`
        mkimg
        geoexec

	)
        sleep $step
    done
exit 0
