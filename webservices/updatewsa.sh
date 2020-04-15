#sh
wsaman -name $1 -appname Oblik_Document -disable
wsaman -name $1 -appname Oblik_Document -wsm Oblik_Document.wsm -update
wsaman -name $1 -appname Oblik_Document -enable
wsaman -name $1 -appname Oblik_DocEditor -disable
wsaman -name $1 -appname Oblik_DocEditor -wsm Oblik_DocEditor.wsm -update
wsaman -name $1 -appname Oblik_DocEditor -prop waitIfBusy -value 1 -setdefaults
#wsaman -name $1 -appname Oblik_DocEditor -prop staleO4GLObjectTimeout -value 300 -setdefaults
wsaman -name $1 -appname Oblik_DocEditor -enable
