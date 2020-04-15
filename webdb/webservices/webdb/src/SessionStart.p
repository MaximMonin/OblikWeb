/* Copyright (C) Maxim A. Monin 2009-2010 */

define input parameter login as character.
define input parameter pwd as character.
define input parameter lang as character.
define output parameter ContextId as character initial "".

define variable state as logical.

/* Сделаем задержку после неудачного логина на секунду. */
/* Как механизм антиспама */

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

create webdb.UserSession.
assign
webdb.UserSession.RidUser = webdb.WebUsers.RidUser
webdb.UserSession.UserLogin = login.

create webdb.Context.
assign
webdb.Context.RidSession = webdb.UserSession.RidSession
webdb.Context.RidContextUp = webdb.Context.RidContext.

ContextId = webdb.Context.ContextKey.

run webservices/webdb/src/SaveContext.p (INPUT-OUTPUT ContextId, 
   "webuser=" + webdb.WebUsers.UserLogin + "&" +
   "webusername=" + webdb.WebUsers.UserName + "&" +
   "lang=" + lang)).

return "OK".
