/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table DBList NO-UNDO
  field DBRid as integer
  field DBId as integer
  field DB_Name as character
  field WSPath as character
  field WSPath2 as character
  field ImagePath as character
  field Services as character
  index i0 DBId asc.

define input-output parameter ContextId as character.
define output parameter table for DBList.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

find first webdb.UserSession of webdb.Context NO-LOCK NO-ERROR.
if not available webdb.UserSession then RETURN.

find first webdb.WebUsers where webdb.WebUsers.RidUser = webdb.UserSession.RidUser NO-LOCK NO-ERROR.
if not available webdb.WebUsers then RETURN.

run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
  RETURN.

define variable isAdmin as logical.
isAdmin = False.
if webdb.Context.ContextType = "SystemAdmin" then
  isAdmin = true.
if (not isAdmin) then
do:
  pause 1.
  RETURN.
end.

for each webdb.Db NO-LOCK:
  create DBList.
  assign
  DBList.DBRid = webdb.Db.RidDb
  DBList.DBId  = webdb.Db.idDb
  DBList.DB_Name = webdb.Db.Db_Name
  DBList.WSPath = webdb.Db.WebServPath
  DBList.WSPath2 = webdb.Db.WebServPath2
  DBList.ImagePath = webdb.Db.ImagePath.
  for each webdb.Service of webdb.Db NO-LOCK:
    if DBList.Services = "" then DBList.Services = webdb.Service.ServiceName.
    else DBList.Services = DBList.Services + "," + webdb.Service.ServiceName.
  end.
end.
