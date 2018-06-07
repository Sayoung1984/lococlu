#! /bin/bash
# echo -e '"/receptionist/func/hijack.sh", the prototype of "receptionist"'
# export LOGNAME=env | grep LOGNAME= | /usr/bin/awk -F "=" '{print $2}'
echo -e "Login UID="$LOGNAME
#echo -e "Hello "`finger $LOGNAME | grep Name: | /usr/bin/awk -F "Name: " '{print $2}'`"!"
echo -e '\n!!!Warning!!!'
echo -e 'Blind selecting nodes!\t\tNode SitRep module under development...'
echo -e 'Exposeing node SitRep speedometer for demo only'
cat /receptionist/nodeload.*
echo -e "\t\t\t\t\t\t     Local timestamp: "`/bin/date +%Y-%m%d-%H%M-%S`
echo -e '\n!!!Warning!!!'
echo -e 'Manual selecting nodes!\t\tLoad balance logic under development...\n'
echo -e '\n!!!Warning!!!'
echo -e 'Plain ssh connection only!\tUser workspace image automount under development...\n'
echo -e '\nHello, Would you like to connect to remote nodes?\n'
echo -e '\t1.Local bash(For prototype demo only)\t 2.ssh to muscle01\t3.ssh to muscle02\t4.ssh to muscle03\n'
echo -e 'You are choosing: \c'
read TARGET_M
case $TARGET_M in
        1)
                exec /bin/bash;;
        2)
                exec /usr/bin/ssh $LOGNAME@muscle01;;
        3)
                exec /usr/bin/ssh $LOGNAME@muscle02;;
        4)
                exec /usr/bin/ssh $LOGNAME@muscle03;;
        *)
                echo "Try again please?";;
esac
