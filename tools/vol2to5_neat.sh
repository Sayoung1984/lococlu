#! /bin/bash

export COLUMNS=512
endline="###---###---###---###---###"
loglatency=3
opstmp=/LCC/opstmp
lococlu=/LCC/bin
source /LCC/bin/lcc.conf

namelist()
{
	ls /images/vol02 | grep ".img" | awk -F ".img" '{print $1}'
}

for tgt in $(namelist)
do
	{
	node=
	loginStd=`cat $opstmp/secrt.sitrep.* | grep "=ulsc" | grep $tgt`
	mountStd=`cat $opstmp/secrt.sitrep.* | grep "=imgon" | grep $tgt`
	if [ -n "$loginStd" ]
	then
		node=`echo -e $loginStd | awk '{print $1}'`
		echo -e "online: \t$node\t$tgt"
	elif [ -n "$mountStd" ]
	then
		node=`echo -e $mountStd | awk '{print $1}'`
		echo -e "mounted:\t$node\t$tgt"

	else
		echo -e "clear:  \t_\t$tgt"
		# Place of real move operations.
	fi
	}&
done | sort
