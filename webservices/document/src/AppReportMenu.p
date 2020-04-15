/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table AppDocMenu NO-UNDO
  field MenuItem as character
  field IdItem as integer
  field ItemLevel as integer
  field ParentId as integer
  field RidMenu as integer
  field RidTypedoc as integer
  field ViewOnly as logical
  field IsAvailable as logical
  index i0 IdItem asc.

define input-output parameter ContextId as character.
define output parameter table for AppDocMenu.

define variable recid-prg as integer.
define variable pPath as character.
define variable ModulePath as character.
define variable idtypedoc as integer.
define variable v-only as logical.

/* Security + инициализация глобальных переменных */
{connect.i}
{oblik.i}

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
run webservices/main/src/InitGlobalVars.p (ContextId).
/* /Security + инициализация глобальных переменных */

find first system.progs where system.progs.rid-app = current-app and
  system.progs.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
if not available system.progs then RETURN.
recid-prg = system.progs.rid-prg.

define buffer menu2 for system.menu.
define buffer AppDocMenu2 for AppDocMenu.
define buffer AppDocMenu3 for AppDocMenu.
FOR EACH system.menu 
  WHERE system.menu.rid-prg = recid-prg NO-LOCK
  BY system.menu.number:     

  pPath = "".
  ModulePath = "".
  find first system.modules where system.modules.rid-module = system.menu.rid-module NO-LOCK NO-ERROR.
  if available system.modules then
  do:
    ModulePath = system.modules.sys-name.
    pPath = system.modules.sys-name.
    find first webdb.WebModules where
      webdb.WebModules.pModule = system.modules.sys-name NO-LOCK NO-ERROR.
    if available webdb.WebModules then
      ModulePath = webdb.WebModules.wModule.
    if system.modules.sys-name begins "./" then
    do:
      pPath = substring(system.modules.sys-name, 3).
      find first webdb.WebModules where
        webdb.WebModules.pModule = substring(system.modules.sys-name, 3) NO-LOCK NO-ERROR.
      if available webdb.WebModules then
        ModulePath = webdb.WebModules.wModule.
    end.
  end.
  if ModulePath <> webdb.Context.ContextType then NEXT.

  v-only = false.
  if read-only then v-only = true.
  if system.menu.v-only then v-only = true.
  if system.progs.v-only then v-only = true.

  create AppDocMenu.
  assign
    AppDocMenu.RidMenu = system.menu.rid-menu
    AppDocMenu.IdItem = system.menu.number
    AppDocMenu.ItemLevel = system.menu.nmb-level
    AppDocMenu.MenuItem = TRIM(system.menu.name)
    AppDocMenu.ViewOnly = v-only.

  idtypedoc = INTEGER ( system.menu.parameters ) NO-ERROR.
  AppDocMenu.MenuItem = AppDocMenu.MenuItem + " (" + system.menu.parameters + ")".

  AppDocMenu.RidTypedoc = 0.
  AppDocMenu.IsAvailable = false.
  Find First system.typedoc WHERE system.typedoc.id-typedoc = idtypedoc
    NO-LOCK NO-ERROR.
  IF AVAILABLE system.typedoc then
  do:
    AppDocMenu.RidTypedoc = system.typedoc.rid-typedoc.

    define variable RecID-limit as integer.
    RecID-limit = ?.
    FOR EACH system.limittypedoc-cathg WHERE system.limittypedoc-cathg.rid-typedoc = AppDocMenu.RidTypedoc AND
                                             system.limittypedoc-cathg.rid-cathg = currid-cathg AND
                                             system.limittypedoc-cathg.rid-ent = ? NO-LOCK:
      RecID-limit = system.limittypedoc-cathg.rid-limit.
    END.
    FOR EACH system.limittypedoc-cathg WHERE system.limittypedoc-cathg.rid-typedoc = AppDocMenu.RidTypedoc AND
                                             system.limittypedoc-cathg.rid-cathg = currid-cathg AND
                                             system.limittypedoc-cathg.rid-ent = rid-ent NO-LOCK:
      RecID-limit = system.limittypedoc-cathg.rid-limit.
    END.
    FIND FIRST system.limittypedoc-cathg WHERE
               system.limittypedoc-cathg.rid-limit = RecID-limit NO-LOCK NO-ERROR.
    IF AVAILABLE system.limittypedoc-cathg THEN
      AppDocMenu.IsAvailable = true.
  end.

  /* Создам группы отчетов */
  AppDocMenu.ParentId = 0.
  for each menu2 NO-LOCK where 
    menu2.rid-prg = system.menu.rid-prg and
    menu2.nmb-level < system.menu.nmb-level and 
    menu2.number < system.menu.number
    BY menu2.number DESC:

    AppDocMenu.ParentId = menu2.number.
    Find First AppDocMenu2 where AppDocMenu2.IdItem = AppDocMenu.ParentId NO-ERROR.
    if not available AppDocMenu2 then
    do:
      create AppDocMenu2.
      assign
      AppDocMenu2.RidMenu = menu2.rid-menu
      AppDocMenu2.IdItem = menu2.number
      AppDocMenu2.ItemLevel = menu2.nmb-level
      AppDocMenu2.MenuItem = TRIM(menu2.name)
      AppDocMenu2.ViewOnly = true.
      AppDocMenu2.RidTypedoc = 0.
      AppDocMenu2.IsAvailable = false.
    end.
    leave.
  end.
end.

/* Привяжем группы отчетов друг к другу */
for each AppDocMenu2:
  Find last AppDocMenu3 use-index i0 where AppDocMenu3.ItemLevel < AppDocMenu2.ItemLevel and
     AppDocMenu3.IdItem < AppDocMenu2.IdItem NO-ERROR.
  if available AppDocMenu3 then
  do:
    /* Если группа из другого поддерева то не привязываем */
    find first menu2 where menu2.rid-prg = recid-prg and
      menu2.number > AppDocMenu3.IdItem and menu2.number < AppDocMenu2.IdItem and
      menu2.nmb-level < AppDocMenu3.ItemLevel NO-LOCK NO-ERROR.
    if not available menu2 then
      AppDocMenu2.ParentId = AppDocMenu3.IdItem.
  end.
  else
    AppDocMenu2.ParentId = 0.
end.
