/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter ServiceId as integer.
define input parameter ContextData as character.

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

find first webdb.UserService where 
  webdb.UserService.RidUserService = ServiceId NO-LOCK NO-ERROR.
if not available UserService then RETURN.

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
  find first webdb.UserServiceParams of webdb.UserService where
    webdb.UserServiceParams.ParamName = var-name NO-ERROR.
  if not available webdb.UserServiceParams then
  do:
    if var-value = "" then NEXT.
    create webdb.UserServiceParams.
    assign
      webdb.UserServiceParams.RidUserService = webdb.UserService.RidUserService
      webdb.UserServiceParams.ParamName = var-name.
  end.
  if var-value = "" then
    delete webdb.UserServiceParams.
  else
    webdb.UserServiceParams.ParamValue = var-value.
end.
