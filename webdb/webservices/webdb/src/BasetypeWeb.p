/* Copyright (C) Maxim A. Monin 2009-2010 */

define input parameter basetype as character.
define input parameter AppendParam as character.
define input parameter ContextParam as character.
define input parameter SearchString as character.
define input-output parameter AllRecords as logical.
define output parameter TABLE-HANDLE SearchData.

DEFINE SHARED VARIABLE uid as character. 
DEFINE SHARED VARIABLE read-only as logical.
DEFINE SHARED VARIABLE current-role as character.
DEFINE SHARED VARIABLE lang as character.
DEFINE SHARED VARIABLE webAdmin as logical.

DEFINE variable hQuery           AS HANDLE NO-UNDO.
DEFINE variable hBuffer          AS HANDLE NO-UNDO.
DEFINE VARIABLE hBufferField     AS HANDLE NO-UNDO.
define variable itemcount        as integer no-undo.
define variable btime            as datetime.

create temp-table SearchData.
SearchData:ADD-NEW-FIELD   ("IntValue", "character"). 
SearchData:ADD-NEW-FIELD   ("FormValue", "character"). 
SearchData:ADD-NEW-FIELD   ("IdValue", "character"). 
SearchData:ADD-NEW-INDEX   ("i0", false, true).
SearchData:ADD-INDEX-FIELD ("i0","IdValue").

SearchData:TEMP-TABLE-PREPARE ("SearchData").
CREATE BUFFER hBuffer FOR TABLE SearchData:DEFAULT-BUFFER-HANDLE.

if AllRecords then
  itemcount = 1000.
else
  itemcount = 10.

if basetype = "USERSERVICE" then
do:
  find first webdb.WebUsers where webdb.WebUsers.UserLogin = uid NO-LOCK NO-ERROR.
  if not available webdb.WebUsers then RETURN.

  for each webdb.UserService no-lock where webdb.UserService.RidUser = webdb.WebUsers.RidUser and
    (AllRecords OR webdb.UserService.ServiceName matches ("*" + searchstring + "*")):

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(webdb.UserService.RidService).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE = webdb.UserService.ServiceName.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = webdb.UserService.ServiceName.
  end.
end.

if basetype = "SERVICE" then
do:
  for each webdb.Service no-lock where 
    (AllRecords OR webdb.Service.ServiceName matches ("*" + searchstring + "*")):

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(webdb.Service.RidService).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE = webdb.Service.ServiceName.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = webdb.Service.ServiceName.
  end.
end.

if basetype = "USER" then
do:
  if webAdmin = false then RETURN.

  for each webdb.WebUsers no-lock where AllRecords OR
    (webdb.WebUsers.UserLogin + " " + webdb.WebUsers.UserName) matches "*" + searchstring + "*":

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(webdb.WebUsers.RidUser).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  webdb.WebUsers.UserLogin.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      webdb.WebUsers.UserLogin + " " + webdb.WebUsers.UserName.
  end.
end.

if basetype = "SERVICETYPE" then
do:
  for each webdb.ServiceType no-lock where 
    (AllRecords OR webdb.ServiceType.TypeName matches ("*" + searchstring + "*")):

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(webdb.ServiceType.RidServiceType).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE = webdb.ServiceType.TypeName.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = webdb.ServiceType.TypeName.
  end.
end.

if basetype = "DB" then
do:
  for each webdb.DB no-lock where 
    (AllRecords OR webdb.DB.DB_Name matches ("*" + searchstring + "*")):

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(webdb.DB.RidDB).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE = webdb.DB.DB_Name.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = webdb.DB.DB_Name.
  end.
end.
