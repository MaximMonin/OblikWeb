/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table STList NO-UNDO
  field STRid as integer
  field STName as character
  field ImagePath as character
  field Services as character
  index i0 STName asc.

define input-output parameter ContextId as character.
define input parameter table for STList.
define output parameter OutMessage as character initial "Error".

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

define variable num-errors as integer.
num-errors = 0.
for each webdb.ServiceType:
  find first STList where STList.STRid = webdb.ServiceType.RidServiceType NO-ERROR.
  if not available STList then
  do:
    delete webdb.ServiceType NO-ERROR.
    if ERROR-STATUS:ERROR then
      num-errors = num-errors + 1.
    NEXT.
  end.
  else do:
    assign
    webdb.ServiceType.TypeName = STList.STName
    webdb.ServiceType.ImagePath = STList.ImagePath NO-ERROR.
    if ERROR-STATUS:ERROR then
      num-errors = num-errors + 1.
    else do:
      release webdb.ServiceType NO-ERROR.
      if ERROR-STATUS:ERROR then
        num-errors = num-errors + 1.
    end.
    delete STList.
  end.
end.
for each STList:
  create webdb.ServiceType.
  assign
    webdb.ServiceType.TypeName = STList.STName
    webdb.ServiceType.ImagePath = STList.ImagePath NO-ERROR.
  if ERROR-STATUS:ERROR then
    num-errors = num-errors + 1.
  else do:
    release webdb.ServiceType NO-ERROR.
    if ERROR-STATUS:ERROR then
      num-errors = num-errors + 1.
  end.
  delete STList.
end.
if num-errors = 0 then OutMessage = "OK".
