/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table ContextVars NO-UNDO
  field VarName as character
  field VarValue as character
  index i0 VarName.

define input-output parameter ContextId as character.
define output parameter table for ContextVars.

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

for each webdb.ContextData of webdb.Context NO-LOCK:
  create ContextVars.
  assign 
    ContextVars.VarName  = webdb.ContextData.ParamName
    ContextVars.VarValue = webdb.ContextData.DataValue.
end.
