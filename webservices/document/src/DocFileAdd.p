/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter RidDoc as integer.
define input parameter HostFileName as character.
define input parameter LocalFileName as character.
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
OutMessage = ENTRY(l,"Файл не найден,File not found").


if search(HostFileName) = ? then
do:
  RETURN.
end.

define variable riduser as integer initial ?.
define variable HostFileSize as integer.
define variable filelistrid as integer.
define variable file-num as integer.

FILE-INFORMATION:FILE-NAME = HostFileName.
HostFileName = FILE-INFORMATION:FULL-PATHNAME.
HostFileSize = FILE-INFORMATION:FILE-SIZE.

find first system.users WHERE system.users.sys-name = uid NO-LOCK NO-ERROR.
IF AVAILABLE users THEN
  riduser = system.users.rid-user.
  
find first system.document where system.document.rid-document = RidDoc NO-LOCK NO-ERROR.
if available system.document then
DO:  
  FIND FIRST file-list OF system.document NO-LOCK NO-ERROR.
  IF NOT AVAILABLE file-list THEN
  DO:
    find first system.document where system.document.rid-document = RidDoc EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
    if not available system.document then
    do:
      OS-DELETE value(HostFileName).
      OutMessage = ENTRY(l, "Документ занят другим пользователем. Файл не добавлен,Document is locked by another user. File is not attached").
      RETURN.
    end.

    CREATE file-list.
    ASSIGN 
      system.document.rid-file-list = file-list.rid-file-list.
    release system.document.
  END.

  filelistrid = file-list.rid-file-list.
    
  FIND LAST doc-files OF file-list NO-LOCK NO-ERROR.
  IF AVAILABLE doc-files THEN
    file-num = doc-files.number + 1.
  ELSE
    file-num = 1.

  CREATE doc-files.
  ASSIGN 
    doc-files.filename      = LocalFileName
    doc-files.number        = file-num
    doc-files.filesize      = HostFileSize
    doc-files.filedate      = NOW
    doc-files.rid-user      = riduser 
    doc-files.rid-file-list = filelistrid
    doc-files.descr = "".
  
  COPY-LOB FROM FILE HostFileName TO doc-files.file-blob NO-CONVERT.
END.

OS-DELETE value(HostFileName).
OutMessage = "".
