#! /bin/bash
echo "Choose red, green or blue"
read ipcolor
valid="red|green|blue"
echo -e "DBG001 ipcolor=$ipcolor valid=$valid"
eval "case \"$ipcolor\" in
    $valid)
#        echo -e "DBG002 ipcolor=$ipcolor valid=$valid"
    	echo $LOGNAME chose $ipcolor
        echo do something good here
        ;;
    *)
#        echo -e "DBG003 ipcolor=$ipcolor valid=$valid"
	echo invalid colour
        ;;
esac"
