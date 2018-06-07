#! /bin/bash

# Set log latency threshhold
loglatency=3

listnode()
{
/bin/cat /receptionist/opstmp/secrt.sitrep.load.* | awk '{ print $1"\t"$2"\t"$3"\t"$4"\t"$5}' | sort -n -t$'\t' -k 2 1> /receptionist/opstmp/resource.sortload
chmod 666 /receptionist/opstmp/resource.sortload
NodeLine=`cat /receptionist/opstmp/resource.sortload | head -n 1`
NodeLine_Name=`echo $NodeLine | awk '{print $1}'`
NodeLine_timestamp=`echo -e "$NodeLine" | awk -F " " '{print $NF}'`
NodeLine_latency=`expr $(date +%s) - $NodeLine_timestamp 2>/dev/null`
}


listnode
# echo -e "\n#DBG_C Log latency = $loglatency"
# echo -e "#DBG_C NodeLine_Name = $NodeLine_Name"
# echo -e "#DBG_C NodeLine_timestamp = $NodeLine_timestamp"
# echo -e "#DBG_C NodeLine_latency = $NodeLine_latency\n\n"
echo -e "\nRefreshing node load info.\c"
  while [ "$NodeLine_latency" -gt "$loglatency" ]
		do
      rm -f /receptionist/opstmp/secrt.sitrep.load.$NodeLine_Name
			sleep 1
      listnode
      echo -e ".\c"
#       echo -e "\n#DBG_D NodeLine_Name = $NodeLine_Name"
#       echo -e "#DBG_D NodeLine_timestamp = $NodeLine_timestamp"
#       echo -e "#DBG_D NodeLine_latency = $NodeLine_latency\n\n"
		done
rm -f /receptionist/opstmp/resource.sortload
FreeNode=$NodeLine_Name
echo -e "\n\nSelect $FreeNode as node with lowest load.\n"
