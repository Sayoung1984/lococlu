#~ /bin/bash
rm -f ./resource.node
for node in `cat ../secrep.loadrep.*`
	do
		touch ./resource.node
		echo -e $node "\t" $(expr $(wc -l ./resource.node| awk -F " " '{print $1}') + 1) >> resource.node
	done
