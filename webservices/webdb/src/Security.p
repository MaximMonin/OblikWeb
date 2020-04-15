/* Copyright (C) Maxim A. Monin 2009-2010 */

/* ����뢠�� �ࠢ��� ������᭮�� �� ࠡ�� � ���砬�,
   �뤠����� Web �㦡��                              */

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
/* �������� �㡫��� ���� ����� �ᯮ�짮���� �� ��� ������.
   ���쪮 ������� ᭨���� �ਧ��� �㡫�筮�� ࠧ��� �ᯮ�짮���� 
   ���� �����.
   ����� �� ⠪�� ����権 - ����祭�� �室��� ��ࠬ��஢ ����� 
*/
if webdb.Context.PublicKey then
do:
  ContextId = "Timeout".
  RETURN "ERROR".
end.
if webdb.Context.SecurityErrors >= 3 then  /* ��᫮ ����⮪ ���ࠢ��쭮 �ᯮ�짮���� ���⥪�� ���� */
do:
  ContextId = "Timeout".
  RETURN "ERROR".
end.
if (NOW - webdb.Context.UseTime) / 3600000 > 30 /* <���� �� �ᯮ�짮����� 㦥 ����� 30 �ᮢ) */
then do:
  ContextId = "Timeout".
  RETURN "ERROR".
end.
if (NOW - webdb.Context.UseTime) / 3600000 > 6 /* <���� �� �ᯮ�짮����� 㦥 ����� 6 �ᮢ) */
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
