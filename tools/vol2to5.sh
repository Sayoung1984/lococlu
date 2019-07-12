#! /bin/bash

COLUMNS=512
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
		cp --sparse=always /images/vol02/$tgt.img /images/vol05/$tgt
		checkStd=`cat $opstmp/secrt.sitrep.* | grep $tgt`
		if [ -n "$checkStd" ]
		then
			mv /images/vol05/$tgt /images/vol05/abort.$tgt
			echo -e "$tgt image move abort!\t$(date)" >> /images/vol05/movelog
		else
			mv /images/vol02/$tgt.img /images/vol02/$tgt
			mv /images/vol05/$tgt /images/vol05/$tgt.img
			sizeO=`ls -l /images/vol02/$tgt | awk '{print $5}'`
			sizeT=`ls -l /images/vol05/$tgt.img | awk '{print $5}'`
			check0=$(($sizeO-$sizeT))
			check1=`cmp -n 1GB /images/vol02/$tgt /images/vol05/$tgt.img`
			check2=`cmp -i 200GB -n 1GB /images/vol02/$tgt /images/vol05/$tgt.img`
			check3=`cmp -i 400GB -n 1GB /images/vol02/$tgt /images/vol05/$tgt.img`
			if [ "$check0" != 0 -o -n "$check1" -o -n "$check2" -o -n "$check3" ]
			then
				mv /images/vol02/$tgt /images/vol02/$tgt.img
				mv /images/vol05/$tgt.img /images/vol05/reverse.$tgt
				echo -e "$tgt image move incomplete! Reverse move!\t$(date)" >> /images/vol05/movelog
			else
				mv /images/vol02/$tgt /images/vol02/done.$tgt
				echo -e "$tgt image move complete!\t$(date)" >> /images/vol05/movelog
			fi
		fi
	fi
	}&
done
