/* Copyright (C) Maxim A. Monin 2009-2010 */

Define Temp-Table MainMenu NO-UNDO
  field RidMenu as integer
  field ItemId as integer
  field ItemLevel as integer
  field ParentId as integer
  field ItemName as character
  field ItemHelp as character
  field ImagePath as character
  field ModulePath as character
  index i0 ItemId.
Define Temp-Table FastMenu NO-UNDO
  field RidMenu as integer
  field ItemName as character
  field ItemHelp as character
  field ImagePath as character
  field RunCount as integer
  field ModulePath as character
  index i0 RunCount desc.

define input-output parameter AppId as integer. /* CallBack Key */
define input-output parameter ContextId as character.
define input parameter RidEnt as integer.
define input parameter RidCathg as integer.
define input parameter RidApp as integer.
define output parameter table for MainMenu.
define output parameter table for FastMenu.

define variable RidContext as integer.
define variable recid-prg as integer.
define variable login as character.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
do:
  pause 1.
  return "".
end.
RidContext = webdb.Context.RidContext.
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

FOR EACH system.menu 
  WHERE system.menu.rid-prg = recid-prg NO-LOCK
  BY system.menu.number:     

  IF system.menu.final THEN  
  DO:
     IF TRIM(system.menu.name) = "-" THEN NEXT.
  end.

  define buffer MainMenu2 for MainMenu.
  create MainMenu.
  assign
    MainMenu.RidMenu = system.menu.rid-menu
    MainMenu.ItemId = system.menu.number
    MainMenu.ItemLevel = system.menu.nmb-level
    MainMenu.ItemName = TRIM(system.menu.name)
    MainMenu.ItemHelp = system.menu.help-string.
  IF TRIM(system.menu.parameters) <> "" then
    MainMenu.ItemName = MainMenu.ItemName + " (" + system.menu.parameters + ")".
  find first system.imagelist where system.imagelist.rid-image = system.menu.rid-image no-error.
  if available system.imagelist then
    MainMenu.ImagePath = system.imagelist.i-path.
  find first system.modules where system.modules.rid-module = system.menu.rid-module NO-LOCK NO-ERROR.
  if available system.modules then
  do:
    MainMenu.ModulePath = system.modules.sys-name.
    find first webdb.WebModules where
      webdb.WebModules.pModule = system.modules.sys-name NO-LOCK NO-ERROR.
    if available webdb.WebModules then
      MainMenu.ModulePath = webdb.WebModules.wModule.
    if system.modules.sys-name begins "./" then
    do:
      find first webdb.WebModules where
        webdb.WebModules.pModule = substring(system.modules.sys-name, 3) NO-LOCK NO-ERROR.
      if available webdb.WebModules then
        MainMenu.ModulePath = webdb.WebModules.wModule.
    end.
  end.
  if MainMenu.ImagePath = "" then
    MainMenu.ImagePath = "src/images/document.ico".

  Find last MainMenu2 where MainMenu2.ItemLevel = MainMenu.ItemLevel - 1 NO-ERROR.
  if available MainMenu2 then
    MainMenu.ParentId = MainMenu2.ItemId.
  else
    MainMenu.ParentId = 0.
END.

find first webdb.ContextData where webdb.ContextData.RidContext = RidContext and
  webdb.ContextData.ParamName = "uid" NO-LOCK NO-ERROR.
if available webdb.ContextData then
  login = webdb.ContextData.DataValue.

find first system.users WHERE system.users.sys-name = login NO-LOCK NO-ERROR.
if not available system.users then RETURN.

for each system.quicklaunch where system.quicklaunch.rid-user = system.users.rid-user NO-LOCK:
  find first MainMenu where MainMenu.RidMenu = system.quicklaunch.rid-menu no-lock no-error.
  if not available MainMenu then
    next. 
    
  create FastMenu.
  assign
    FastMenu.RidMenu = MainMenu.RidMenu
    FastMenu.ItemName = system.quicklaunch.item-title
    FastMenu.ItemHelp = MainMenu.ItemHelp
    FastMenu.RunCount = system.quicklaunch.item-number.
  find first system.imagelist where system.imagelist.rid-image = system.quicklaunch.rid-image no-error.
  if available system.imagelist then
    FastMenu.ImagePath = system.imagelist.i-path.
  else
  do:
    FastMenu.ImagePath = MainMenu.ImagePath.
  end.
  FastMenu.ModulePath = MainMenu.ModulePath.
  if FastMenu.ImagePath = "" then 
    FastMenu.ImagePath = "src/images/document.ico".
end.
