/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter RidFileDoc as integer.
define output parameter HostFileName as character.
define output parameter LocalFileName as character.
define output parameter OutMessage as character initial "".

/* Security + инициализация глобальных переменных */
{connect.i}
{oblik.i}

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
run webservices/main/src/InitGlobalVars.p (ContextId).
/* /Security + инициализация глобальных переменных */

define variable l as integer.
if lang begins "ru" then
  l = 1.
else
  l = 2.
OutMessage = ENTRY(l,"Ошибка чтения файла,File reading error").


find first system.doc-files where system.doc-files.rid-doc-files = RidFileDoc NO-LOCK NO-ERROR.
if not available system.doc-files then RETURN.

run src/system/getmpfi2.p ("tmp").
HostFileName = RETURN-VALUE.
OUTPUT TO VALUE (HostFileName).
OUTPUT CLOSE.
LocalFileName = system.doc-files.filename.

COPY-LOB FROM system.doc-files.file-blob TO FILE HostFileName NO-CONVERT NO-ERROR.
if ERROR-STATUS:ERROR then
  RETURN.

OutMessage = "".
