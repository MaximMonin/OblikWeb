/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table AvailServices NO-UNDO
  field ServiceId as integer
  field ServiceName as character
  field ServiceType as character
  field ImageLink as character
  field ServiceDbName as character
  field EndPoint as character
  field DefLogin as character
  field RunCount as integer
  field EasyLogin as logical
  index i0 RunCount desc.

define input-output parameter ContextId as character.
define output parameter UserName as character.
define output parameter UserPos as character.
define output parameter table for AvailServices.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

find first webdb.UserSession of webdb.Context NO-LOCK NO-ERROR.
if not available webdb.UserSession then RETURN.

find first webdb.WebUsers where webdb.WebUsers.RidUser = webdb.UserSession.RidUser NO-LOCK NO-ERROR.
if not available webdb.WebUsers then RETURN.

run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
  RETURN.

UserName = webdb.WebUsers.UserName.
UserPos = webdb.WebUsers.UserCompany.
if UserPos = "" then
  UserPos = webdb.WebUsers.UserPosition.
else
  UserPos = UserPos + ", " + webdb.WebUsers.UserPosition.

for each webdb.UserService of webdb.WebUsers NO-LOCK,
    each webdb.Service where webdb.Service.RidService = webdb.UserService.RidService NO-LOCK,
    each webdb.Db of webdb.Service NO-LOCK,
    each webdb.ServiceType of webdb.Service NO-LOCK:
  create AvailServices.
  assign
    AvailServices.ServiceId     = webdb.UserService.RidUserService
    AvailServices.ServiceName   = webdb.UserService.ServiceName
    AvailServices.ServiceType   = webdb.ServiceType.TypeName
    AvailServices.ImageLink     = webdb.ServiceType.ImagePath
    AvailServices.EasyLogin     = webdb.Service.EasyLogin
    AvailServices.ServiceDbName = webdb.Db.Db_Name
    AvailServices.EndPoint      = webdb.Db.WebServPath
    AvailServices.RunCount      = webdb.UserService.CountStarted.

  if AvailServices.RunCount = 0 then AvailServices.EasyLogin = false.
  if AvailServices.ServiceType = "UserAdmin" or AvailServices.ServiceType = "SystemAdmin" then
    AvailServices.EasyLogin = true.

  if webdb.Db.ImagePath <> "" then
    AvailServices.ImageLink = webdb.Db.ImagePath.
  if AvailServices.ImageLink  = "" then AvailServices.ImageLink = "images/oblikerp_image.png".
  find first webdb.UserServiceParams of webdb.UserService where
     webdb.UserServiceParams.ParamName = "uid" NO-LOCK NO-ERROR.
  if available webdb.UserServiceParams then
    AvailServices.DefLogin = webdb.UserServiceParams.ParamValue.
end.
