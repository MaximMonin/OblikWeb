/* Copyright (C) Maxim A. Monin 2009-2010 */

define input parameter ContextId as character.

DEFINE SHARED VARIABLE uid as character. 
DEFINE SHARED VARIABLE read-only as logical.
DEFINE SHARED VARIABLE current-role as character.
DEFINE SHARED VARIABLE lang as character.
DEFINE SHARED VARIABLE webAdmin as logical.

define variable var-name as character.
define variable var-value as character.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

for each webdb.ContextData of webdb.Context NO-LOCK:
  var-name = webdb.ContextData.ParamName.
  var-value = webdb.ContextData.DataValue.
  if var-name = "webuser" then
    uid = var-value.
  if var-name = "read-only" or var-name = "v-only" then
    read-only = LOGICAL(var-value).
  if var-name = "lang" then
    lang = var-value.
  if var-name = "role" then
    current-role = var-value.
end.
if current-role = "UserAdmin" or current-role = "SystemAdmin" then
  webAdmin = true.
else
  webAdmin = false.
