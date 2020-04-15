/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter DocsId as integer. /* CallBack Key */
define input-output parameter ContextId as character.
define input parameter RidDoc as integer.
define output parameter DocRight as integer.
define output parameter OutMessage as character.

OutMessage = "У вас нет прав на просмотр этого документа".

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

run src/kernel/docright.p ( RidDoc ).
DocRight = Integer (RETURN-VALUE).
if DocRight < 1 then RETURN.

define variable temp-rowid as rowid.
RUN src/kernel/protdoc3.p ( RidDoc, 2, "Просмотр через Web", OUTPUT temp-rowid).          

OutMessage = "".
