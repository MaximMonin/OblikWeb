/* Copyright (C) Maxim A. Monin 2009-2010 */

define input parameter ContextId as character.

DEFINE SHARED VARIABLE uid as character. 
DEFINE SHARED VARIABLE tty as character.
DEFINE SHARED VARIABLE read-only as logical.
DEFINE SHARED VARIABLE oracledb as logical.
DEFINE SHARED VARIABLE currid-cathg as integer. 
DEFINE SHARED VARIABLE current-app as integer.
DEFINE SHARED VARIABLE rid-ent as integer.
DEFINE SHARED VARIABLE RootOfAnobject as integer.
define shared variable lang as character.

define variable var-name as character.
define variable var-value as character.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

for each webdb.ContextData of webdb.Context NO-LOCK:
  var-name = webdb.ContextData.ParamName.
  var-value = webdb.ContextData.DataValue.
  if var-name = "uid" then
    uid = var-value.
  if var-name = "oracledb" then
    oracledb = LOGICAL(var-value).
  if var-name = "read-only" then
    read-only = LOGICAL(var-value).
  if var-name = "RootOfAnobject" then
    RootOfAnobject = INTEGER(var-value).
  if var-name = "currid-cathg" then
    currid-cathg = INTEGER(var-value).
  if var-name = "current-app" then
    current-app = INTEGER(var-value).
  if var-name = "rid-ent" then
    rid-ent = INTEGER(var-value).
  if var-name = "lang" then
    lang = var-value.
end.
tty = "web".
