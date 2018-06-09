#! /bin/bash
# Prototype of ticktock flips per 1 sec. A method to solve realtime CPU usage status issue
# For $tick, $tock = last sec; so does $tock. Set $tick=CCC to break
# Doing real job in MainFunc
filper()
{
  while [ "tick" != "CCC" ]
  do
    tick=AAA
    tock=BBB
    MainFunc
    sleep 1
    tick=BBB
    tock=AAA
    MainFunc
    sleep 1
  done
}

sumtick()
{
  sum=0
  for i in `cat /tmp/CPU.$tick`
  do
    sum=$(($sum+$i))
  done
  SumTick=$sum
}

sumtock()
{
  sum=0
  for i in `cat /tmp/CPU.$tock`
  do
    sum=$(($sum+$i))
  done
  SumTock=$sum
}

MainFunc()
{
  #echo -e `cat /proc/stat | grep '^cpu ' | awk '{$1=null;print $0}'`"\t"`date +%s`> /tmp/CPU.$tick
  echo -e `cat /proc/stat | grep '^cpu ' | awk '{$1=null;print $0}' | sed 's/^[ \t]*//g'` > /tmp/CPU.$tick
  LineTick=`cat /tmp/CPU.$tick`
  LineTock=`cat /tmp/CPU.$tock`
  #sumtick
  #sumtock
  SumTick=`cat /tmp/CPU.$tick | tr " " "+" | /usr/bin/bc`
  SumTock=`cat /tmp/CPU.$tock | tr " " "+" | /usr/bin/bc`
  IdleTick=`echo $LineTick | awk '{print $4}'`
  IdleTock=`echo $LineTock | awk '{print $4}'`
  DiffSum=`expr $SumTick - $SumTock`
  DiffIdle=`expr $IdleTick - $IdleTock`
  CPULoad=`/bin/echo -e "scale=2; 100 * ( $DiffSum - $DiffIdle ) / $DiffSum " | /usr/bin/bc`
  # echo -e "$LineTick"
  # echo -e "$LineTock"
  # echo -e "SumTick = $SumTick"
  # echo -e "SumTick = `cat /tmp/CPU.$tick | tr " " "+" | /usr/bin/bc`"
  # echo -e "SumTock = $SumTock"
  # echo -e "IdleTick = $IdleTick"
  # echo -e "IdleTock = $IdleTock"
  # echo -e "DiffSum = $DiffSum"
  # echo -e "DiffIdle = $DiffIdle"
  echo -e "CPULoad=$CPULoad"
}

filper
