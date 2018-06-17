#! /bin/bash
cat ../lcc.conf
source ../lcc.conf
echo -e "#DBG_start"
echo -e "COLUMNS=$COLUMNS"
echo -e "endline=$endline"
echo -e "paraopstmp=$paraopstmp"
echo -e "opstmp=$opstmp"
ls -l $opstmp
