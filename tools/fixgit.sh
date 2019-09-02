#! /bin/bash
OSV=`/usr/bin/lsb_release -r | /usr/bin/awk '{print $2}'`
# echo "OSV=$OSV" #DBG
if [[ "$OSV" = 14.04 ]]
then
	gitsum=`/usr/bin/md5sum /usr/bin/git | /usr/bin/awk '{print $1}'`
	# echo "gitsum=$gitsum" #DBG
	if [[ "$gitsum" != e966ffe0d6766cfc42bd770298d0f833 ]]
	then
		# echo "Patching git!" #DBG
		/usr/bin/dpkg -i /images/vol00/UB1404_ssl_git/git_1.9.1-1ubuntu0.10_amd64.deb
	# else #DBG
	# 	echo "No patch needed!" #DBG
	fi
fi