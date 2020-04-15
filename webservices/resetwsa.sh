#sh
wsaman -name $1 -appname Oblik_Document -disable
wsaman -name $1 -appname Oblik_Document -enable
wsaman -name $1 -appname Oblik_DocEditor -disable
wsaman -name $1 -appname Oblik_DocEditor -enable
wsaman -name $1 -appname Oblik_Main -disable
wsaman -name $1 -appname Oblik_Main -enable
wsaman -name $1 -appname Oblik_DBView -disable
wsaman -name $1 -appname Oblik_DBView -enable
wsaman -name webdb -appname webdb -disable
wsaman -name webdb -appname webdb -enable
