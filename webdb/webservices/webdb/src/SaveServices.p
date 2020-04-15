/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table ServiceList NO-UNDO
  field ServiceRid as integer
  field ServiceName as character
  field STRid as integer
  field DBRid as integer
  field EasyLogin as logical
  index i0 ServiceName asc.

define input-output parameter ContextId as character.
define input parameter table for ServiceList.
define output parameter OutMessage as character initial "Error".

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
  RETURN.

define variable isAdmin as logical.
isAdmin = False.
if webdb.Context.ContextType = "SystemAdmin" then
  isAdmin = true.
for each webdb.ContextData of webdb.Context where 
  webdb.ContextData.ParamName = "read-only" NO-LOCK:
  if webdb.ContextData.DataValue = "true" then
  do:
    pause 1.
    run webservices/webdb/src/SecurityError.p (INPUT ContextId).
    RETURN.
  end.
end.
if (not isAdmin) then
do:
  pause 1.
  run webservices/webdb/src/SecurityError.p (INPUT ContextId).
  RETURN.
end.

define variable num-errors as integer no-undo.
num-errors = 0.

for each ServiceList where ServiceList.ServiceRid = 0:
  DO TRANSACTION ON ERROR UNDO, LEAVE:
    create webdb.Service.
    assign
    webdb.Service.RidServiceType = ServiceList.STRid
    webdb.Service.RidDb = ServiceList.DBRid
    webdb.Service.ServiceName = ServiceList.ServiceName
    webdb.Service.EasyLogin = ServiceList.EasyLogin
    NO-ERROR.
    if ERROR-STATUS:ERROR then
      num-errors = num-errors + 1.
    else do:
      release webdb.Service NO-ERROR.
      if ERROR-STATUS:ERROR then
        num-errors = num-errors + 1.
    end.
    delete ServiceList.
  END.
end.

for each ServiceList,
  each webdb.Service where webdb.Service.RidService = ServiceList.ServiceRid:
  DO TRANSACTION ON ERROR UNDO, LEAVE:
    assign
    webdb.Service.RidServiceType = ServiceList.STRid
    webdb.Service.RidDb = ServiceList.DBRid
    webdb.Service.ServiceName = ServiceList.ServiceName
    webdb.Service.EasyLogin = ServiceList.EasyLogin
    NO-ERROR.
    if ERROR-STATUS:ERROR then
      num-errors = num-errors + 1.
    else do:
      release webdb.Service NO-ERROR.
      if ERROR-STATUS:ERROR then
        num-errors = num-errors + 1.
    end.
    delete ServiceList.
  END.
end.
if num-errors = 0 then OutMessage = "OK".
