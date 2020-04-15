/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter AppId as integer. /* CallBack Key */
define input-output parameter ContextId as character.
define input-output parameter Module as character.
define input parameter RidEnt as integer.
define input parameter RidCathg as integer.
define input parameter RidApp as integer.
define input parameter RidMenu as integer.
define output parameter ModuleContextId as character initial "".

define variable RidContext as integer.
define variable RidSession as integer.
define variable recid-prg as integer.
define variable cs as character.
define variable read-only as logical initial false.
define variable v-only as logical.
define variable login as character.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
do:
  pause 1.
  return "".
end.
RidContext = webdb.Context.RidContext.
RidSession = webdb.Context.RidSession.
run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
do:
  pause 1.
  return RETURN-VALUE.
end.

find first system.progs where system.progs.rid-app = RidApp and
  system.progs.rid-cathg = RidCathg NO-LOCK NO-ERROR.
if not available system.progs then RETURN.
recid-prg = system.progs.rid-prg.
find first system.menu where system.menu.rid-menu = RidMenu NO-LOCK NO-ERROR.
if not available system.menu then RETURN.

create webdb.Context.
assign
webdb.Context.RidSession = RidSession
webdb.Context.RidContextUp = RidContext
webdb.Context.ContextType = Module
webdb.Context.PublicKey = yes.

ModuleContextId = webdb.Context.ContextKey.

run webservices/webdb/src/CopyContext.p (ContextId, ModuleContextId).

cs = "rid-menu=" + string(RidMenu).
if RidEnt <> 0 then
  cs = cs + "&rid-ent=" + string(RidEnt).
if RidCathg <> 0 then
  cs = cs + "&currid-cathg=" + string(RidCathg).
if RidApp <> 0 then
  cs = cs + "&current-app=" + string(RidApp).
run webservices/webdb/src/SaveContext.p (INPUT-OUTPUT ModuleContextId, cs).

v-only = false.

find first webdb.ContextData where webdb.ContextData.RidContext = RidContext and
  webdb.ContextData.ParamName = "uid" NO-LOCK NO-ERROR.
if available webdb.ContextData then
  login = webdb.ContextData.DataValue.
find first webdb.ContextData where webdb.ContextData.RidContext = RidContext and
  webdb.ContextData.ParamName = "read-only" NO-LOCK NO-ERROR.
if available webdb.ContextData then
do:
  read-only = LOGICAL(webdb.ContextData.DataValue).
  v-only = LOGICAL(webdb.ContextData.DataValue).
end.

if system.progs.v-only then
  v-only = true.

if system.menu.v-only then
  v-only = true.
cs = "v-only=" + string(v-only).
if system.menu.parameters <> "" then
  cs = cs + "&ModuleParams=" + system.menu.parameters.
find first system.modules where system.modules.rid-module = system.menu.rid-module NO-LOCK NO-ERROR.
if available system.modules then
  cs = cs + "&ModuleName=" + system.modules.sys-name.
run webservices/webdb/src/SaveContext.p (INPUT-OUTPUT ModuleContextId, cs).

if not read-only then
do:                
  find first system.users WHERE system.users.sys-name = login NO-LOCK NO-ERROR.
  if available system.users then
  do:
    find first system.quicklaunch of system.users where
      system.quicklaunch.rid-menu = RidMenu NO-ERROR.
    if not available system.quicklaunch then
    do:
      create system.quicklaunch.
      assign
        system.quicklaunch.rid-user = system.users.rid-user
        system.quicklaunch.rid-menu = RidMenu
        system.quicklaunch.item-title = system.menu.name.
      if system.menu.parameters <> "" then
        system.quicklaunch.item-title = system.quicklaunch.item-title +
          " (" + system.menu.parameters + ")".
    end.
    system.quicklaunch.item-number = system.quicklaunch.item-number + 1.
  end.
end.
