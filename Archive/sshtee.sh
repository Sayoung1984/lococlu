#! /bin/bash

# tee_out prototype

tee_out()
{
	/usr/bin/tee >(tee_filter)
}


tee_filter()
{
output=/tmp/lcclog.`/bin/date +%y%m%d-%H%M%S`.$LOGNAME
# output=/tmp/lcclog.$LOGNAME
echo -e "\n`/bin/date +%Y-%m%d-%H%M-%S`\t User= $LOGNAME\n">$output
# i=1
while read line
do
    # echo -en "line$i\t" >> $output; i=$(($i+1))
	
	echo $line >> $output
    if [ -n "`echo $line | grep '^Last login'`" ]
    then
		/bin/echo -e "\nUser got into the target node.\n\n" >> $output
		# output=/dev/null
		tee_passthrough
    fi
done
}

tee_passthrough()
{
 # ls -l /dev/fd/ >> /tmp/lcclog.$LOGNAME
 /bin/cat > printf
}


main_out()
{
for i in {250..255}
do
    echo $(($i*$(($i+1))))
done

    ssh $LOGNAME@testlab-sha4
}


main_out | tee_out