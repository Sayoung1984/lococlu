#! /bin/bash
# LCC debug tool of check sitrep line counts in every second. for ((i=0;i<3600;i=(i+1)));do cat /LCC/opstmp/secrt.sitrep.muscle01 | grep imgon | wc -l ; sleep 1 ;done ###Check sitrep output line count
for ((i=0;i<3600;i=(i+1)))
do
	sleep 1
	RepSnapShoot=`/bin/cat /LCC/opstmp/secrt.sitrep.* | /bin/grep -v "###"`

	for CurrNode in `/bin/echo -e "$RepSnapShoot" | /usr/bin/awk '{print $1}' | /usr/bin/sort -u`
	do
		CurrSnapShoot=`/bin/echo -e "$RepSnapShoot" | /bin/grep $CurrNode`
		CurrLoad=`/bin/echo -e "$CurrSnapShoot" | /bin/grep load | /usr/bin/wc -l`
		CurrULSC=`/bin/echo -e "$CurrSnapShoot" | /bin/grep ulsc | /usr/bin/wc -l`
		CurrImgon=`/bin/echo -e "$CurrSnapShoot" | /bin/grep imgon | /usr/bin/wc -l`
		/bin/echo -e "$CurrNode load=$CurrLoad ulsc=$CurrULSC imgon=$CurrImgon"
	done

done | /bin/grep node-sh-05
exit 0
