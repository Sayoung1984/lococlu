#! /bin/bash
watch -n 0.1 -c "load_raw=\$(cat /LCC/opstmp/secrt.sitrep.* | grep -a log=load);\
/bin/echo -en "node count= "; /bin/echo -e \"\$load_raw\" | wc -l; \
/bin/echo -e \"node_name\tlog_type\tLoad_C\tPerf_R\tCPU\tIO\tRAM\tSWAP\tUSER\tAR\tuptm\ttmsp\t\tlag\"; \
/bin/echo -e \"\$load_raw\" | awk '{now=systime();printf \$0 \"\t\" now-\$(NF)\"\n\"}'| \
while read line; do if [ \$(/bin/echo \$line | awk '{print \$NF}') -ge 2 ] ; \
then /bin/echo -e \"\\\033[31m\$line\\\033[0m\" ; else /bin/echo -e \"\$line\"; fi; done"