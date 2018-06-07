#! /bin/bash

# noderep.sh single instance lock
pidpath=/tmp/noderep.pid
if [ -f "$pidpath" ]
    then
        kill `/bin/cat $pidpath`>/dev/null 2>&1
        /bin/rm -f $pidpath
fi
echo $$ >$pidpath

COLUMNS=300
endline="###---###---###---###---###"

# Fixed parameters for CPU info
# CPUFREQ=`cat /proc/cpuinfo | /bin/grep "model name" | /usr/bin/uniq | /bin/sed -r 's/.*@ (.*)GHz.*/\1/'` # Not compatible with AMD CPU
# CPUFREQ=`/bin/lscpu | /bin/grep 'max' | /usr/bin/awk -F " " '{print $4}'` # Not compatible with VM
# CPUFREQ=`/bin/lscpu | /bin/grep 'CPU MHz:' | /usr/bin/awk -F " " '{print $3}'` # Dynamic value, move to loadrep()
# LOGICORE=`/bin/cat /proc/cpuinfo | /bin/grep siblings | /usr/bin/uniq | /usr/bin/awk -F ": " '{print $2}'`
# LOGICORE=`/usr/bin/lscpu | /bin/grep -v NUMA | /bin/grep -e "CPU(s):" | /usr/bin/awk -F " " '{print $2}'`
LOGICORE=`nproc --all`
# nproc=LOGICORE
TPCORE=`/usr/bin/lscpu | /bin/grep -e "Thread" | /usr/bin/awk -F " " '{print $4}'`

# System load info structure in "Hostname"  "PerfIndex" "SHORTLOAD" "Timestamp human" "Timestamp machine"
# PerfIndex = 10*liveUsers + 100*Loadavg / PhysicCores
loadrep()
{
    #CPUUSE=`top -d 0.2 -bn 3 | grep "%Cpu(s)" | tail -n 1 | awk '{print 100-$8}'`
    SHORTLOAD=`/bin/cat /proc/loadavg | /usr/bin/awk '{print $1}'`
    USERCOUNT=`/usr/bin/w -h |  /usr/bin/awk '{print $1}' | /usr/bin/sort | /usr/bin/uniq | /usr/bin/wc -l`
    /bin/echo -ne `/bin/hostname`"\t"
    /bin/echo -e "scale=2; 10 * $USERCOUNT + 100 * $SHORTLOAD * $TPCORE / $LOGICORE " | /usr/bin/bc | /usr/bin/tr "\n" "\t"
    # /bin/echo -ne $USERCOUNT "live users\t"`/bin/cat /proc/loadavg`"\t"CPU: $(/usr/bin/expr $LOGICORE / $TPCORE) cores\@
    # /bin/echo -ne `/usr/bin/lscpu | /bin/grep 'CPU MHz:' | /usr/bin/awk -F " " '{print $3}'` Mhz"\t"
    /bin/echo -e " 100 * $SHORTLOAD* $TPCORE / $LOGICORE "| /usr/bin/bc | /usr/bin/awk -F "." '{print $1}' | /usr/bin/tr "\n" "\t"
    #/bin/echo -e " 10 * $CPUUSE "| /usr/bin/bc | /usr/bin/awk -F "." '{print $1}' | /usr/bin/tr "\n" "\t"
    /bin/echo -e `/bin/date +%Y-%m%d-%H%M-%S`"\t"`/bin/date +%s`
    /bin/echo -e "$endline" `hostname`
}

# IMGoN mount info structure v2
imgonrep()
{
  for LOOPIMG in `COLUMNS=300 /sbin/losetup -a | /bin/grep -v snap | /usr/bin/awk -F "[()]" '{print $2}'`
  do
    /bin/echo -e `/bin/hostname`"\t\c"
    /bin/echo -e $LOOPIMG"\t\c"
    /bin/mount | /bin/grep $LOOPIMG | /usr/bin/awk -F " " '{printf $3}'
    /bin/echo -e "\t"`/bin/date +%Y-%m%d-%H%M-%S`"\t"`/bin/date +%s`
  done
  /bin/echo -e "$endline" `hostname`
}

# Secure Real Time Text Copy, check text integrity, then drop real time text to NFS at this last step
secrttcp_old()
{
    for REPLX in `/bin/ls /var/log/rt.*`
        do
            rpcheckline=`/usr/bin/tail -n 1 $REPLX`
            if [ "$rpcheckline"  != "###---###---###---###---###" ]
                then
                    /bin/rm $REPLX
                else
                    /bin/sed -i '$d' $REPLX
		    rpchecklineL2=`/usr/bin/tail -n 1 $REPLX`
		    if [ "$rpchecklineL2"  == "###---###---###---###---###" ]
		    	then
			     /bin/rm $REPLX
			else
			     REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
		    	     cp $REPLX `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
                    # cp $REPLX `echo $REPLX | /bin/sed 's/\/var\/log/\/receptionist/'`
					 chmod 666 `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
		    fi
            fi
        done
}

# Secure Realtime Text Copy v2, check text integrity, then drop real time text to NFS at this last step, with endline
# /bin/sed -i '$d' $REPLX # To cat last line, on receive side
secrtsend()
{
  for REPLX in `/bin/ls /var/log/rt.* 2>/dev/null`
  do
    CheckLineL1=`/usr/bin/tac $REPLX | sed -n '1p'`
    CheckLineL2=`/usr/bin/tac $REPLX | sed -n '2p'`
    if [ "$CheckLineL1"  == "$endline `hostname`" -a "$CheckLineL2"  != "$endline `hostname`" ]
    then
      REPLXNAME=`/bin/echo $REPLX | /usr/bin/awk -F "/var/log/" '{print $2}'`
      cp $REPLX `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
      chmod 666 `/bin/echo -e "/receptionist/opstmp/sec$REPLXNAME"`
    else
      # mv $REPLX.fail  #DBG
      /bin/rm $REPLX
    fi
  done
}

# Infant image maker, !!! current only for /images/vol01 !!!
mkinfantimg()
{
    if [ ! -f /images/vol01/diskinfant ]
	then
		/bin/dd if=/dev/zero of=/images/vol01/diskinfant bs=1G count=0 seek=500
		/bin/chmod 666 /images/vol01/diskinfant
		/sbin/mkfs.ext4 -Fq /images/vol01/diskinfant 500G
		sleep 1
    fi
}

# User image maker
mkuserimg()
{
    MkImgUser=`/bin/cat /receptionist/opstmp/secrt.ticket.mkimg.* 2> /dev/null`
    /bin/echo -e "DBG_MkImgUser_A MkImgUser=$MkImgUser" > /root/DBG_MkImgUser_A
    if [ -n "$MkImgUser" ]
    then
#    	mv /receptionist/opstmp/secrt.ticket.mkimg.$MkImgUser /receptionist/opstmp/done.secrt.ticket.mkimg.$MkImgUser	#DBG
    	rm -f /receptionist/opstmp/secrt.ticket.mkimg.$MkImgUser
    	mv /images/vol01/diskinfant /images/vol01/$MkImgUser.img
    	MkImgUser=""
    fi
}

# General operation executor, run command in tickets as root
geoexec_old()
{
  if [ -f "/receptionist/opstmp/secrt.ticket.geoexec.$(hostname)" ]
    then
      eval $(/bin/cat /receptionist/opstmp/secrt.ticket.geoexec.$(hostname))
      echo $(/bin/cat /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)) > /local/mnt/workspace/CMD_LOG     #DBG show last ticket command
      # /bin/echo -e "#DBG\t"$(/bin/cat /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)) >> /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)
      # /bin/echo -e "#DBG\t$(hostname) got this secrt.ticket" >> /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)
      mv /receptionist/opstmp/secrt.ticket.geoexec.$(hostname) /receptionist/opstmp/done.secrt.ticket.geoexec.$(hostname)   #DBG Save last ticket
      # /bin/rm -f /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)
  fi
}

# General Operation Executor v2, run command in tickets as root
geoexec()
{
  if [ -f "/receptionist/opstmp/secrt.ticket.geoexec.$(hostname)" ]
    then
      eval $(/bin/cat /receptionist/opstmp/secrt.ticket.geoexec.$(hostname))
      echo $(/bin/cat /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)) > /local/mnt/workspace/CMD_LOG     #DBG show last ticket command
      # /bin/echo -e "#DBG\t"$(/bin/cat /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)) >> /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)
      # /bin/echo -e "#DBG\t$(hostname) got this secrt.ticket" >> /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)
      mv /receptionist/opstmp/secrt.ticket.geoexec.$(hostname) /receptionist/opstmp/done.secrt.ticket.geoexec.$(hostname)   #DBG Save last ticket
      # /bin/rm -f /receptionist/opstmp/secrt.ticket.geoexec.$(hostname)
  fi
}

# Main function loop
step=1 #Execution time interval, MUST UNDER 3600!!!
for (( i = 0; i < 3600; i=(i+step) ))
    do
        $(
        loadrep > /var/log/rt.sitrep.load.`hostname`
        imgonrep > /var/log/rt.sitrep.imgon.`hostname`
        # imgonrep > /root/dbg_imgonrep
        # /bin/echo -e "$endline" `hostname` >> /var/log/rt.sitrep.load.`hostname`
        # /bin/echo -e "$endline" `hostname` >> /var/log/rt.sitrep.imgon.`hostname`
        secrtsend
        mkuserimg
        mkinfantimg
        geoexec
	)
        sleep $step
    done
exit 0
