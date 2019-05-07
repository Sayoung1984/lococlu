#! /bin/bash
echo -e "VolumePath\tUsed(G)\tFree(G)\tCap(G)\tHardPct\tSoftPct"
for i in `ls /images`
do
	echo -ne "/images/$i \t"
	quotausage=`ls -l --block-size=g /images/$i |  awk '{ total += $5; print }; END { print total}' | tail -n 1`
	echo -ne "$quotausage \t"
	volfree=`df -BG /images/$i | tail -n 1 | awk '{print $4}' | sed 's/.$//'`
	echo -ne "$volfree \t"
	volsize=`df -BG /images/$i | tail -n 1 | awk '{print $2}' | sed 's/.$//'`
	echo -ne "$volsize \t"
	hardpct=`echo -e " 100 - 100 * $volfree / $volsize " | /usr/bin/bc`
	echo -ne "$hardpct% \t"
	softpct=`echo -e " 100 * $quotausage / $volsize " | /usr/bin/bc`
	echo -e $softpct%
done | sort -n -k4
