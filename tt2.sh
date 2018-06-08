#! /bin/bash
#Prototype of ticktock flips per 1 sec.
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

MainFunc()
{
	echo -e "tick = $tick"
	echo -e "tock = $tock\n"
}

filper