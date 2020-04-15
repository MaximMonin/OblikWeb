/* Copyright (C) Maxim A. Monin 2009-2010 */

define input parameter login as character.
define input parameter pwd as character.
define input-output parameter ContextId as character initial "".

define variable state as logical.

find first webdb.WebUsers where webdb.WebUsers.UserLogin = login NO-LOCK NO-ERROR.
if not available webdb.WebUsers then
do:
  pause 1.
  return "".
end.
if webdb.WebUsers.banned then
do:
  pause 1.
  return "Banned".
end.

state = SETUSERID ( login, pwd, "webdb" ).
if state = false then
do:
  pause 1.
  return "".
end.

if ContextId begins "Relogin," then
  ContextId = Substring(ContextId, 9).
find first webdb.Context where webdb.Context.ContextKey = ContextId NO-ERROR.
if not available webdb.Context then RETURN "".

webdb.Context.UseTime = NOW.
run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
