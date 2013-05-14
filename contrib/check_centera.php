<?php
#
# Plugin: check_centera
# Author: Rene Koch <r.koch@ovido.at>
# Date: 2013/05/14
#

$opt[1] = "--vertical-label \"System Buffer \" -l 0 --title \"System buffer free on $hostname\" --slope-mode -u 100 -N";
$def[1] =  "DEF:var1=$RRDFILE[1]:$DS[1]:AVERAGE " ;
$def[1] .= "LINE1:var1#F30000:\"System Buffer free\" " ;
$def[1] .= "GPRINT:var1:LAST:\"%3.4lg%s$UNIT[1] LAST \" ";
$def[1] .= "GPRINT:var1:MAX:\"%3.4lg%s$UNIT[1] MAX \" ";
$def[1] .= "GPRINT:var1:AVERAGE:\"%3.4lg%s$UNIT[1] AVERAGE \" "

?>