/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter DocsId as integer. /* CallBack Key */
define input-output parameter ContextId as character.

define input parameter RidDoc as integer.
define input-output parameter FrameKey as integer.
define output parameter TABLE-HANDLE DocTableData.

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

define variable rid-ff as integer.
define variable cur-row as integer.
DEFINE variable hQuery           AS HANDLE NO-UNDO.
DEFINE variable hBuffer          AS HANDLE NO-UNDO.
DEFINE VARIABLE hBufferField     AS HANDLE NO-UNDO.

define temp-table ff NO-UNDO
  field rid-ff as integer
  field ftype as character
  field fformat as character
  index io rid-ff.

create temp-table DocTableData.
DocTableData:ADD-NEW-FIELD   ("RowId", "integer"). 
DocTableData:ADD-NEW-INDEX   ("i0", false, true).
DocTableData:ADD-INDEX-FIELD ("i0","RowId").

FOR EACH doc-frame-fields
   WHERE doc-frame-fields.rid-frame = FrameKey AND
         doc-frame-fields.is-del = no NO-LOCK,
    EACH doc-data-type OF doc-frame-fields NO-LOCK,
    EACH basetype OF doc-data-type NO-LOCK:

   rid-ff = doc-frame-fields.rid-ff.
   find first FF where FF.rid-ff = rid-ff NO-ERROR.
   if available FF then NEXT.

   create FF.
   FF.rid-ff = rid-ff.
   if basetype.progress-type = "LOGICAL" then
     FF.ftype = "LOGICAL".
   else
     FF.ftype = "CHARACTER".
   FF.fformat = "".
   if basetype.progress-type = "DECIMAL" or basetype.progress-type = "INTEGER" then
     FF.fformat = doc-frame-fields.field-format.

   DocTableData:ADD-NEW-FIELD ("Field" + string(rid-ff), FF.ftype). 
   DocTableData:ADD-NEW-FIELD ("Data"  + string(rid-ff), FF.ftype). 
END.
for each doc-form-fields where doc-form-fields.rid-form-frame = FrameKey NO-LOCK,
    each doc-frame-fields where doc-frame-fields.rid-ff = doc-form-fields.rid-ff NO-LOCK,
    EACH doc-data-type OF doc-frame-fields NO-LOCK,
    EACH basetype OF doc-data-type NO-LOCK:

   rid-ff = doc-form-fields.rid-ff.
   find first FF where FF.rid-ff = rid-ff NO-ERROR.
   if available FF then NEXT.

   create FF.
   FF.rid-ff = rid-ff.
   if basetype.progress-type = "LOGICAL" then
     FF.ftype = "LOGICAL".
   else
     FF.ftype = "CHARACTER".
   FF.fformat = "".
   if basetype.progress-type = "DECIMAL" or basetype.progress-type = "INTEGER" then
     FF.fformat = doc-frame-fields.field-format.

   DocTableData:ADD-NEW-FIELD ("Field" + string(rid-ff), FF.ftype). 
   DocTableData:ADD-NEW-FIELD ("Data"  + string(rid-ff), FF.ftype). 
end.
DocTableData:TEMP-TABLE-PREPARE ("DocTableData").
CREATE BUFFER hBuffer FOR TABLE DocTableData:DEFAULT-BUFFER-HANDLE.

cur-row = -1.
for each system.doc-field-data WHERE
         system.doc-field-data.rid-document = RidDoc NO-LOCK,
   each  FF where FF.rid-ff =  system.doc-field-data.rid-ff NO-LOCK
   by    system.doc-field-data.recnum:

   rid-ff = system.doc-field-data.rid-ff.
   if system.doc-field-data.recnum <> cur-row then
   do:
     cur-row = system.doc-field-data.recnum.

     hBuffer:BUFFER-CREATE().
     hBuffer:BUFFER-FIELD("RowId"):BUFFER-VALUE = cur-row.
   end.
   if FF.ftype = "LOGICAL" then
   do:
     hBuffer:BUFFER-FIELD("Data" + string(rid-ff)):BUFFER-VALUE = LOGICAL(system.doc-field-data.field-value) NO-ERROR.
     hBuffer:BUFFER-FIELD("Field" + string(rid-ff)):BUFFER-VALUE = LOGICAL(system.doc-field-data.field-value) NO-ERROR.
   end.
   else do:
     hBuffer:BUFFER-FIELD("Data" + string(rid-ff)):BUFFER-VALUE = system.doc-field-data.field-value.
     run src/kernel/strtofrm.p ( rid-ff, system.doc-field-data.field-value, ff.fformat ).
     hBuffer:BUFFER-FIELD("Field" + string(rid-ff)):BUFFER-VALUE = RETURN-VALUE.
   end.
end.
