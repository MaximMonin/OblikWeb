/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter ServiceRid as integer.
define output parameter OutMessage as character initial "Error".

define variable state as logical.

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

define variable isAdmin as logical.
isAdmin = False.
if webdb.Context.ContextType = "SystemAdmin" then
  isAdmin = true.
if isAdmin = false then
do:
  pause 1.
  run webservices/webdb/src/SecurityError.p (INPUT ContextId).
  RETURN.
end.

for each webdb.ContextData of webdb.Context where 
  webdb.ContextData.ParamName = "read-only" NO-LOCK:
  if webdb.ContextData.DataValue = "true" then
  do:
    pause 1.
    run webservices/webdb/src/SecurityError.p (INPUT ContextId).
    RETURN.
  end.
end.

find first webdb.UserService where 
  webdb.UserService.RidService = ServiceRid NO-LOCK NO-ERROR.
if available webdb.UserService then
do:
  OutMessage = "CannotDelete".
  RETURN.
end.

find first webdb.Service where webdb.Service.RidService = ServiceRid EXCLUSIVE-LOCK NO-ERROR.
delete webdb.Service.
OutMessage = "OK".
