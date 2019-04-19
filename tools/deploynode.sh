#! /bin/bash
apt-get update && apt-get install -y automake build-essential chrpath cscope cvs diffstat dos2unix finger flex gawk gcc-multilib git-core g++-multilib htop lib32bz2-dev lib32gcc1 lib32gomp1 lib32ncurses5 lib32stdc++6 lib32z1 lib32z1-dev libc6-i386 libglib2.0-dev libsdl1.2-dev libssl-dev libtool lzop python-dev speedometer subversion sysstat texinfo tmux unzip wget xterm xutils-dev
mv /bin/sh /bin/sh.bak && sudo ln -sf /bin/bash /bin/sh
mkdir -p /images/vol01 /images/vol02 /receptionist
echo -e "chess:/vol/eng_sh_quicdata_02/build_test\t/receptionist\tnfs\tdefaults\t0\t0\ngrilled:/build_store2\t/images/vol01\tnfs\tdefaults\t0\t0\nchess:/vol/eng_sh_quicdata_02/build_test/vol02\t/images/vol02\tnfs\tdefaults\t0\t0" >> /etc/fstab
mount -a
duty remove local-sudo.enable
echo -e "* */1 * * * /receptionist/lococlu/noderep.sh" >> /var/spool/cron/root
service cron restart
