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
define input parameter UserLogin as character.
define output parameter table for UserProfile.
define output parameter table for AvailServices.

create UserProfile.  

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

find first webdb.UserSession of webdb.Context NO-LOCK NO-ERROR.
if not available webdb.UserSession then RETURN.

find first webdb.WebUsers where webdb.WebUsers.RidUser = webdb.UserSession.RidUser NO-LOCK NO-ERROR.
if not available webdb.WebUsers then RETURN.

run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
  RETURN.

define variable isAdmin as logical.
isAdmin = False.
if webdb.Context.ContextType = "UserAdmin" or 
   webdb.Context.ContextType = "SystemAdmin" then
  isAdmin = true.
if (UserLogin <> "" or IsNew) and isAdmin = false then
do:
  pause 1.
  RETURN.
end.

if UserLogin <> "" then
do:
  find first webdb.WebUsers where webdb.WebUsers.UserLogin = UserLogin NO-LOCK NO-ERROR.
  if not available webdb.WebUsers then RETURN.
end.

if not IsNew then
do:
  UserProfile.UserLogin = webdb.WebUsers.UserLogin.
  UserProfile.UserName = webdb.WebUsers.UserName.
  UserProfile.UserEMail = webdb.WebUsers.UserEmail.
  UserProfile.UserCompany = webdb.WebUsers.UserCompany.
  UserProfile.UserPosition = webdb.WebUsers.UserPosition.
  UserProfile.UserBanned = webdb.WebUsers.Banned.
end.

if not isAdmin then
do:
  for each webdb.UserService of webdb.WebUsers NO-LOCK,
      each webdb.Service where webdb.Service.RidService = webdb.UserService.RidService NO-LOCK,
      each webdb.ServiceType of webdb.Service NO-LOCK:
    find first AvailServices where 
      AvailServices.ServiceRid = webdb.Service.RidService NO-LOCK NO-ERROR.

    create AvailServices.
    assign
      AvailServices.ServiceId     = webdb.UserService.RidUserService
      AvailServices.ServiceRid    = webdb.UserService.RidService
      AvailServices.UserServiceName = webdb.UserService.ServiceName
      AvailServices.ServiceName   = webdb.Service.ServiceName
      AvailServices.ServiceType   = webdb.ServiceType.TypeName
      AvailServices.RunCount      = webdb.UserService.CountStarted.
      AvailServices.ReadOnly      = webdb.UserService.ReadOnly.
    AvailServices.Enabled = true.
  end.
end.
else do:
  if webdb.Context.ContextType = "SystemAdmin" then
  do:
    for each webdb.Service NO-LOCK,
        each webdb.ServiceType of webdb.Service NO-LOCK:

      find first AvailServices where 
        AvailServices.ServiceRid = webdb.Service.RidService NO-LOCK NO-ERROR.
      if not available AvailServices then
      do:
        create AvailServices.
        assign
          AvailServices.ServiceId     = 0
          AvailServices.ServiceRid    = webdb.Service.RidService
          AvailServices.UserServiceName = webdb.Service.ServiceName
          AvailServices.ServiceName   = webdb.Service.ServiceName
          AvailServices.ServiceType   = webdb.ServiceType.TypeName
          AvailServices.RunCount      = 0.
        AvailServices.ReadOnly      = false.
        AvailServices.Enabled = false.
      end.
    end.
  end.
  else do:
    find first webdb.WebUsers where webdb.WebUsers.RidUser = webdb.UserSession.RidUser NO-LOCK NO-ERROR.
    for each webdb.UserService of webdb.WebUsers NO-LOCK,
      each webdb.Service where webdb.Service.RidService = webdb.UserService.RidService NO-LOCK,
      each webdb.ServiceType of webdb.Service NO-LOCK:

      find first AvailServices where 
        AvailServices.ServiceRid = webdb.Service.RidService NO-LOCK NO-ERROR.
      if not available AvailServices then
      do:
        create AvailServices.
        assign
          AvailServices.ServiceId     = 0
          AvailServices.ServiceRid    = webdb.UserService.RidService
          AvailServices.UserServiceName = webdb.UserService.ServiceName
          AvailServices.ServiceName   = webdb.Service.ServiceName
          AvailServices.ServiceType   = webdb.ServiceType.TypeName
          AvailServices.RunCount      = 0.
        AvailServices.ReadOnly      = false.
        AvailServices.Enabled = false.
      end.
    end.
  end.
  find first webdb.WebUsers where webdb.WebUsers.UserLogin = UserProfile.UserLogin NO-LOCK NO-ERROR.
  if not available webdb.WebUsers then RETURN.

  for each webdb.UserService of webdb.WebUsers NO-LOCK,
      each webdb.Service where webdb.Service.RidService = webdb.UserService.RidService NO-LOCK,
      each webdb.ServiceType of webdb.Service NO-LOCK:
    find first AvailServices where 
      AvailServices.ServiceRid = webdb.Service.RidService NO-ERROR.

    /* UserAdmin не видит сервисы пользователя, которые админу не доступны */
    if not available AvailServices then NEXT.
    
    assign
    AvailServices.ServiceId     = webdb.UserService.RidUserService
    AvailServices.ServiceRid    = webdb.UserService.RidService
    AvailServices.UserServiceName = webdb.UserService.ServiceName
    AvailServices.ServiceName   = webdb.Service.ServiceName
    AvailServices.ServiceType   = webdb.ServiceType.TypeName
    AvailServices.RunCount      = webdb.UserService.CountStarted.
    AvailServices.ReadOnly      = webdb.UserService.ReadOnly.
    AvailServices.Enabled = true.
  end.
end.

