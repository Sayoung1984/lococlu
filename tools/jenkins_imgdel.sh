#! /bin/bash
 # FOLDER1=LA.UM-XXX && FOLDER2= && FOLDER3=/images/vol00/LE.UM.0.0-20190510155420
 # BUILD_USER=$LOGNAME

if [[  $Data_backup_verification =~ ^([No]) ]]; then
   echo No
   exit
fi

mail_notice() {
/usr/lib/sendmail $mail_users
}

## set mail header
###### dont intent this since sendmail needs to read it
mail_font() {
cat << EOF
MIME-Version: 1.0
Content-Type: text/html
Content-Disposition: inline
<html>
<body>
<pre style="font: monospace">
EOF
}

mail_header() {
from="China-SW-EC <china-sw-ec.tx@qti.qualcomm.com>"
replyto="China-SW-EC <china-sw-ec.tx@qti.qualcomm.com>"
subject="AFBF branch deletion for ${BUILD_USER}"
cat << EOF
From: $from
To: $mail_users
Subject: $subject
Reply-To: $replyto
EOF
###### end dont intent section

}

mail_body(){
cat << EOF
Hello$user_full_name,

Thanks for using Android Fast Build Farm, aka AFBF. 

EOF
}

mail_footer() {

cat << EOF


China SW EC Team
</pre>
</body>
</html>
EOF
}

user_full_name=`ph user_account=${BUILD_USER} | grep name | awk -F: '{print $2}' | awk -F, '{print $2}' | sed "s/  / /g"`
NOTICE=chn.afbf.notice@qti.qualcomm.com
#NOTICE="ziyij@qti.qualcomm.com"

mail_users="${BUILD_USER}@qti.qualcomm.com,$NOTICE"

dir=/receptionist/lococlu/tools
MAIL_OUT=$dir/mail_notice

mail_header > ${MAIL_OUT}
mail_font >> ${MAIL_OUT}
mail_body >> ${MAIL_OUT}

c=0
for folder in $FOLDER1 $FOLDER2 $FOLDER3
do
        FOLDER=`echo $folder | sed 's/;$//g;s/\/$//g' | awk -F"/" '{print $NF}'`
        echo "FOLDER is $FOLDER"
        if [ -f "/images/vol00/$FOLDER..${BUILD_USER}.img" ]; then
                killlist[$c]="$FOLDER..${BUILD_USER}.img"
                echo "killlist is ${killlist[$c]}" >> $MAIL_OUT
                ((c++))
        else
                echo "$FOLDER not found. Please check if you have input the right folder name!" >> $MAIL_OUT
        fi
done
Tgtlist=$(for item in ${killlist[@]}; do echo $item; done)
# echo -e "!!!KABOOOOM!!! $Tgtlist !!!KABOOOOM!!!"
/receptionist/lococlu/tools/imgdel.sh -i "$Tgtlist" >> $MAIL_OUT
cat $MAIL_OUT

mail_footer >> ${MAIL_OUT}
cat ${MAIL_OUT} | mail_notice
