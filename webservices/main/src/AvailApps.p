/* Copyright (C) Maxim A. Monin 2009-2010 */

Define Temp-Table AvailEnt NO-UNDO
  field EntName as character
  field rident as integer
  index i0 EntName.
Define Temp-Table AvailCathg NO-UNDO
  field CathgName as character
  field ridcathg as integer
  index i0 CathgName.
Define Temp-Table AvailApp NO-UNDO
  field AppName as character
  field ridcathg as integer
  field ridapp as integer
  index i0 is primary ridcathg AppName
  index i1 ridcathg.

define input-output parameter AppId as integer. /* CallBack key */
define input-output parameter ContextId as character.
define input parameter ServiceId as integer.
define output parameter UserName as character initial "".
define output parameter Db_Name as character initial "".
define output parameter DefEnt as integer initial ?.
define output parameter DefCathg as integer initial ?.
define output parameter DefApp as integer initial ?.
define output parameter table for AvailEnt.
define output parameter table for AvailCathg.
define output parameter table for AvailApp.

define variable RidContext as integer.
define variable ent-count as integer.
define variable checkdef as logical.
define variable checkcount as integer.
define variable login as character.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
do:
  pause 1.
  return "".
end.
RidContext = webdb.Context.RidContext.
find first webdb.UserService where 
  webdb.UserService.RidUserService = ServiceId NO-LOCK NO-ERROR.
if not available UserService then
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

find first webdb.ContextData where webdb.ContextData.RidContext = RidContext and
  webdb.ContextData.ParamName = "uid" NO-LOCK NO-ERROR.
if available webdb.ContextData then
  login = webdb.ContextData.DataValue.

find first system.users WHERE system.users.sys-name = login NO-LOCK NO-ERROR.
if available system.users then
do:
  find first system.employeers of system.users NO-LOCK NO-ERROR.
  if available system.employeers then UserName = system.employeers.name-emp.
  else UserName = system.users.name.
end.
else RETURN.

find first system.config NO-LOCK NO-ERROR.
if available system.config then
  Db_Name = system.config.client-name.

ent-count = 0.
for each ent NO-LOCK:
  ent-count = ent-count + 1.
  if ent-count > 1 then leave.
end.
if ent-count > 1 then
do:
  find first system.user-ent of system.users NO-LOCK NO-ERROR.
  if not available system.user-ent then
    RETURN.
  find first webdb.UserServiceParams of webdb.UserService where
     webdb.UserServiceParams.ParamName = "rid-ent" NO-LOCK NO-ERROR.
  if available webdb.UserServiceParams then
    DefEnt = INTEGER(webdb.UserServiceParams.ParamValue).

  checkdef = false.
  checkcount = 0.
  for each system.user-ent of system.users NO-LOCK,
      each ent of system.user-ent NO-LOCK:
    create AvailEnt.
    assign
      AvailEnt.EntName = ent.name-ent
      AvailEnt.rident = ent.rid-ent.
    if DefEnt = AvailEnt.rident then
      checkdef = true.
    checkcount = checkcount + 1.
  end.
  if checkdef = false then
    DefEnt = ?.
  if checkcount = 1 then
  do:
    find first AvailEnt.
    DefEnt = AvailEnt.rident.
  end.
end.

find first webdb.UserServiceParams of webdb.UserService where
   webdb.UserServiceParams.ParamName = "rid-cathg" NO-LOCK NO-ERROR.
if available webdb.UserServiceParams then
  DefCathg = INTEGER(webdb.UserServiceParams.ParamValue).

checkdef = false.
checkcount = 0.
FOR EACH system.ctg-user NO-LOCK WHERE
         system.ctg-user.rid-user = system.users.rid-user,  
    EACH system.cathg OF system.ctg-user NO-LOCK:
  create AvailCathg.
  assign
    AvailCathg.CathgName = system.cathg.name
    AvailCathg.ridcathg = system.cathg.rid-cathg.

  if DefCathg = AvailCathg.ridcathg then
    checkdef = true.
  checkcount = checkcount + 1.
END.
if checkdef = false then
  DefCathg = ?.
if checkcount = 1 then
do:
  find first AvailCathg.
  DefCathg = AvailCathg.ridcathg.
end.

find first webdb.UserServiceParams of webdb.UserService where
   webdb.UserServiceParams.ParamName = "rid-app" NO-LOCK NO-ERROR.
if available webdb.UserServiceParams then
  DefApp = INTEGER(webdb.UserServiceParams.ParamValue).

checkdef = false.
checkcount = 0.
FOR EACH AvailCathg:
  find first system.cathg where 
    system.cathg.rid-cathg = AvailCathg.ridcathg NO-LOCK NO-ERROR.
  if not available system.cathg then NEXT.

  FOR EACH system.progs NO-LOCK WHERE
      system.progs.rid-cathg = AvailCathg.ridcathg,
      EACH system.applicat OF system.progs NO-LOCK WHERE
           system.applicat.prior <= system.cathg.prior:
    create AvailApp.
    assign
      AvailApp.AppName = system.applicat.name
      AvailApp.ridcathg = AvailCathg.ridcathg
      AvailApp.ridapp = system.applicat.rid-app.
    if DefCathg = AvailCathg.ridcathg and DefApp = AvailApp.ridapp then
      checkdef = true.
    if DefCathg = AvailCathg.ridcathg then
      checkcount = checkcount + 1.
  END.
END.
if checkdef = false then
  DefApp = ?.
if checkcount = 1 then
do:
  find first AvailApp where AvailApp.ridcathg = DefCathg.
  DefApp = AvailApp.ridapp.
end.
