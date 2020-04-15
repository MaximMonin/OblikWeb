/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter ContextData as character.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

define variable isAdmin as logical.
define variable readonly as logical.
isAdmin = False.
readonly = false.
if webdb.Context.ContextType = "UserAdmin" or 
   webdb.Context.ContextType = "SystemAdmin" then
do:
  isAdmin = true.
end.
for each webdb.ContextData of webdb.Context where 
  webdb.ContextData.ParamName = "read-only" NO-LOCK:
  if webdb.ContextData.DataValue = "true" then
  do:
    readonly = true.
    leave.
  end.
end.

define variable i as integer.
define variable item as character.
define variable var-name as character.
define variable var-value as character.
do i = 1 to num-entries(ContextData, "&"):
  item = entry (i, ContextData, "&").
  var-name = entry(1, item, "=").
  if num-entries(item, "=") > 1 then
    var-value = entry(2, item, "=").
  else
    var-value = "".

  if var-name = "read-only" and var-value <> "true" then
  do:
    if isAdmin and readonly then
    do:
      pause 1.
      run webservices/webdb/src/SecurityError.p (INPUT ContextId).
      RETURN.
    end.
    if readonly then NEXT.
  end.

  find first webdb.ContextData of webdb.Context where
    webdb.ContextData.ParamName = var-name NO-ERROR.
  if not available webdb.ContextData then
  do:
    create webdb.ContextData.
    assign
      webdb.ContextData.RidContext = webdb.Context.RidContext
      webdb.ContextData.ParamName = var-name.
  end.
  webdb.ContextData.DataValue = var-value.
end.
