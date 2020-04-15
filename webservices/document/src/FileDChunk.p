/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter HostFileName as character.
define input-output parameter BytesFrom as integer.
define input-output parameter BytesTo as integer.
define output parameter OutMessage as character initial "".
define output parameter HostFileSize as integer.
define output parameter FileBinary as MEMPTR NO-UNDO.

define variable CopyBytes as integer.

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
OutMessage = ENTRY(l,"Файл не найден,File not found").

if search(HostFileName) = ? then
do:
  RETURN.
end.

FILE-INFORMATION:FILE-NAME = HostFileName.
HostFileName = FILE-INFORMATION:FULL-PATHNAME.
HostFileSize = FILE-INFORMATION:FILE-SIZE.

if BytesTo > HostFileSize then
  BytesTo = HostFileSize.
if BytesFrom > BytesTo then
do:
  OutMessage = ENTRY(l,"Неверные параметры запроса данных файла,Incorrect parameters to load file").
  RETURN.
end.
  
SET-SIZE (FileBinary) = 0.
CopyBytes = BytesTo - BytesFrom + 1.
SET-SIZE (FileBinary) = CopyBytes.

COPY-LOB FROM FILE HostFileName
  Starting AT BytesFrom FOR CopyBytes TO FileBinary NO-CONVERT.
OutMessage = "".
