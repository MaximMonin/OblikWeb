/* Copyright (C) Maxim A. Monin 2009-2010 */

define input parameter basetype as character.
define input parameter AppendParam as character.
define input parameter ContextParam as character.
define input parameter SearchString as character.
define input-output parameter AllRecords as logical.
define output parameter TABLE-HANDLE SearchData.

DEFINE variable hQuery           AS HANDLE NO-UNDO.
DEFINE variable hBuffer          AS HANDLE NO-UNDO.
DEFINE VARIABLE hBufferField     AS HANDLE NO-UNDO.
define variable itemcount        as integer no-undo.
define variable btime            as datetime.

create temp-table SearchData.
SearchData:ADD-NEW-FIELD   ("IntValue", "character"). 
SearchData:ADD-NEW-FIELD   ("FormValue", "character"). 
SearchData:ADD-NEW-FIELD   ("IdValue", "character"). 
SearchData:ADD-NEW-INDEX   ("i0", false, true).
SearchData:ADD-INDEX-FIELD ("i0","IdValue").

SearchData:TEMP-TABLE-PREPARE ("SearchData").
CREATE BUFFER hBuffer FOR TABLE SearchData:DEFAULT-BUFFER-HANDLE.

if AllRecords then
  itemcount = 1000.
else
  itemcount = 10.

if basetype = "TABLES" then
do:
  for each system._File no-lock where 
    (AllRecords OR system._File._File-Name + " " + 
     (if(system._File._File-Label = ?) then("") 
     else (system._File._File-Label)) matches ("*" + searchstring + "*")):

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system._File._File-Name).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE = system._File._File-Name.
    if system._File._File-Label = ? then
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system._File._File-Name.
    else
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system._File._File-Name + " " + system._File._File-Label.
  end.
end.

