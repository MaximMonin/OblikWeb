/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define output parameter db_name as character.
define output parameter db_version as character.

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

define variable t1 as character.
define variable t2 as character.
if search ("db/version.dat") <> ? then
do:
  INPUT FROM "db/version.dat".
  IMPORT delimiter "," t1 t2.
  db_version = t1 + " " + t2.
  INPUT CLOSE.
end.

if db_version = "" then
  db_version = "Progress " + PROVERSION.
else
  db_version = db_version + " (Progress " + PROVERSION + ")".

find first system._File where system._File._File-Name = "config" no-lock no-error.
if available system._File then
  run webservices/dbview/src/dbinfo2.p (output db_name).
if db_name = "" then
  db_name = PDBNAME("system") + ".db" .
else
  db_name = db_name + " (" + PDBNAME("system") + ".db" + ")".
