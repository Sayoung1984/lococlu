#! /bin/bash
# First working prototype CPU usage monitor
v1()
{
  while true ; do
    #echo -e "#DBG#"
    # LineTick=`cat /proc/stat | grep '^cpu ' | awk '{$1=null;print $0}' | sed 's/^[ \t]*//g'`
    LineTick=`cat /proc/stat | grep '^cpu ' | sed 's/^cpu[ \t]*//g'`
    SumTick=`echo $LineTick | /usr/bin/tr " " "+" | /usr/bin/bc`
    IdleTick=`echo $LineTick | awk '{print $4}'`
    sleep 1
    #LineTock=`cat /proc/stat | grep '^cpu ' | awk '{$1=null;print $0}' | sed 's/^[ \t]*//g'`
    LineTock=`cat /proc/stat | grep '^cpu ' | sed 's/^cpu[ \t]*//g'`
    SumTock=`echo $LineTock | /usr/bin/tr " " "+" | /usr/bin/bc`
    IdleTock=`echo $LineTock | awk '{print $4}'`
    DiffSum=`expr $SumTock - $SumTick`
    DiffIdle=`expr $IdleTock - $IdleTick`
    #if [ "$DiffSum" > "$DiffIdle" > 0 ]
    #then
    CPULoad=`printf %.$2f $(/bin/echo -e "scale=2; 100 * ( $DiffSum - $DiffIdle ) / $DiffSum " | /usr/bin/bc)`
    #fi
    # #DBG Debug output as below
    # echo -e "$LineTick"
    # echo -e "$LineTock"
    # echo -e "SumTick = $SumTick"
    # echo -e "SumTock = $SumTock"
    # echo -e "IdleTick = $IdleTick"
    # echo -e "IdleTock = $IdleTock"
    # echo -e "DiffSum = $DiffSum"
    # echo -e "DiffIdle = $DiffIdle"
    echo -e "CPULoad = $CPULoad %\n"
  done
}


# The secound version of CPU usage monitor, a sleep between pairs of tick and tock
cputick()
{
  LineTick=`cat /proc/stat | grep '^cpu ' | sed 's/^cpu[ \t]*//g'`
  SumTick=`echo $LineTick | /usr/bin/tr " " "+" | /usr/bin/bc`
  IdleTick=`echo $LineTick | awk '{print $4}'`
}

cputock()
{
  LineTock=`cat /proc/stat | grep '^cpu ' | sed 's/^cpu[ \t]*//g'`
  SumTock=`echo $LineTock | /usr/bin/tr " " "+" | /usr/bin/bc`
  IdleTock=`echo $LineTock | awk '{print $4}'`
  # SumTock=`cat /proc/stat | grep '^cpu ' | awk '{$1=null;print $0}' | sed 's/^[ \t]*//g' | /usr/bin/tr " " "+" | /usr/bin/bc`
  # IdleTock=`cat /proc/stat | grep '^cpu '| awk '{print $5}'`
  DiffSum=`expr $SumTock - $SumTick`
  DiffIdle=`expr $IdleTock - $IdleTick`
  CPULoad=`printf %.$2f $(/bin/echo -e "scale=2; 100 * ( $DiffSum - $DiffIdle ) / $DiffSum " | /usr/bin/bc)`
  # #DBG Debug output as below
  # echo -e "SumTick = $SumTick"
  # echo -e "SumTock = $SumTock"
  # echo -e "IdleTick = $IdleTick"
  # echo -e "IdleTock = $IdleTock"
  # echo -e "DiffSum = $DiffSum"
  # echo -e "DiffIdle = $DiffIdle"
  echo -e "CPULoad = $CPULoad %"
}

##### Main functions below #####

# v1

# Run v2 in a loop, for noderep deamon of lococlu system
while true
do
  cputick
  sleep 1
  cputock
done
