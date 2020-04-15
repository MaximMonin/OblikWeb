/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input-output parameter TableName as character.

define temp-table TableInfo NO-UNDO
  field table_name as character
  field table_label as character
  field dump_name as character
  field table_desc as character
  field valexp as character
  field valmsg as character
  field sys as logical
  index i0 sys asc table_name asc.

define temp-table TTriggers NO-UNDO
  field event as character
  field proc_name as character
  field override as logical
  field checkcrc as logical
  field ttext as character
  index i0 event.

DEFINE temp-table TRelation
  FIELD owner      as character
  FIELD ref_table  as character
  FIELD field_name as character
  Index i0 owner ref_table.

define temp-table TFields NO-UNDO
  field pos as integer
  field field_name as character
  field field_label as character
  field dt as character
  field field_format as character
  field initial as character
  field flags as character
  field field_width as integer
  index i0 pos asc.

define temp-table TIndexes NO-UNDO
  field pos as integer
  field name as character
  field idesc as character
  field num_fields as integer
  field flags as character
  field fields_name as character
  index i0 pos.


define output parameter table for TableInfo.
define output parameter table for TTriggers.
define output parameter table for TRelation.
define output parameter table for TFields.
define output parameter table for TIndexes.

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


DEFINE BUFFER g_mfile    FOR system._File.
DEFINE BUFFER g_xfield   FOR system._Field.
DEFINE BUFFER g_xfile    FOR system._File.

find first system._File where system._File._File-Name = TableName NO-LOCK NO-ERROR.
if not available system._File then RETURN.

create TableInfo.
assign
  TableInfo.table_name  = system._File._File-Name
  TableInfo.table_label = system._File._File-Label
  TableInfo.sys         = system._File._Frozen
  TableInfo.dump_name   = system._File._Dump-name
  TableInfo.table_desc  = system._File._Desc
  TableInfo.valexp      = system._File._Valexp
  TableInfo.valmsg      = system._File._Valmsg.
if TableInfo.sys then 
do:
  TableInfo.valmsg = "".
  TableInfo.valexp = "".
end.

for each system._File-Trig of system._File NO-LOCK:
  create TTriggers.
  assign
    TTriggers.event     = system._File-Trig._Event
    TTriggers.proc_name = system._File-Trig._Proc-Name
    TTriggers.override  = system._File-Trig._Override.
  if system._File-trig._Trig-Crc <> 0 AND system._File-trig._Trig-Crc <> ? THEN 
    TTriggers.checkcrc = yes.
  else
    TTriggers.checkcrc = no.
  run LoadSrc (TTriggers.proc_name, OUTPUT TTriggers.ttext).
end.

FOR EACH system._Field OF system._File NO-LOCK:
  create TFields.
  assign
    TFields.pos          = system._Field._Order
    TFields.field_name   = system._Field._Field-name             
    TFields.field_label  = system._Field._Label
    TFields.dt           = system._Field._Data-Type
    TFields.field_format = system._Field._Format
    TFields.initial      = system._Field._Initial.
  TFields.flags =
      (IF system._Field._Fld-case THEN "c" ELSE "") +
      (IF CAN-FIND(FIRST system._Index-field OF system._Field) THEN "i" ELSE "") +
      (IF system._Field._Mandatory THEN "m" ELSE "") +
      (IF CAN-FIND(FIRST system._View-ref WHERE
                   system._View-ref._Ref-Table = system._File._File-name AND
                   system._View-ref._Base-col  = system._Field._Field-name)                    
      THEN "v" ELSE "").
  if TFields.dt = "decimal" then 
    TFields.dt = TFields.dt + "(" + string(system._Field._Decimals) + ")".
  if TableInfo.sys then TFields.field_format = "".
  run CalcFieldWidth (TFields.dt, TFields.field_format, OUTPUT TFields.field_width).
end.                                                                   

for each system._Index of system._File NO-LOCK:
  create TIndexes.

  find first system._Index-field where
      system._Index-field._Index-recid = RECID(system._Index) NO-LOCK NO-ERROR.
  TIndexes.flags = 
      (IF system._File._Prime-index = RECID(system._Index) THEN "p" ELSE "") +
      (IF system._Index._Unique                            THEN "u" ELSE "") +
      (IF system._Index._Wordidx = 1                       THEN "w" ELSE "") +
      (IF AVAILABLE system._Index-field 
          AND system._Index-field._Abbreviate              THEN "a" ELSE "") +
      (IF NOT system._Index._Active                        THEN "i" ELSE "").

  assign
    TIndexes.pos = system._Index._idx-num
    TIndexes.name = system._Index._Index-Name
    TIndexes.idesc = system._Index._Desc
    TIndexes.num_fields = system._Index._Num-comp.

  for each system._Index-field where
    system._Index-field._Index-recid = RECID(system._Index) NO-LOCK,
    first system._Field where
          system._Index-field._Field-recid = RECID(system._Field) NO-LOCK:

    TIndexes.fields_name = TIndexes.fields_name + 
      (IF system._Index-field._Ascending then "+ " else "- ") +
      _Field._Field-Name + " ".
  end.
  TIndexes.fields_name = TRIM(TIndexes.fields_name).
end.

/* Поиск связей между таблицами */
find first g_mfile where g_mfile._File-Name = TableName NO-LOCK NO-ERROR.
if not available g_mfile then RETURN.

/* для обычных */
FOR
    EACH system._Index       WHERE
         system._Index._Unique and 
         system._Index._Num-comp = 1, 
    EACH system._File        OF system._Index WHERE
         system._File._File-num > 0 /* and
         system._File._File-Name <> TableName */,
    EACH system._Index-field OF system._Index,
    EACH system._Field       OF system._Index-field NO-LOCK:

    FOR EACH g_xfield WHERE
             g_xfield._Field-name = system._Field._Field-name AND
             RECID(g_xfield) <> RECID(system._Field),
        EACH g_xfile OF g_xfield NO-LOCK:
      IF g_mfile._File-name <> system._File._File-name AND
         g_mfile._File-name <> g_xfile._File-name THEN NEXT.

      CREATE TRelation.
      ASSIGN
        TRelation.owner    = system._File._File-name
        TRelation.ref_table  = g_xfile._File-name
        TRelation.field_name = _Field._Field-name.
    END.
END.

/* для служебных таблиц, хранящих структуру БД */
FOR
  EACH system._File WHERE
       system._File._File-num <= 0 /* and
       system._File._File-Name <> TableName */ NO-LOCK:

    FOR EACH g_xfield of g_mfile WHERE
             g_xfield._Field-name = system._File._File-Name + "-recid":
      CREATE TRelation.
      ASSIGN
        TRelation.owner      = system._File._File-name
        TRelation.ref_table  = g_mfile._File-name
        TRelation.field_name = g_xfield._Field-name.
    END.
    FOR EACH system._Field OF system._File NO-LOCK:
      if system._Field._Field-name = TableName + "-recid" then
      do:
        CREATE TRelation.
        ASSIGN
          TRelation.owner      = g_mfile._File-name
          TRelation.ref_table  = system._File._File-name
          TRelation.field_name = system._Field._Field-name.
      end.
/*
      FOR EACH g_xfield of g_mfile WHERE
               g_xfield._Field-name = system._Field._Field-name:
        CREATE TRelation.
        ASSIGN
          TRelation.owner      = system._File._File-name
          TRelation.ref_table  = g_mfile._File-name
          TRelation.field_name = g_xfield._Field-name.
      END.
*/
    END.

END.
FOR EACH TRelation BREAK BY owner BY ref_table:
  IF NOT (FIRST-OF(ref_table) AND
          LAST-OF(ref_table)) THEN DELETE TRelation.
END.


PROCEDURE LoadSrc:
  define input parameter file-name as character.
  define output parameter file-text as character initial "".

  define variable line as character.

  if search(file-name) = ? then RETURN.
  input from value (file-name).
  repeat:
    import unformatted line.
    if file-text = "" then
      file-text = line.
    else
      file-text = file-text + chr(10) + line.
    if length (file-text) > 10000 then
    do:
      file-text = file-text + chr(10) + "........." + chr(10).
      leave.
    end.
  end.
  input close.
END.

PROCEDURE CalcFieldWidth:
  define input parameter dt as character.
  define input parameter fformat as character.
  define output parameter fwidth as integer.

  fformat = trim(fformat).
  if fformat = "" then
  do:
    if dt = "integer" or dt = "recid" or dt = "date" then fwidth = 10.
    if dt = "decimal" then fwidth = 15.
    if dt = "character" then fwidth = 30.
    if dt = "logical" then fwidth = 5.
    if dt = "datetime" or dt = "datetime-tz" then fwidth = 20.
  end.
  else do:
   if dt = "character" or dt = "logical" then
   do:
     if dt = "logical" then fwidth = 5.
     if fformat begins "X(" then fwidth = integer(entry(1,substring(fformat,3), ")")).
   end.
   else fwidth = length(fformat).
  end.
  if fwidth = 0 then fwidth = 15.
end.
