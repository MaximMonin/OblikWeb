/* Copyright (C) Maxim A. Monin 2009-2010 */

DEFINE TEMP-TABLE FrameData NO-UNDO
  FIELD RidFF           AS integer
  FIELD InternalValue   as character
  FIELD FormValue       as character.

define input-output parameter DocsId as integer. /* CallBack Key */
define input-output parameter ContextId as character.

define input parameter RidDoc as integer.
define input-output parameter FrameKey as integer.
define output parameter TABLE for FrameData.

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
define variable fformat as character.

FOR EACH doc-frame-fields
   WHERE doc-frame-fields.rid-frame = FrameKey AND
         doc-frame-fields.is-del = no NO-LOCK,
    EACH doc-data-type OF doc-frame-fields NO-LOCK,
    EACH basetype OF doc-data-type NO-LOCK:

   rid-ff = doc-frame-fields.rid-ff.
   fformat = "".
   if basetype.progress-type = "DECIMAL" or basetype.progress-type = "INTEGER" then
     fformat = doc-frame-fields.field-format.

   create FrameData.
   FrameData.RidFF = rid-ff.
   FrameData.InternalValue = "".
   FrameData.FormValue = "".

   FIND system.doc-field-data WHERE system.doc-field-data.rid-document = RidDoc 
      AND system.doc-field-data.rid-ff = rid-ff NO-LOCK NO-ERROR.
   IF AVAILABLE system.doc-field-data then
   do: 
     FrameData.InternalValue = system.doc-field-data.field-value.
     run src/kernel/strtofrm.p ( rid-ff, system.doc-field-data.field-value, fformat ).
     FrameData.FormValue = RETURN-VALUE.
   end.
end.

for each doc-form-fields where doc-form-fields.rid-form-frame = FrameKey NO-LOCK,
    each doc-frame-fields where doc-frame-fields.rid-ff = doc-form-fields.rid-ff NO-LOCK,
    EACH doc-data-type OF doc-frame-fields NO-LOCK,
    EACH basetype OF doc-data-type NO-LOCK:
   rid-ff = doc-form-fields.rid-ff.

   create FrameData.
   FrameData.RidFF = rid-ff.
   FrameData.InternalValue = "".
   FrameData.FormValue = "".

   fformat = "".
   if basetype.progress-type = "DECIMAL" or basetype.progress-type = "INTEGER" then
     fformat = doc-frame-fields.field-format.

   FIND system.doc-field-data WHERE system.doc-field-data.rid-document = RidDoc 
      AND system.doc-field-data.rid-ff = rid-ff NO-LOCK NO-ERROR.
   IF AVAILABLE system.doc-field-data then
   do: 
     FrameData.InternalValue = system.doc-field-data.field-value.
     run src/kernel/strtofrm.p ( rid-ff, system.doc-field-data.field-value, fformat ).
     FrameData.FormValue = RETURN-VALUE.
   end.
end.
