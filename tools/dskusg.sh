echo -e "VolumePath\tUsed(G)\tCap(G)\tQuotaPerc"
for i in `ls /images | grep -v vol00`
do
	echo -ne "/images/$i \t" 
	quotausage=`ls -l --block-size=g /images/$i |  awk '{ total += $5; print }; END { print total}' | tail -n 1`
	echo -ne "$quotausage \t"
	volsize=`df -BG /images/$i | tail -n 1 | awk '{print $2}' | sed 's/.$//'`
	echo -ne "$volsize \t"
	quotaperc=`echo -e " 100 * $quotausage / $volsize " | /usr/bin/bc`
	echo -e $quotaperc%
done | sort -n -k4
