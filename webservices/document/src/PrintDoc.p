/* Copyright (C) Maxim A. Monin 2009-2010 */

define TEMP-TABLE PrintOpers NO-UNDO
  field Module as character
  field ViewOnly as logical
  field FileName as character
  field FileType as character
  field PrintParams as character.

define input-output parameter ContextId as character.
define input-output parameter RidDoc    as integer.
define output parameter OutMessage      as character initial "".
define output parameter table for PrintOpers.

/* Security + инициализация глобальных переменных */
{connect.i}
{oblik.i}

SESSION:SUPPRESS-WARNINGS = TRUE.

define variable l as integer.
l = 1.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
do:
  pause 1.                                 
  OutMessage = ENTRY(l, "Ошибка обмена данными,Data exchange error").
  return.
end.
run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
do:
  pause 1.
  OutMessage = ENTRY(l, "Ошибка обмена данными,Data exchange error").
  return.
end.
run webservices/main/src/InitGlobalVars.p (ContextId).
/* /Security + инициализация глобальных переменных */

if lang begins "ru" then
  l = 1.
else
  l = 2.


&Scoped-define ON-BEFORE-PRINT       16
&Scoped-define ON-PRINT-DOCUMENT      6

DEFINE NEW SHARED VARIABLE put-off AS LOGICAL.

/* Закешируем документ, чтобы алгоритм печати не мог поменять данные документа
   при печати */

define variable rid-doc as integer.      /* Внутренняя ссылка на документ */
define variable maxright as integer.
define variable rv as character.

run src/kernel/docright.p ( RidDoc ).
maxright = INTEGER(RETURN-VALUE).
if maxright = 0 then
do:
  OutMessage = Entry(l, "У вас нет прав на этот документ,You dont have a right on this document").
  RETURN.
end.

FIND system.document WHERE system.document.rid-document = RidDoc NO-LOCK NO-ERROR.
IF NOT AVAILABLE system.document THEN RETURN. 

CREATE tt_document.
BUFFER-COPY system.document TO tt_document.
FIND typedoc OF tt_document NO-LOCK NO-ERROR.
IF NOT AVAILABLE typedoc THEN
do:
  OutMessage = ENTRY(l,"Неизвестный вид документа,Unknown document type").
  RETURN.
end.

/* Кешируем данные самого документа */
RUN src/kernel/bufdoc.p ( RidDoc ).
RUN src/kernel/buffrdoc.p ( tt_document.rid-typedoc ).

CREATE DocumentState.
DocumentState.rid-doc = RidDoc.
ASSIGN 
  DocumentState.BufEdit     = TRUE 
  DocumentState.cash-only   = false
  DocumentState.is-docvonly = true.

rid-doc = RidDoc.

Empty Temp-Table PrintOpers.
Empty Temp-Table tt_proc-messages.

RUN src/kernel/cr_mess_rec.p (rid-doc, uid, "", TODAY, "", currid-cathg, OUTPUT uni-key-AppServer, FALSE, FALSE, OUTPUT TABLE tt_proc-messages).

RUN src/kernel/exectrig.p ( rid-doc, {&ON-BEFORE-PRINT}, ?, 1, ? ).
rv = RETURN-VALUE.
IF rv = "SAVE-AND-PRINT" then
  rv = "PRINT".
if rv = "PRINT" then
do:
  run src/kernel/exectrig.p ( rid-doc, {&ON-PRINT-DOCUMENT}, ?, 1, ? ).
end.

/* Интерфейс с системой печати. События OnPrintDocument/OnCloseDocument
   могут вызывать модули src/editor.w (просмотр текста), 
   src/prn_dvs.w (система печати через драйвера для tty/windows).
   Расшифровываем параметры и формируем результат */

define variable module as character.
define variable param1 as logical.
define variable param2 as character.
define variable param3 as character.
define variable file-param as character.
define variable N as integer.
define variable M as integer.

for each tt_proc-messages:
  module = tt_proc-messages.module.
  param1 = tt_proc-messages.v-only.
  param2 = tt_proc-messages.file-path.
  param3 = tt_proc-messages.params.

  IF module <> "" THEN
  DO:
    DO N = 1 TO NUM-ENTRIES (module) :
      file-param = ENTRY (N, param2).
      DO M = 1 TO NUM-ENTRIES (file-param, ";"):
        if NUM-ENTRIES (ENTRY(M,file-param,";"), "#") < 2 then NEXT.
        if ENTRY(2,ENTRY(M,file-param,";"),"#") = "" then NEXT.
        create PrintOpers.
        assign
          PrintOpers.Module = ENTRY (N, module).
          PrintOpers.ViewOnly = param1.
          PrintOpers.FileName = ENTRY(2,ENTRY(M,file-param,";"),"#").
          PrintOpers.FileType = ENTRY(1,ENTRY(M,file-param,";"),"#").
          PrintOpers.PrintParams = ENTRY (N, param3, "|").
        if PrintOpers.Module = "src/editor.w" then
          PrintOpers.Module = "ViewText".
        if PrintOpers.Module = "src/prn_dvs.w" then
          PrintOpers.Module = "PrintFile".
      END.
    END.
  END.
END.
