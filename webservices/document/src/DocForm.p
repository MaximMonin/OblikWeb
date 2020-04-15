/* Copyright (C) Maxim A. Monin 2009-2010 */

DEFINE TEMP-TABLE Frames NO-UNDO
  FIELD FrameKey        AS integer
  FIELD RidFrame        AS integer
  FIELD IsTable         AS LOGICAL
  FIELD N               AS INTEGER 
  FIELD PageN           AS INTEGER 
  FIELD FrameHeight     AS INTEGER
  FIELD FrameTitle      AS character
  INDEX i0 PageN asc N asc.

DEFINE TEMP-TABLE FrameFields NO-UNDO
  FIELD RidFF           AS integer
  FIELD FrameKey        AS integer
  FIELD RidFrame        AS integer
  FIELD FieldNum        as integer
  FIELD IsMandatory     AS LOGICAL
  FIELD IsLim           AS LOGICAL
  FIELD ViewOnly        AS LOGICAL
  FIELD IsSelect        AS LOGICAL
  FIELD IsAutoSelect    AS LOGICAL
  FIELD FieldCol        AS INTEGER
  FIELD FieldRow        AS INTEGER
  FIELD FieldWidth      AS INTEGER
  FIELD FieldHeight     AS INTEGER
  FIELD ColNumber       AS INTEGER
  FIELD AppendParam     AS CHARACTER
  FIELD BaseType        AS CHARACTER
  FIELD FieldFormat     AS CHARACTER
  FIELD FieldLabel      AS CHARACTER
  FIELD FieldAlign      AS CHARACTER
  FIELD ObjectType      AS CHARACTER
  FIELD ProgressType    AS CHARACTER
  FIELD HelpString      AS CHARACTER
  FIELD FreeEdit        as logical
  INDEX i1 IS PRIMARY FieldNum.


define input-output parameter DocsId as integer. /* CallBack Key */
define input-output parameter ContextId as character.

define input parameter RidTypeDoc as integer.
define output parameter TABLE for Frames.
define output parameter TABLE for FrameFields.

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

define variable recid-limit as integer.
define variable rid-form as integer.
define variable FrameKey as integer.
define variable N as integer.
define variable Ncount as integer.
define variable is-lim as logical.
define variable is-visible as logical.
define variable col-number as integer.

find first system.typedoc where system.typedoc.rid-typedoc = RidTypedoc NO-LOCK NO-ERROR.
if not available system.typedoc then RETURN.

RecID-limit = ?.
FOR EACH limittypedoc-cathg WHERE limittypedoc-cathg.rid-typedoc = RidTypedoc AND
  limittypedoc-cathg.rid-cathg = currid-cathg AND
  limittypedoc-cathg.rid-ent = ? NO-LOCK:
  RecID-limit = limittypedoc-cathg.rid-limit.
END.
FOR EACH limittypedoc-cathg WHERE limittypedoc-cathg.rid-typedoc = RidTypedoc AND
  limittypedoc-cathg.rid-cathg = currid-cathg AND
  limittypedoc-cathg.rid-ent = rid-ent NO-LOCK:
  RecID-limit = limittypedoc-cathg.rid-limit.
END.
FIND FIRST limittypedoc-cathg 
  WHERE limittypedoc-cathg.rid-limit = RecID-limit NO-LOCK NO-ERROR.
IF NOT AVAILABLE limittypedoc-cathg THEN RETURN.

rid-form = ?.
FIND FIRST doc-form WHERE doc-form.rid-form = limittypedoc-cathg.rid-form NO-LOCK NO-ERROR.
IF AVAILABLE doc-form THEN
  rid-form = doc-form.rid-form.

if rid-form = ? then
do:
  FOR EACH doc-frame WHERE doc-frame.rid-typedoc = RIdTypedoc  AND 
    NOT doc-frame.hidden NO-LOCK BY doc-frame.page-n BY doc-frame.number:

    FrameKey = doc-frame.rid-frame.

    CREATE Frames.
    ASSIGN
    Frames.FrameKey     = FrameKey
    Frames.RidFrame     = FrameKey
    Frames.IsTable      = (NOT doc-frame.type)
    Frames.N            = doc-frame.number
    Frames.PageN        = doc-frame.page-n
    Frames.FrameHeight  = doc-frame.Height - 2
    Frames.FrameTitle   = doc-frame.frame-title.

    col-number = 0.
    if Frames.IsTable then
    do:
      FOR EACH doc-frame-fields
            WHERE doc-frame-fields.rid-frame = FrameKey AND
                  doc-frame-fields.is-del = no NO-LOCK,
            EACH doc-data-type OF doc-frame-fields NO-LOCK,
            EACH basetype OF doc-data-type NO-LOCK
            BY doc-frame-fields.f-order:
        run AddField (yes).    
      end.
    end.
    else do:
      FOR EACH doc-frame-fields
            WHERE doc-frame-fields.rid-frame = FrameKey AND
                  doc-frame-fields.is-del = no NO-LOCK,
            EACH doc-data-type OF doc-frame-fields NO-LOCK,
            EACH basetype OF doc-data-type NO-LOCK
            BY doc-frame-fields.y BY doc-frame-fields.x:  
        run AddField (no).    
      end.
    end.
  END.
end.
else do:
  N = 0.
  for each doc-form-pages where doc-form-pages.rid-form = rid-form,
      each doc-form-frame where doc-form-frame.rid-form-pages = doc-form-pages.rid-form-pages
      by doc-form-frame.y:

    FrameKey = doc-form-frame.rid-form-frame.
    N = N + 1.
    CREATE Frames.
    ASSIGN
    Frames.FrameKey     = FrameKey
    Frames.IsTable      = (NOT doc-form-frame.type)
    Frames.N            = N
    Frames.PageN        = doc-form-pages.page-n
    Frames.FrameHeight  = doc-form-frame.height - 2
    Frames.FrameTitle   = doc-form-frame.frame-title.

    col-number = 0.
    if Frames.IsTable then
    do:
      for each doc-form-fields where doc-form-fields.rid-form-frame = FrameKey NO-LOCK,
          each doc-frame-fields where doc-frame-fields.rid-ff = doc-form-fields.rid-ff NO-LOCK,
          EACH doc-data-type OF doc-frame-fields NO-LOCK,
          EACH basetype OF doc-data-type NO-LOCK
          BY doc-form-fields.f-order:  
        Frames.RidFrame = doc-frame-fields.rid-frame.
        run AddField2 (yes).
      end.
    end.
    else do:
      for each doc-form-fields where doc-form-fields.rid-form-frame = FrameKey NO-LOCK,
          each doc-frame-fields where doc-frame-fields.rid-ff = doc-form-fields.rid-ff NO-LOCK,
          EACH doc-data-type OF doc-frame-fields NO-LOCK,
          EACH basetype OF doc-data-type NO-LOCK
          BY doc-form-fields.y BY doc-form-fields.x:  
        run AddField2 (no).
      end.
    end.      
  end.
end.

PROCEDURE AddField:
  define input parameter is-table as logical.
  is-lim = FALSE.
  is-visible = TRUE.    
      
  IF RecID-limit <> ? THEN
  DO:
    FIND FIRST field-limit 
               WHERE field-limit.rid-limit = RecID-limit AND
               field-limit.rid-ff = doc-frame-fields.rid-ff NO-LOCK NO-ERROR.

    IF AVAILABLE field-limit THEN
    DO:
      IF field-limit.limit THEN
        is-visible = FALSE.
      ELSE  
        is-lim     = TRUE.
    END.
  END.
  
  IF NOT is-visible THEN
   NEXT.

  col-number = col-number + 1.

  create FrameFields.
  assign
   FrameFields.FrameKey      = FrameKey
   FrameFields.RidFrame      = doc-frame-fields.rid-frame
   FrameFields.objecttype    = doc-frame-fields.objecttype
   FrameFields.FieldCol      = doc-frame-fields.x 
   FrameFields.FieldRow      = doc-frame-fields.y
   FrameFields.FieldWidth    = doc-frame-fields.width
   FrameFields.FieldHeight   = doc-frame-fields.height
   FrameFields.FieldLabel    = doc-frame-fields.field-label
   FrameFields.ColNumber     = col-number
   FrameFields.ProgressType  = basetype.progress-type
   FrameFields.RidFF         = doc-frame-fields.rid-ff
   FrameFields.BaseType      = doc-data-type.base-type
   FrameFields.IsMandatory   = doc-frame-fields.is-mandatory
   FrameFields.HelpString    = doc-frame-fields.help-string
   FrameFields.FieldFormat   = doc-frame-fields.field-format
   FrameFields.ViewOnly      = doc-frame-fields.view-only
   FrameFields.AppendParam   = doc-frame-fields.append-param
   FrameFields.IsSelect      = basetype.is-select
   FrameFields.IsAutoSelect  = doc-frame-fields.is-autoselect
   FrameFields.FieldNum      = Ncount
   FrameFields.IsLim         = is-lim.

  if is-table then
    FrameFields.FieldWidth    = 
      max(FrameFields.FieldWidth,length(FrameFields.FieldLabel)).

  FrameFields.FieldAlign = "left".
  if system.basetype.right-align then
    FrameFields.FieldAlign = "right".
  if system.doc-data-type.base-type = "LOGICAL" and is-table then
  do:
    FrameFields.FieldAlign = "center".
  end.
  if system.doc-data-type.base-type = "LOGICAL" then
    FrameFields.objecttype = "Переключатель".
  if system.doc-data-type.base-type = "SIGNATURE" then
   FrameFields.IsSelect      = true.

  FrameFields.FreeEdit = false.
  if doc-data-type.base-type = "CAR2" or doc-data-type.base-type = "CAR-MARK2" or 
     doc-data-type.base-type = "CHARACTER" or doc-data-type.base-type = "DIRTOPIC" or
     doc-data-type.base-type = "DIRTOPI2" or doc-data-type.base-type = "SERIES" or 
     doc-data-type.base-type = "SERIESDT" or doc-data-type.base-type = "SERIESWH" or
     doc-data-type.base-type = "TIMETYPE"
  then 
    FrameFields.FreeEdit = true.
  if FrameFields.ProgressType = "INTEGER" or FrameFields.ProgressType = "DECIMAL" or 
     FrameFields.ProgressType = "DATE" or doc-data-type.base-type = "TIME" then
    FrameFields.FreeEdit = true.

  Ncount = Ncount + 1.
END.

PROCEDURE AddField2:
  define input parameter is-table as logical.
  is-lim = FALSE.
  is-visible = TRUE.    
  
  IF RecID-limit <> ? THEN
  DO:
    FIND FIRST field-limit 
               WHERE field-limit.rid-limit = RecID-limit AND
               field-limit.rid-ff = doc-frame-fields.rid-ff NO-LOCK NO-ERROR.

    IF AVAILABLE field-limit THEN
    DO:
      IF field-limit.limit THEN
        is-visible = FALSE.
      ELSE  
        is-lim     = TRUE.
    END.
  END.
  
  IF NOT is-visible THEN
   NEXT.

  col-number = col-number + 1.

  create FrameFields.
  assign
   FrameFields.FrameKey      = FrameKey
   FrameFields.RidFrame      = doc-frame-fields.rid-frame
   FrameFields.objecttype    = doc-frame-fields.objecttype
   FrameFields.FieldCol      = doc-form-fields.x 
   FrameFields.FieldRow      = doc-form-fields.y
   FrameFields.FieldWidth    = doc-form-fields.width
   FrameFields.FieldHeight   = doc-form-fields.height
   FrameFields.FieldLabel    = doc-frame-fields.field-label
   FrameFields.ColNumber     = col-number
   FrameFields.ProgressType  = basetype.progress-type
   FrameFields.RidFF         = doc-frame-fields.rid-ff
   FrameFields.BaseType      = doc-data-type.base-type
   FrameFields.IsMandatory   = doc-frame-fields.is-mandatory
   FrameFields.HelpString    = doc-frame-fields.help-string
   FrameFields.FieldFormat   = doc-frame-fields.field-format
   FrameFields.ViewOnly      = doc-frame-fields.view-only
   FrameFields.AppendParam   = doc-frame-fields.append-param
   FrameFields.IsSelect      = basetype.is-select
   FrameFields.IsAutoSelect  = doc-frame-fields.is-autoselect
   FrameFields.FieldNum      = Ncount
   FrameFields.IsLim         = is-lim.

  if is-table then
    FrameFields.FieldWidth    = 
      max(FrameFields.FieldWidth,length(FrameFields.FieldLabel)).

  FrameFields.FieldAlign = "left".
  if system.basetype.right-align then
    FrameFields.FieldAlign = "right".
  if system.doc-data-type.base-type = "LOGICAL" and is-table then
  do:
    FrameFields.FieldAlign = "center".
  end.
  if system.doc-data-type.base-type = "LOGICAL" then
    FrameFields.objecttype = "Переключатель".
  if system.doc-data-type.base-type = "SIGNATURE" then
   FrameFields.IsSelect      = true.

  FrameFields.FreeEdit = false.
  if doc-data-type.base-type = "CAR2" or doc-data-type.base-type = "CAR-MARK2" or 
     doc-data-type.base-type = "CHARACTER" or doc-data-type.base-type = "DIRTOPIC" or
     doc-data-type.base-type = "DIRTOPI2" or doc-data-type.base-type = "SERIES" or 
     doc-data-type.base-type = "SERIESDT" or doc-data-type.base-type = "SERIESWH" or
     doc-data-type.base-type = "TIMETYPE"
  then 
    FrameFields.FreeEdit = true.
  if FrameFields.ProgressType = "INTEGER" or FrameFields.ProgressType = "DECIMAL" or 
     FrameFields.ProgressType = "DATE" or doc-data-type.base-type = "TIME" then
    FrameFields.FreeEdit = true.

  Ncount = Ncount + 1.
END.
