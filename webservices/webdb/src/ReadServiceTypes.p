/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table STList NO-UNDO
  field STRid as integer
  field STName as character
  field ImagePath as character
  field Services as character
  index i0 STName asc.

define input-output parameter ContextId as character.
define output parameter table for STList.

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
/*
if (not isAdmin) then
do:
  pause 1.
  RETURN.
end.
*/

for each webdb.ServiceType NO-LOCK:
  create STList.
  assign
  STList.STRid = webdb.ServiceType.RidServiceType
  STList.STName = webdb.ServiceType.TypeName
  STList.ImagePath = webdb.ServiceType.ImagePath.
  for each webdb.Service of webdb.ServiceType NO-LOCK:
    if STList.Services = "" then STList.Services = webdb.Service.ServiceName.
    else STList.Services = STList.Services + "," + webdb.Service.ServiceName.
  end.
end.
