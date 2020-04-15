/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter ServiceId as integer.
define output parameter ModuleContextId as character initial "".
define output parameter Module as character initial "".

define variable state as logical.
define variable RidContext as integer.
define variable RidSession as integer.

/* Сделаем задержку после неудачного логина на секунду. */
/* Как механизм антиспама */

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
do:
  pause 1.
  return "".
end.
RidContext = webdb.Context.RidContext.
RidSession = webdb.Context.RidSession.

/* Проверим есть ли у пользователя права на запуск сервиса */
Find First webdb.UserSession where
  webdb.UserSession.RidSession = RidSession NO-LOCK NO-ERROR.
if not available webdb.UserSession then
do:
  pause 1.
  return "".
end.

state = false.
for each webdb.UserService NO-LOCK where 
  webdb.UserService.RidUser = webdb.UserSession.RidUser,
    each webdb.Service NO-LOCK where 
  webdb.Service.RidService = webdb.UserService.RidService,
    each webdb.ServiceType of webdb.Service NO-LOCK where
  webdb.ServiceType.TypeName = "SystemAdmin":
  state = true.
  leave.
end.
if not state then
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
  webdb.UserService.RidUserService = ServiceId EXCLUSIVE-LOCK NO-ERROR NO-WAIT.
if available webdb.UserService then
do:
  webdb.UserService.CountStarted = webdb.UserService.CountStarted + 1.

  create webdb.Context.
  assign
  webdb.Context.RidSession = RidSession
  webdb.Context.RidContextUp = RidContext.
  webdb.Context.ContextType = "SystemAdmin".
  ModuleContextId = webdb.Context.ContextKey.

  /* Скопируем контекст вышестоящего объекта и запишем точки доступа */
  run webservices/webdb/src/CopyContext.p (ContextId, ModuleContextId).
  for each webdb.Service where webdb.Service.RidService = webdb.UserService.RidService NO-LOCK,
      each webdb.Db of webdb.Service NO-LOCK:

    run webservices/webdb/src/SaveContext.p (INPUT-OUTPUT ModuleContextId, 
     "webEndPoint=" + webdb.Db.WebServPath + "&" +
     "webEndPoint2=" + webdb.Db.WebServPath2 + "&role=SystemAdmin").
    if webdb.UserService.ReadOnly then
    do:
      run webservices/webdb/src/SaveContext.p (INPUT-OUTPUT ModuleContextId, 
        "read-only=true&v-only=true").
    end.
  end.
  Module = "admin/sysadmin.html".
  return "OK".
end.

RETURN "".
