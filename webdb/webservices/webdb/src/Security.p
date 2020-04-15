/* Copyright (C) Maxim A. Monin 2009-2010 */

/* Описывает правила безопасности по работе с ключами,
   выдаваемые Web службой                              */

define input-output parameter ContextId as character.
define input parameter changekey as logical.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-ERROR.
if not available webdb.Context then RETURN "".

/* Additinal protection of SysAdmin PublicKey */
if webdb.Context.NumUsed = 0 and webdb.Context.ContextType = "SystemAdmin" then
do:
  /* Public systemadmin key lifetime is 15 seconds */
  if NOW - webdb.Context.UseTime > 15000 then
  do:
    ContextId = "Timeout".
    RETURN "ERROR".
  end.
end.

webdb.Context.NumUsed = Context.NumUsed + 1.
/* Созданный публичный ключ нельзя использовать по любым операциям.
   Только некоторые снимают признак публичности разрешая использовать 
   ключ далее.
   Одной из таких операций - получение входных параметров модуля 
*/
if webdb.Context.PublicKey then
do:
  ContextId = "Timeout".
  RETURN "ERROR".
end.
if webdb.Context.SecurityErrors >= 3 then  /* Число попыток неправильно использовать контексный ключ */
do:
  ContextId = "Timeout".
  RETURN "ERROR".
end.
if (NOW - webdb.Context.UseTime) / 3600000 > 30 /* <Ключ не использовался уже более 30 часов) */
then do:
  ContextId = "Timeout".
  RETURN "ERROR".
end.
if (NOW - webdb.Context.UseTime) / 3600000 > 6 /* <Ключ не использовался уже более 6 часов) */
then do:
  ContextId = "Relogin," + ContextId.
  RETURN "ERROR".
end.

webdb.Context.UseTime = NOW.

if changekey then
do:
  webdb.Context.ContextKey = ENCODE (STRING(webdb.Context.RidContext) +
    "_" + STRING(webdb.Context.NumUsed)).
  ContextId = webdb.Context.ContextKey.
end.
RETURN "".
