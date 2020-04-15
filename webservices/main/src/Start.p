/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter ServiceId as integer.
define input parameter login as character.
define input parameter pwd as character.
define output parameter OblikContextId as character initial "".

define variable state as logical.
define variable RidContext as integer.
define variable RidSession as integer.

/* ������� ����প� ��᫥ ��㤠筮�� ������ �� ᥪ㭤�. */
/* ��� ��堭��� ���ᯠ�� */

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
do:
  pause 1.
  return "".
end.
RidContext = webdb.Context.RidContext.
RidSession = webdb.Context.RidSession.

/* �஢�ਬ ���� �� � ���짮��⥫� �ࠢ� �� ����� �ࢨ� */
Find First webdb.UserSession where
  webdb.UserSession.RidSession = RidSession NO-LOCK NO-ERROR.
if not available webdb.UserSession then
do:
  pause 1.
  return "".
end.
find first webdb.UserService where 
  webdb.UserService.RidUserService = ServiceId NO-LOCK NO-ERROR.
if not available UserService then
do:
  pause 1.
  return "".
end.
if webdb.UserSession.RidUser <> webdb.UserService.RidUser then
do:
  pause 1.
  return "".
end.

run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
do:
  pause 1.
  return RETURN-VALUE.
end.

find first system.users WHERE system.users.sys-name = login NO-LOCK NO-ERROR.
if not available system.users then
do:
  pause 1.
  return "".
end.

if system.users.sh = false then
do:
  pause 1.
  return "Banned".
end.
if system.users.end-date <> ? then
do:
  if system.users.end-date < TODAY then
  do:
    pause 1.
    return "Banned".
  end.
end.

/*
   �஢�ઠ ��饭���� ������ � �� ��� �஢�ન ��஫� 
   �ࠡ��뢠�� ��᫥ ��ࢮ�� 㤠筮�� ����᪠ �ࢨ� � 
   ��⠭��������� ������쭮�� 䫠�� "���⮩ �����" �� �㦡�.
   �� �� ᬥ�� ����� ���짮��⥫� ��஫� �஢��塞 ᭮��.
*/
define variable EasyLogin as logical.
EasyLogin = false.
for each webdb.Service where webdb.Service.RidService = webdb.UserService.RidService NO-LOCK:
  if webdb.Service.EasyLogin = true and webdb.UserService.CountStarted > 0 then
  do:
    find first webdb.UserServiceParams of webdb.UserService where
      webdb.UserServiceParams.ParamName = "uid" NO-LOCK NO-ERROR.
    if available webdb.UserServiceParams then
    do:
      if webdb.UserServiceParams.ParamValue = login then
        EasyLogin = true.
    end.
  end.
end.

define variable read-only as logical initial no.
define variable oracledb as logical initial no.
define variable RootOfAnobject as integer.
define variable i as integer.

if webdb.UserService.ReadOnly then read-only = true.
repeat i = 1 to num-dbs:
  if dbrestrictions(i) = "READ-ONLY" then read-only = yes.
  if DBTYPE(i) = "ORACLE" then oracledb = true.
end.

if not EasyLogin then
do:
  if oracledb then
    state = (ENCODE(pwd) = system.users.passwd).
  else
    state = SETUSERID ( login, pwd, "system" ).
end.
else state = true.
if state = false then
do:
  pause 1.
  return "".
end.

create webdb.Context.
assign
webdb.Context.RidSession = RidSession
webdb.Context.RidContextUp = RidContext.
webdb.Context.ContextType = webdb.UserService.ServiceName.

OblikContextId = webdb.Context.ContextKey.

find first webdb.UserService where
  webdb.UserService.RidUserService = ServiceId EXCLUSIVE-LOCK NO-ERROR NO-WAIT.
if available webdb.UserService then
do:
  webdb.UserService.CountStarted = webdb.UserService.CountStarted + 1.

  /* �᫨ �� �� �� �������� ����� �室� � ��, ���������� ��� ��⮬���᪨ */
  find first webdb.UserServiceParams of webdb.UserService where
    webdb.UserServiceParams.ParamName = "uid" NO-LOCK NO-ERROR.
  if not available webdb.UserServiceParams then
  do:
    create webdb.UserServiceParams.
    assign
      webdb.UserServiceParams.RidUserService = webdb.UserService.RidUserService
      webdb.UserServiceParams.ParamName = "uid"
      webdb.UserServiceParams.ParamValue = login.
  end.
end.

/* ������㥬 ���⥪�� ������饣� ��ꥪ� � ����襬 �窨 ����㯠 */
run webservices/webdb/src/CopyContext.p (ContextId, OblikContextId).
for each webdb.Service where webdb.Service.RidService = webdb.UserService.RidService NO-LOCK,
    each webdb.Db of webdb.Service NO-LOCK:

  run webservices/webdb/src/SaveContext.p (INPUT-OUTPUT OblikContextId, 
   "webEndPoint=" + webdb.Db.WebServPath + "&" +
   "webEndPoint2=" + webdb.Db.WebServPath2).
end.

/* ���樠�����㥬 �������� ��६���� ����� */
define variable cs as character.
cs = "uid=" + login.
if oracledb then
  cs = cs + "&oracledb=true".
if read-only then
  cs = cs + "&read-only=true".

find first system.anobject 
  where system.anobject.rid-anobject = system.anobject.rid-upobject NO-LOCK NO-ERROR. 
if not available system.anobject then 
do:
  create anobject.
  anobject.id-anobject = 0.
  anobject.name-anobject = "��� ���������".
  anobject.rid-upobject = anobject.rid-anobject.
  RootOfAnobject = system.anobject.rid-anobject.
end.
else do:
  RootOfAnobject = system.anobject.rid-anobject.
end.
cs = cs + "&RootOfAnobject=" + STRING(RootOfAnobject).
run webservices/webdb/src/SaveContext.p (INPUT-OUTPUT OblikContextId, cs).

/*
  /* ����襬 ᮡ�⨥ �室� � ����� � ��⥬�� ��ୠ� �㤨�. */
  define variable fio as character.
  define variable my-comp as character.
  define variable my-ip as character.
  define variable event-detail as character.
  find first system.employeers of system.users NO-LOCK NO-ERROR.
  if available system.employeers then fio = system.employeers.name-emp.
  else fio = system.users.name.
  /* � ��ୠ� �㤨� ������� � ⮩ ����஢��, � ���ன ������ ��. 
     ��� Windows �㦭� �८�ࠧ������.
  */
  fio = codepage-convert ( fio, Db-codepage  ).
  run src/system/auditconn.p ( output my-ip, OUTPUT my-comp ).
  event-detail = my-ip + " (" + my-comp + ")".
  AUDIT-CONTROL:Log-Audit-Event ( 32100, fio, event-detail ).

  /* ����� ࠡ��� ��⥬� �㤨� */
*/

return "OK".
