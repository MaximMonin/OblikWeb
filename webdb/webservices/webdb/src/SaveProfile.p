/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table UserProfile NO-UNDO
  field UserLogin as character
  field UserName as character
  field UserEMail as character
  field UserCompany as character
  field UserPosition as character
  field UserBanned as logical
  field ConfPass as character
  field NewPass as character
  field OldPass as character
  field ChangePass as logical
  index i0 UserLogin asc.

define temp-table AvailServices NO-UNDO
  field ServiceId as integer
  field ServiceRid as integer
  field UserServiceName as character
  field ServiceName as character
  field ServiceType as character
  field RunCount as integer
  field ReadOnly as logical
  field Enabled as logical
  index i0 RunCount desc
  index i1 ServiceRid.

define input-output parameter ContextId as character.
define input parameter IsNew as logical.
define input parameter table for UserProfile.
define input parameter table for AvailServices.
define output parameter OutMessage as character initial "Error".

define variable state as logical.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
do:
  pause 1. 
  return "".
end.
find first webdb.UserSession of webdb.Context NO-LOCK NO-ERROR.
if not available webdb.UserSession then RETURN.

run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
do:
  pause 1.
  return RETURN-VALUE.
end.

find first UserProfile NO-ERROR.
if not available UserProfile then RETURN.

define variable newuserid as integer.
find first webdb.WebUsers where webdb.WebUsers.UserLogin = UserProfile.UserLogin NO-LOCK NO-ERROR.
if available webdb.WebUsers and IsNew or UserProfile.UserLogin = "" then
do:
  OutMessage = "BadUser".
  RETURN.
end.

define variable isAdmin as logical.
isAdmin = False.
if webdb.Context.ContextType = "UserAdmin" or 
   webdb.Context.ContextType = "SystemAdmin" then
do:
  isAdmin = true.
end.
for each webdb.ContextData of webdb.Context where 
  webdb.ContextData.ParamName = "read-only" NO-LOCK:
  if webdb.ContextData.DataValue = "true" then
  do:
    pause 1.
    run webservices/webdb/src/SecurityError.p (INPUT ContextId).
    RETURN.
  end.
end.
/* Only admin can add users */
if not available webdb.WebUsers and not isAdmin then
do:
  pause 1.
  run webservices/webdb/src/SecurityError.p (INPUT ContextId).
  RETURN.
end.
/* Not admin can change only own profile */
if available webdb.WebUsers and not isAdmin then
do:
  if webdb.WebUsers.RidUser <> webdb.UserSession.RidUser then
  do:
    pause 1.
    run webservices/webdb/src/SecurityError.p (INPUT ContextId).
    RETURN.
  end.
end.
/* Checking Services Set */
for each AvailServices:
  find first webdb.UserService where
    AvailServices.ServiceId = webdb.UserService.RidUserService NO-ERROR.
  if available webdb.UserService then
  do:
    /* Ссылка на сервис может быть задана только для существующих пользователей */
    if not available webdb.WebUsers then  
    do:
      pause 1.
      run webservices/webdb/src/SecurityError.p (INPUT ContextId).
      RETURN.
    end.
    /* Передается имя одного пользователя а сервис другого пользователя */
    if webdb.UserService.RidUser <> webdb.WebUsers.RidUser then
    do:
      pause 1.
      run webservices/webdb/src/SecurityError.p (INPUT ContextId).
      RETURN.
    end.
  end.
  find first webdb.Service where webdb.Service.RidService = AvailServices.ServiceRid NO-LOCK NO-ERROR.
  if not available webdb.Service then
  do:
    delete AvailServices.
    NEXT.
  end.
  state = false.
  for each webdb.UserService where webdb.UserService.RidService = webdb.Service.RidService NO-LOCK:
    if webdb.UserService.RidUser = webdb.UserSession.RidUser then
      state = true.
  end.
  /* Менять атрибуты не своих сервисов может только SystemAdmin
     UserAdmin cannot change Services that not available to him/her */
  if state = false and webdb.Context.ContextType <> "SystemAdmin" then
  do:
    pause 1.
    run webservices/webdb/src/SecurityError.p (INPUT ContextId).
    RETURN.
  end.
end.


if not available webdb.WebUsers then
do:
  if UserProfile.NewPass <> UserProfile.ConfPass then
  do:
    OutMessage = "BadPassword".
    pause 1.
    RETURN.
  end.

  find last webdb.WebUsers use-index id NO-LOCK NO-ERROR.
  if available webdb.WebUsers then
    newuserid = webdb.WebUsers.IdUser + 1.
  else 
    newuserid = 1.

  create webdb.WebUsers.
  webdb.WebUsers.UserLogin = UserProfile.UserLogin.
  webdb.WebUsers.IdUser = newuserid.
  
  find first _user where _user._userid = UserProfile.UserLogin NO-ERROR.
  if available _user then
    delete _user.

  create _user.
  _user._userid = UserProfile.UserLogin.
  _user._password = ENCODE (UserProfile.NewPass).
end.
else do:
  if UserProfile.ChangePass then
  do:
    state = SETUSERID ( UserProfile.UserLogin, UserProfile.OldPass, "webdb" ).
    if not state then
    do:
      OutMessage = "BadPassword".
      pause 1.
      run webservices/webdb/src/SecurityError.p (INPUT ContextId).
      RETURN.
    end.
  end.
  find first webdb.WebUsers where webdb.WebUsers.UserLogin = 
    UserProfile.UserLogin EXCLUSIVE-LOCK NO-ERROR NO-WAIT.
  if available webdb.WebUsers and UserProfile.ChangePass and 
     UserProfile.NewPass = UserProfile.ConfPass then
  do:
    find first _user where _user._userid = UserProfile.UserLogin NO-ERROR.
    if available _user then
      delete _user.

    create _user.
    _user._userid = UserProfile.UserLogin.
    _user._password = ENCODE (UserProfile.NewPass).
  end.
end.
if available webdb.WebUsers then
do:
  webdb.WebUsers.UserName = UserProfile.UserName.
  webdb.WebUsers.UserEmail = UserProfile.UserEMail.
  webdb.WebUsers.UserCompany = UserProfile.UserCompany.
  webdb.WebUsers.UserPosition = UserProfile.UserPosition.
  if webdb.Context.ContextType = "SystemAdmin" then
    webdb.WebUsers.Banned = UserProfile.UserBanned.

  for each AvailServices:
    find first webdb.UserService where
      AvailServices.ServiceId = webdb.UserService.RidUserService NO-ERROR.
    if available webdb.UserService then
    do:
      if AvailServices.Enabled = false then
      do:
        if isAdmin then
          delete webdb.UserService.
      end.
      else do:
        webdb.UserService.ServiceName = AvailServices.UserServiceName.
        if isAdmin then
          webdb.UserService.ReadOnly = AvailServices.ReadOnly.
      end.
    end.
    else do:
      if AvailServices.Enabled = true and isAdmin then
      do:
        create webdb.UserService.
        webdb.UserService.RidService = AvailServices.ServiceRid.
        webdb.UserService.RidUser = webdb.WebUsers.RidUser.
        webdb.UserService.ServiceName = AvailServices.UserServiceName.
        webdb.UserService.ReadOnly = AvailServices.ReadOnly.
      end.
    end.
  end.

  OutMessage = "OK".
end.
