/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define output parameter AppName as character initial "".
define output parameter Db_Name as character initial "".
define output parameter UserName as character initial "".

/* Security + инициализация глобальных переменных */
{connect.i}
{oblik.i}

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
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
run webservices/main/src/InitGlobalVars.p (ContextId).
/* /Security + инициализация глобальных переменных */

find first system.applicat where system.applicat.rid-app = current-app NO-LOCK NO-ERROR.
if available system.applicat then
  AppName = system.applicat.name.

UserName = uid + " ".
find first system.users WHERE system.users.sys-name = uid NO-LOCK NO-ERROR.
if available system.users then
do:
  find first system.employeers of system.users NO-LOCK NO-ERROR.
  if available system.employeers then UserName = UserName + system.employeers.name-emp.
  else UserName = UserName + system.users.name.
end.

find first system.config NO-LOCK NO-ERROR.
if available system.config then
  Db_Name = system.config.client-name.

define variable ent-count as integer.
ent-count = 0.
for each system.ent NO-LOCK:
  ent-count = ent-count + 1.
  if ent-count > 1 then leave.
end.
if ent-count > 1 then
do:
  find first system.ent where system.ent.rid-ent = rid-ent NO-LOCK NO-ERROR.
  if available system.ent then
    Db_Name = Db_Name + " (" + system.ent.name-ent + ")".
end.  
