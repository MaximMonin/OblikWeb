/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table ContextParams NO-UNDO
  field ParamName as character
  field ParamValue as character
  index i0 ParamName.

define input-output parameter ContextId as character.
define input parameter ContextRid as integer.
define output parameter table for ContextParams.

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

for each webdb.ContextData where webdb.ContextData.RidContext = ContextRid NO-LOCK:
    create ContextParams.
    assign
      ContextParams.ParamName = webdb.ContextData.ParamName
      ContextParams.ParamValue = webdb.ContextData.DataValue.
end.
