/* Copyright (C) Maxim A. Monin 2009-2010 */

/* ������� ���㬥�⮢, ���� persistent ��ꥪ⮬ �������� ContextKey 
   �� � �⮣� �ਢ���� � ⮬�, �� �ᨭ�஭�� ��楤���, �ᯮ����騥 ��� 
   �� ���� ������� ��ଠ�쭮 ࠡ���� � ���� ���� ��ꥪ� �� �㤥� 㤠���.
   ���⮬� ���⥪�� ��������� � ��㣮� ��ꥪ�.
*/


define input-output parameter KeyId as integer. /* Callback key */
define input-output parameter ContextId as character.
define input parameter ContextType as character.
define output parameter NewContextId as character initial "".

define variable RidContext as integer.
define variable RidSession as integer.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
do:
  pause 1.
  return "".
end.
RidContext = webdb.Context.RidContext.
RidSession = webdb.Context.RidSession.
run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
do:
  pause 1.
  return RETURN-VALUE.
end.

create webdb.Context.
assign
webdb.Context.RidSession = RidSession
webdb.Context.RidContextUp = RidContext
webdb.Context.ContextType = ContextType
webdb.Context.PublicKey = no.

NewContextId = webdb.Context.ContextKey.
run webservices/webdb/src/CopyContext.p (ContextId, NewContextId).
