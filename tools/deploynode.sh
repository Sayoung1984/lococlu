#! /bin/bash
apt-get update && apt-get install -y finger htop speedometer sysstat tmux cscope chrpath texinfo libssl-dev dos2unix lzop gcc-multilib g++-multilib
mv /bin/sh /bin/sh.bak && sudo ln -sf /bin/bash /bin/sh
mkdir -p /images/vol01 /images/vol02 /receptionist
echo -e "chess:/vol/eng_sh_quicdata_02/build_test\t/receptionist\tnfs\tdefaults\t0\t0\ngrilled:/build_store2\t/images/vol01\tnfs\tdefaults\t0\t0\nchess:/vol/eng_sh_quicdata_02/build_test/vol02\t/images/vol02\tnfs\tdefaults\t0\t0" >> /etc/fstab
mount -a
duty remove local-sudo.enable
echo -e "* */1 * * * /receptionist/lococlu/noderep.sh" >> /var/spool/cron/root
service cron restart
