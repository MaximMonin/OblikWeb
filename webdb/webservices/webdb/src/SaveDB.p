/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table DBList NO-UNDO
  field DBRid as integer
  field DBId as integer
  field DB_Name as character
  field WSPath as character
  field WSPath2 as character
  field ImagePath as character
  field Services as character
  index i0 DBId asc.

define input-output parameter ContextId as character.
define input parameter table for DBList.
define output parameter OutMessage as character initial "Error".

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
if webdb.Context.ContextType = "SystemAdmin" then
  isAdmin = true.
for each webdb.ContextData of webdb.Context where 
  webdb.ContextData.ParamName = "read-only" NO-LOCK:
  if webdb.ContextData.DataValue = "true" then
  do:
    pause 1.
    run webservices/webdb/src/SecurityError.p (INPUT ContextId).
    RETURN.
  end.
end.
if (not isAdmin) then
do:
  pause 1.
  run webservices/webdb/src/SecurityError.p (INPUT ContextId).
  RETURN.
end.

define variable num-errors as integer.
num-errors = 0.
for each webdb.Db:
  find first DBList where DBList.DBRid = webdb.Db.RidDb NO-ERROR.
  if not available DBList then
  do:
    delete webdb.Db NO-ERROR.
    if ERROR-STATUS:ERROR then
      num-errors = num-errors + 1.
    NEXT.
  end.
  else do:
    assign
    webdb.Db.idDb = DBList.DBId
    webdb.Db.Db_Name = DBList.DB_Name
    webdb.Db.WebServPath = DBList.WSPath
    webdb.Db.WebServPath2 = DBList.WSPath2
    webdb.Db.ImagePath = DBList.ImagePath NO-ERROR.
    if ERROR-STATUS:ERROR then
      num-errors = num-errors + 1.
    else do:
      release webdb.Db NO-ERROR.
      if ERROR-STATUS:ERROR then
        num-errors = num-errors + 1.
    end.
    delete DBList.
  end.
end.
for each DBList:
  create webdb.Db.
  assign
    webdb.Db.idDb = DBList.DBId
    webdb.Db.Db_Name = DBList.DB_Name
    webdb.Db.WebServPath = DBList.WSPath
    webdb.Db.WebServPath2 = DBList.WSPath2
    webdb.Db.ImagePath = DBList.ImagePath NO-ERROR.
  if ERROR-STATUS:ERROR then
    num-errors = num-errors + 1.
  else do:
    release webdb.Db NO-ERROR.
    if ERROR-STATUS:ERROR then
      num-errors = num-errors + 1.
  end.
  delete DBList.
end.
if num-errors = 0 then OutMessage = "OK".
