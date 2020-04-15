/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table ContextThreads NO-UNDO
  field ContextId as integer
  field ParentId as integer
  field ContextType as character
  field CreateTime as datetime-tz
  field EndTime as datetime-tz
  field Queries as integer
  field SecErrors as integer
  index i0 EndTime desc
  index i1 ContextId asc.

define input-output parameter ContextId as character.
define input parameter SessionRid as integer.
define output parameter table for ContextThreads.

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

for each webdb.Context where webdb.Context.RidSession = SessionRid NO-LOCK:
    create ContextThreads.
    assign
      ContextThreads.ContextId = webdb.Context.RidContext
      ContextThreads.ParentId = webdb.Context.RidContextUp
      ContextThreads.ContextType = webdb.Context.ContextType
      ContextThreads.CreateTime = webdb.Context.CreationTime
      ContextThreads.ContextId = webdb.Context.RidContext
      ContextThreads.EndTime = webdb.Context.UseTime
      ContextThreads.Queries = webdb.Context.NumUsed.
      ContextThreads.SecErrors = webdb.Context.SecurityErrors.
end.
