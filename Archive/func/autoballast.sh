#! /bin/bash
LOGICORE=`/usr/bin/lscpu | /bin/grep -v NUMA | /bin/grep -e "CPU(s):" | /usr/bin/awk -F " " '{print $2}'`
# TPCORE=`/usr/bin/lscpu | /bin/grep -v NUMA | /bin/grep -e "Thread" | /usr/bin/awk -F " " '{print $4}'`
while getopts "t:" arg
do
        case $arg in
                t)
                        THRD=$OPTARG
#                       echo "Got THRD=$THRD from argument"
                ;;
                ?)
                        echo "Auto set $THRD thread via CPU core number"
#                       THRD=$(expr $LOGICORE / $TPCORE)
                        THRD=$LOGICORE
#       exit 1
        ;;
        esac
done
if [ ! $THRD ]; then
        echo -e 'Multi-core CPU load ballast script, Pi 100M per thread'
#       echo -e 'Found' $(expr $LOGICORE / $TPCORE)' physical cores.'
        echo -e 'Found' $LOGICORE' cores.'
        echo -e 'Parallel threads to start: \c'
        read THRD
#       THRD=${THRD:-$(expr $LOGICORE / $TPCORE)}
        THRD=${THRD:-$LOGICORE}
fi
echo -e 'Running '$THRD' threads of Pi now...'
for i in $(seq 1 $THRD)
do
        (pi 100000000) &
        if (($i % 10000 == 0)); then wait; fi
done
wait
