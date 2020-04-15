/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input-output parameter TableName as character.
define input parameter MaxRecCount as integer.
define input parameter sortby as character.
define input parameter filtertext as character.

define output parameter TABLE-HANDLE TableData.

define variable i as integer.
define variable j as integer.
define variable fieldcount as integer.
DEFINE variable hQuery           AS HANDLE NO-UNDO.
DEFINE variable hBuffer          AS HANDLE NO-UNDO.
DEFINE VARIABLE hBufferField     AS HANDLE NO-UNDO.
DEFINE variable hQueryData       AS HANDLE NO-UNDO.
DEFINE variable hBufferData      AS HANDLE NO-UNDO.
DEFINE VARIABLE hBufferFieldData AS HANDLE NO-UNDO.

define variable TableNameFull as character.
TableNameFull = "system." + TableName.

define variable sqlquery as character.
sqlquery = "FOR EACH " + TableNameFull + " NO-LOCK".
filtertext = trim(filtertext).
if filtertext <> "" then
  sqlquery = sqlquery + " where " + filtertext.
if trim(sortby) <> "" then
  sqlquery = sqlquery + " by " + TableNameFull + "." + sortby.

find first system._File where system._File._File-Name = TableName NO-LOCK NO-ERROR.
if not available system._File then RETURN.

create temp-table TableData.

fieldcount = 0.
FOR EACH system._Field OF system._File NO-LOCK By system._Field._Order:
  TableData:ADD-NEW-FIELD (system._Field._Field-name, system._Field._Data-Type). 
  fieldcount = fieldcount + 1.
END.
TableData:TEMP-TABLE-PREPARE ("TableData").

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


CREATE QUERY hQuery.
CREATE BUFFER hBuffer FOR TABLE TableData:DEFAULT-BUFFER-HANDLE.
hQuery:SET-BUFFERS(hBuffer).

CREATE QUERY hQueryData.
CREATE BUFFER hBufferData FOR TABLE TableNameFull.
hQueryData:SET-BUFFERS(hBufferData).
hQueryData:QUERY-PREPARE(sqlquery).
hQueryData:QUERY-OPEN.
hQueryData:GET-FIRST ().
repeat:
  if hQueryData:QUERY-OFF-END then leave.

  hBuffer:BUFFER-CREATE().

  DO j = 1 TO fieldcount:
    hBufferField = hBuffer:BUFFER-FIELD(j).
    hBufferFieldData = hBufferData:BUFFER-FIELD(j).
    hBufferField:BUFFER-VALUE = hBufferFieldData:BUFFER-VALUE.
  END.
  MaxRecCount = MaxRecCount - 1.
  if MaxRecCount <= 0 then leave.
  hQueryData:GET-NEXT ().
END.
