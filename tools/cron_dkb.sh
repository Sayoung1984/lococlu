#! /bin/bash
source /etc/environment
/LCC/bin/tools/dskbill.sh > /LCC/opstmp/dskbill.rep.bak
/bin/mv /LCC/opstmp/dskbill.rep.bak /LCC/opstmp/dskbill.rep
