/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter basetype as character.
define input parameter AppendParam as character.
define input parameter ContextParam as character.
define input parameter SearchString as character.
define output parameter TABLE-HANDLE SearchData.

/* Security + инициализация глобальных переменных */
{webservices/webdb/src/webdb.i}

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
run webservices/webdb/src/InitGlobalVars.p (ContextId).
/* /Security + инициализация глобальных переменных */

define variable AllRecords as logical initial false.

run webservices/webdb/src/BasetypeWeb.p ( basetype, AppendParam, ContextParam, SearchString, 
  input-output AllRecords, OUTPUT TABLE-HANDLE SearchData ).
