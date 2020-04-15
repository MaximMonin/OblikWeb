/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define output parameter ViewOnly as logical initial false.
define output parameter MenuParams as character initial "".
define output parameter ModuleName as character initial "".
define output parameter RidMenu as integer initial ?.
define output parameter EndPoint as character initial "".
define output parameter EndPoint2 as character initial "".
define output parameter lang as character initial "ru_RU".

define variable var-name as character.
define variable var-value as character.
define variable RidContext as integer.

define variable RidSession as integer.
define variable NewContext as character.

if ContextId = "demo" or ContextId = "demoeng" then
do:
  if ContextId = "demoeng" then
    find first webdb.Context where webdb.Context.RidContext = 131 NO-LOCK NO-ERROR.
  else
    find first webdb.Context where webdb.Context.RidContext = 9 NO-LOCK NO-ERROR.
  RidContext = webdb.Context.RidContext.
  RidSession = webdb.Context.RidSession.
  ContextId = webdb.Context.ContextKey.

  create webdb.Context.
  assign
  webdb.Context.RidSession = RidSession
  webdb.Context.RidContextUp = RidContext
  webdb.Context.ContextType = "admin/DBView.swf"
  webdb.Context.PublicKey = false.

  NewContext = webdb.Context.ContextKey.

  run webservices/webdb/src/CopyContext.p (ContextId, NewContext).
  ContextId = NewContext.
  RidContext = webdb.Context.RidContext.
  RidSession = webdb.Context.RidSession.
end.
else do:

  find first webdb.Context where webdb.Context.ContextKey = ContextId NO-ERROR.
  if not available webdb.Context then 
  do:
    pause 1.
    RETURN.
  end.
  RidContext = webdb.Context.RidContext.

  if webdb.Context.PublicKey then
    webdb.Context.PublicKey = false.
  run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, yes).
  if return-value <> "" then
  do:
    pause 1.
    return RETURN-VALUE.
  end.


end.

for each webdb.ContextData where webdb.ContextData.RidContext = RidContext NO-LOCK:
  var-name = webdb.ContextData.ParamName.
  var-value = webdb.ContextData.DataValue.
  if var-name = "v-only" then
    ViewOnly = LOGICAL(var-value).
  if var-name = "read-only" then
    ViewOnly = LOGICAL(var-value).
  if var-name = "ModuleParams" then
    MenuParams = var-value.
  if var-name = "ModuleName" then
    ModuleName = var-value.
  if var-name = "rid-menu" then
    RidMenu = INTEGER(var-value).
  if var-name = "WebEndPoint" then
    EndPoint = var-value.
  if var-name = "WebEndPoint2" then
    EndPoint2 = var-value.
  if var-name = "lang" then
    lang = var-value.
end.
