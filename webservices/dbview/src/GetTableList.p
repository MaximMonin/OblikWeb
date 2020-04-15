/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table TableList NO-UNDO
  field table_name as character
  field table_label as character
  field sys as logical
  index i0 sys asc table_name asc.

define input-output parameter ContextId as character.
define output parameter table for TableList.

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

for each system._File:                
  create TableList.
  assign
  TableList.table_name  = system._File._File-Name
  TableList.table_label = system._File._File-Label
  TableList.sys         = system._File._Frozen.
end.
