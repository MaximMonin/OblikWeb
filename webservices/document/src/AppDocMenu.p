/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table AppDocMenu NO-UNDO
  field MenuItem as character
  field IdItem as integer
  field RidMenu as integer
  field RidApp as integer
  field RidTypedoc as integer
  field PutOff as logical
  field Scope as character
  field ScopeList as character
  field DateFrom as date
  field DateTo as date
  field ViewOnly as logical
  index i0 IdItem asc.

define input-output parameter ContextId as character.
define output parameter table for AppDocMenu.

define variable recid-prg as integer.
define variable pPath as character.
define variable ModulePath as character.
define variable idtypedoc as integer.
define variable cur-scope as integer.
define variable max-scope as integer.
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
  if ModulePath <> "kernel/document.swf" then NEXT.

  v-only = false.
  if read-only then v-only = true.
  if system.menu.v-only then v-only = true.
  if system.progs.v-only then v-only = true.

  create AppDocMenu.
  assign
    AppDocMenu.RidMenu = system.menu.rid-menu
    AppDocMenu.IdItem = system.menu.number
    AppDocMenu.MenuItem = TRIM(system.menu.name)
    AppDocMenu.ViewOnly = v-only.

  if index (pPath, "of") > 0 then
    AppDocMenu.PutOff = true.
  else
    AppDocMenu.PutOff = false.

  AppDocMenu.RidApp = current-app.
  if index (pPath, "on4.p") > 0 or index (pPath, "off4.p") > 0 then
    AppDocMenu.RidApp = ?.

  if index (pPath, "on5.p") > 0 or index (pPath, "off5.p") > 0 or
     index (pPath, "on4.p") > 0 or index (pPath, "off4.p") > 0 then
  do:
    AppDocMenu.RidTypedoc = ?.
    cur-scope = 2.
    max-scope = 2.
    RUN src/kernel/gotchper.p ( OUTPUT AppDocMenu.DateFrom, OUTPUT AppDocMenu.DateTo ). 
  end.
  else do:
    idtypedoc = INTEGER ( system.menu.parameters ) NO-ERROR.
    AppDocMenu.MenuItem = AppDocMenu.MenuItem + " (" + system.menu.parameters + ")".

    AppDocMenu.RidTypedoc = 0.
    Find First system.typedoc WHERE system.typedoc.id-typedoc = idtypedoc
      NO-LOCK NO-ERROR.
    IF AVAILABLE system.typedoc then
    do:
      AppDocMenu.RidTypedoc = system.typedoc.rid-typedoc.
      find first system.groupdoc of system.typedoc NO-LOCK NO-ERROR.
      if available system.groupdoc then
      do:
        find first system.applicat of system.groupdoc NO-LOCK NO-ERROR.
        if available system.applicat then
          AppDocMenu.RidApp = system.groupdoc.rid-app.
      end.
      RUN src/kernel/vperiod.p( system.typedoc.rid-typedoc, 
        OUTPUT cur-scope, OUTPUT AppDocMenu.DateFrom, OUTPUT AppDocMenu.DateTo ). 
      RUN src/kernel/setusdt.p ( system.typedoc.rid-typedoc, 
        INPUT-OUTPUT cur-scope, INPUT-OUTPUT AppDocMenu.DateFrom, INPUT-OUTPUT AppDocMenu.DateTo ).

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
      IF NOT AVAILABLE system.limittypedoc-cathg THEN
        max-scope = -1.
      else
        max-scope = system.limittypedoc-cathg.vis.
    end.
  end.

  Find First system.doc-scope WHERE
    system.doc-scope.nmb-scope = cur-scope NO-LOCK NO-ERROR.
  IF AVAILABLE system.doc-scope then
/*     AppDocMenu.Scope = system.doc-scope.name-scope. */ 
     AppDocMenu.Scope = "SCOPE" + STRING(system.doc-scope.nmb-scope). 
 
  AppDocMenu.ScopeList = "".
  FOR EACH system.doc-scope WHERE 
    system.doc-scope.nmb-scope <= max-scope NO-LOCK :
    IF max-scope = 3 THEN
      IF system.doc-scope.nmb-scope = 1 OR system.doc-scope.nmb-scope = 2 THEN
        NEXT.
    if AppDocMenu.ScopeList = "" then AppDocMenu.ScopeList = STRING(system.doc-scope.nmb-scope).
    else AppDocMenu.ScopeList = AppDocMenu.ScopeList + "," + STRING(system.doc-scope.nmb-scope).
/*
    if AppDocMenu.ScopeList = "" then AppDocMenu.ScopeList = system.doc-scope.name-scope.
    else AppDocMenu.ScopeList = AppDocMenu.ScopeList + "," + system.doc-scope.name-scope.
*/
  end.
end.
