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
#    `/bin/cat /proc/loadavg`"\t"CPU: $(/usr/bin/expr $LOGICORE / $TPCORE) cores\@\
#    `/usr/bin/lscpu | /bin/grep 'CPU MHz:' | /usr/bin/awk -F " " '{print $3}'` Mhz"\t" \
    /bin/echo -ne `/bin/hostname`"\t"\
    && /bin/echo -e "scale=2; 100 * `/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'` * $TPCORE / $LOGICORE " | /usr/bin/bc | /usr/bin/tr "\n" "\t" \
    && /bin/echo -e `/bin/date +%Y-%m%d-%H%M-%S`"\t"`date +%s`
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

# Report integrity checker, drop report to NFS at this last step
secrepcp()
{
    for REPLX in `ls /var/log/rep.*`
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
MkImgUser=`/bin/cat /receptionist/opstmp/ticket.mkimg.* 2> /dev/null`
if [ -n "$MkImgUser" ]
	then
#		mv /receptionist/opstmp/ticket.mkimg.$MkImgUser /receptionist/opstmp/done.ticket.mkimg.$MkImgUser	#DBG
		rm -f /receptionist/opstmp/ticket.mkimg.$MkImgUser
		mv /images/vol01/diskinfant /images/vol01/$MkImgUser.img
		MkImgUser=""
fi
}

# General operation executor, run command in tickets as root
geoexec()
{
  if [ -f "/receptionist/opstmp/ticket.geoexec.$(hostname)" ]
    then
      eval $(/bin/cat /receptionist/opstmp/ticket.geoexec.$(hostname))
#      echo -e "#DBG\t"$(/bin/cat /receptionist/opstmp/ticket.geoexec.$(hostname)) >> /receptionist/opstmp/ticket.geoexec.$(hostname)
#      echo -e "#DBG\t$(hostname) got this ticket" >> /receptionist/opstmp/ticket.geoexec.$(hostname)
#      mv /receptionist/opstmp/ticket.geoexec.$(hostname) /receptionist/opstmp/done.ticket.geoexec.$(hostname)
      rm -f /receptionist/opstmp/ticket.geoexec.$(hostname)
  fi
}


# Main function loop
step=1 #Execution time interval, MUST UNDER 3600!!!
for (( i = 0; i < 3600; i=(i+step) ))
    do
        $(
        secrepcp
        loadrep > /var/log/rep.loadrep.`hostname`
        imgonrep > /var/log/rep.imgonrep.`hostname`
        endline | /usr/bin/tee -a /var/log/rep.loadrep.`hostname` >> /var/log/rep.imgonrep.`hostname`
        mkimg
        geoexec

	)
        sleep $step
    done
exit 0
