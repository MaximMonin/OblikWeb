/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table ServiceList NO-UNDO
  field ServiceRid as integer
  field ServiceName as character
  field STRid as integer
  field ServiceType as character
  field DBRid as integer
  field DB as character
  field EasyLogin as logical
  field NumUsers as integer
  index i0 ServiceName asc.

define input-output parameter ContextId as character.
define input parameter DBRid as integer.
define input parameter STRid as integer.
define output parameter table for ServiceList.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

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


for each webdb.Service NO-LOCK,
    each webdb.Db of webdb.Service NO-LOCK,
    each webdb.ServiceType of webdb.Service NO-LOCK:

  if DBRid <> 0 and webdb.Service.RidDB <> DBRid then NEXT.
  if STRid <> 0 and webdb.Service.RidServiceType <> STRid then NEXT.

  create ServiceList.
  assign
  ServiceList.ServiceRid = webdb.Service.RidService
  ServiceList.ServiceName = webdb.Service.ServiceName
  ServiceList.STRid = webdb.ServiceType.RidServiceType
  ServiceList.ServiceType = webdb.ServiceType.TypeName
  ServiceList.DBRid = webdb.Service.RidDB
  ServiceList.DB = webdb.DB.DB_Name + " (" + webdb.DB.WebServPath + ")".
  ServiceList.EasyLogin = webdb.Service.EasyLogin.

  ServiceList.NumUsers = 0.
  for each webdb.UserService where
    webdb.UserService.RidService = webdb.Service.RidService NO-LOCK:
    ServiceList.NumUsers = ServiceList.NumUsers + 1.
  end.
end.
