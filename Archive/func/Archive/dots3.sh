#! /bin/bash
echo -e "Running jobs \c"
var=1
while [ "$var" -le 5 ]
do 
	echo -ne "."
	var=$(($var+1))
	sleep 1
done
echo
