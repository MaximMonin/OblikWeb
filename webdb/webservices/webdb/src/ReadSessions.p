/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table SessionsList NO-UNDO
  field SessionId as integer
  field UserName as character
  field Login as datetime-tz
  field EndTime as datetime-tz
  field Threads as integer
  field Queries as integer
  field SecErrors as integer
  index i0 EndTime desc
  index i1 SessionId asc.

define input-output parameter ContextId as character.
define input parameter UserRid as integer.
define input parameter DateFrom as date.
define input parameter DateTo as date.
define input parameter MaxRecordCount as integer.
define output parameter table for SessionsList.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
  RETURN.

define variable isAdmin as logical.
isAdmin = False.
if webdb.Context.ContextType = "SystemAdmin" then
  isAdmin = true.
if (not isAdmin) then
do:
  pause 1.
  RETURN.
end.

define variable dt-from as datetime-tz.
define variable dt-to as datetime-tz.
dt-from = DateFrom.
dt-to = DateTo + 1.

for each webdb.Context where webdb.Context.UseTime < dt-to NO-LOCK ,
    each webdb.UserSession of webdb.Context NO-LOCK where
         (webdb.UserSession.RidUser = UserRid or UserRid = 0) and
         webdb.UserSession.StartTime >= dt-from,
    each webdb.WebUsers where webUsers.RidUser = webdb.UserSession.RidUser NO-LOCK                      
    By webdb.Context.UseTime Desc:

  find first SessionsList where SessionsList.SessionId = webdb.UserSession.RidSession NO-ERROR.
  if not available SessionsList then
  do:
    MaxRecordCount = MaxRecordCount - 1.
    if MaxRecordCount < 0 then leave.

    create SessionsList.
    assign
      SessionsList.SessionId = webdb.UserSession.RidSession
      SessionsList.UserName = webdb.UserSession.UserLogin + " " + webdb.WebUsers.UserName
      SessionsList.Login = webdb.UserSession.StartTime
      SessionsList.EndTime = webdb.Context.UseTime.
  end.
end.
for each SessionsList,
    each webdb.Context NO-LOCK where SessionsList.SessionId = webdb.Context.RidSession:
  SessionsList.Threads = SessionsList.Threads + 1.
  SessionsList.Queries = SessionsList.Queries + webdb.Context.NumUsed.
  SessionsList.SecErrors = SessionsList.SecErrors + webdb.Context.SecurityErrors.
end.
