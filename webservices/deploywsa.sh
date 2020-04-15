#sh
wsaman -name $1 -appname Oblik_Document -wsm Oblik_Document.wsm -deploy
wsaman -name $1 -appname Oblik_Document -enable
wsaman -name $1 -appname Oblik_DocEditor -wsm Oblik_DocEditor.wsm -deploy
wsaman -name $1 -appname Oblik_DocEditor -enable
wsaman -name $1 -appname Oblik_DBView   -wsm Oblik_DBView.wsm -deploy
wsaman -name $1 -appname Oblik_DBView -enable
wsaman -name $1 -appname Oblik_Main     -wsm Oblik_Main.wsm -deploy
wsaman -name $1 -appname Oblik_Main -enable
