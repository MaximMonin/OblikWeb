/* Copyright (C) Maxim A. Monin 2009-2010 */

/* Получить связанную информацию по аудиту документа */

define input-output parameter TABLE-HANDLE DocumentData.
define input parameter RidDoc as integer.

DEFINE variable hBuffer          AS HANDLE NO-UNDO.
DEFINE variable hQuery           AS HANDLE NO-UNDO.

CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
CREATE QUERY hQuery.
hQuery:SET-BUFFERS(hBuffer).

define variable EventContext as character.
define variable OperName as character.
define buffer audit-data2 for system._aud-audit-data.

find first system.document where system.document.rid-document = RidDoc NO-LOCK NO-ERROR.
if available system.document then
  EventContext = STRING(system.document.rid-typedoc) + chr(6) + chr(6) + STRING(system.document.rid-document) +
   chr(6) + STRING(system.document.id-document).
EventContext = Substring ( EventContext, 1, R-INDEX(EventContext, chr(6))).

FOR EACH system._aud-audit-data NO-LOCK where
        (system._aud-audit-data._Event-id = 32200 or 
         system._aud-audit-data._Event-id = 32201 or 
         system._aud-audit-data._Event-id = 32202) and
         system._aud-audit-data._Event-context begins EventContext
    BY _aud-audit-data._Audit-date-time DESC:

  OperName = "".
  if (system._aud-audit-data._Event-id = 32200) THEN OperName = "Сохранение документа".
  if (system._aud-audit-data._Event-id = 32201) THEN OperName = "Удаление документа".
  if (system._aud-audit-data._Event-id = 32202) THEN OperName = "Восстановление документа".

  hBuffer:BUFFER-CREATE().
  hBuffer:BUFFER-FIELD("OperDateTime"):BUFFER-VALUE = system._aud-audit-data._Audit-date-time.
  hBuffer:BUFFER-FIELD("OperName"):BUFFER-VALUE = OperName.
  hBuffer:BUFFER-FIELD("User"):BUFFER-VALUE = system._aud-audit-data._User-id.

  find first audit-data2 where
    audit-data2._Client-session-uuid = system._aud-audit-data._Client-session-uuid and
    audit-data2._Database-connection-id = system._aud-audit-data._Database-connection-id and
    audit-data2._Event-id = 32100 NO-LOCK NO-ERROR.
  if available audit-data2 then
  do:
    hBuffer:BUFFER-FIELD("UserName"):BUFFER-VALUE = audit-data2._Event-context.
    hBuffer:BUFFER-FIELD("UserIp"):BUFFER-VALUE = audit-data2._Event-detail.
  end.
  find first audit-data2 where
    audit-data2._Audit-data-guid = system._aud-audit-data._Application-context-id NO-LOCK NO-ERROR.
  if available audit-data2 then
  do:
    find first system.cathg where system.cathg.rid-cathg = INTEGER(audit-data2._Event-context) NO-LOCK NO-ERROR.
    if available system.cathg then
      hBuffer:BUFFER-FIELD("Cathg"):BUFFER-VALUE = system.cathg.name.
  end.
end.
