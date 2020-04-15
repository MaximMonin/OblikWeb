/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter RidFileDoc as integer.
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
OutMessage = ENTRY(l,"Ошибка удаления файла,File deletion error").


find first system.doc-files where system.doc-files.rid-doc-files = RidFileDoc EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
if not available system.doc-files then RETURN.

find first system.file-list of system.doc-files NO-LOCK NO-ERROR.
if not available system.file-list then RETURN.
find first system.document of system.file-list EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
if not available system.document then
do:
  OutMessage = ENTRY(l, "Документ занят другим пользователем. Удаление невозможно, Document is locked by another user. Cannot delete").
  RETURN.
end.

run src/kernel/docright.p ( system.document.rid-document ).
if INTEGER(RETURN-VALUE) < 3 then
do:
  OutMessage = ENTRY(l, "У вас нет прав на удаление файла,You dont have a right to delete file").
  RETURN.
end.

delete system.doc-files.

OutMessage = "".
