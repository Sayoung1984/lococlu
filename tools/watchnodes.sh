#! /bin/bash
watch -d -n 0.1 "echo 'node_name\tlog_type\tLoad_C\tPerf_R\tCPU\tIO\tRAM\tSWAP\tUSER\tAR\tuptm\ttmsp\t\tlag'; \
cat /LCC/opstmp/secrt.sitrep.* | grep log=load | awk '{now=systime();printf \$0 \"\t\" now-\$(NF)\"\n\"}'"

