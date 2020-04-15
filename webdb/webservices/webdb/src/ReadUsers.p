/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table UserProfile NO-UNDO
  field Id as integer
  field Login as character
  field Name as character
  field Banned as logical
  field Company as character
  field Position as character
  field EMail as character
  index i0 Login asc.

define input-output parameter ContextId as character.
define input parameter MyUsers as logical.
define input parameter RidService as character.
define input parameter RidUser as character.
define output parameter table for UserProfile.

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
find first webdb.UserSession of webdb.Context NO-LOCK NO-ERROR.
if not available webdb.UserSession then RETURN.

find first webdb.WebUsers where webdb.WebUsers.RidUser = webdb.UserSession.RidUser NO-LOCK NO-ERROR.
if not available webdb.WebUsers then RETURN.

define variable isAdmin as logical.
isAdmin = False.
if webdb.Context.ContextType = "UserAdmin" or 
   webdb.Context.ContextType = "SystemAdmin" then
do:
  isAdmin = true.
end.
if not isAdmin then
do:
  pause 1.
  RETURN.
end.

define buffer UserService2 for webdb.UserService.
define buffer WebUsers2 for webdb.WebUsers.
define variable ridAdmin as integer.

ridAdmin = webdb.WebUsers.RidUser.

if MyUsers then
do:
  for each webdb.UserService where webdb.UserService.RidUser = ridAdmin NO-LOCK,
    each webdb.Service where webdb.Service.RidService = webdb.UserService.RidService NO-LOCK,
    each UserService2 where UserService2.RidService = webdb.Service.RidService NO-LOCK,
    each WebUsers2 where WebUsers2.RidUser = UserService2.RidUser NO-LOCK:


    if RidService <> "" then
      if integer (RidService) <> webdb.Service.RidService then NEXT.
    if RidUser <> "" then
      if integer (RidUser) <> WebUsers2.RidUser then NEXT.

    find first UserProfile where UserProfile.Login = WebUsers2.UserLogin NO-LOCK NO-ERROR.
    if available UserProfile then NEXT.

    create UserProfile.
    UserProfile.Id       = WebUsers2.IdUser.
    UserProfile.Login    = WebUsers2.UserLogin.
    UserProfile.Name     = WebUsers2.UserName.
    UserProfile.EMail    = WebUsers2.UserEmail.
    UserProfile.Company  = WebUsers2.UserCompany.
    UserProfile.Position = WebUsers2.UserPosition.
    UserProfile.Banned   = WebUsers2.Banned.
  end.
end.
else do:
  for each WebUsers2 NO-LOCK:
    if RidUser <> "" then
      if integer (RidUser) <> WebUsers2.RidUser then NEXT.

    if RidService <> "" then
    do:
      find first UserService2 where UserService2.RidService = INTEGER(RidService) and
        UserService2.RidUser = WebUsers2.RidUser NO-LOCK NO-ERROR.
      if not available UserService2 then NEXT.
    end.

    create UserProfile.
    UserProfile.Id       = WebUsers2.IdUser.
    UserProfile.Login    = WebUsers2.UserLogin.
    UserProfile.Name     = WebUsers2.UserName.
    UserProfile.EMail    = WebUsers2.UserEmail.
    UserProfile.Company  = WebUsers2.UserCompany.
    UserProfile.Position = WebUsers2.UserPosition.
    UserProfile.Banned   = WebUsers2.Banned.
  end.
end.
