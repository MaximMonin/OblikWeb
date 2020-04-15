/* Copyright (C) Maxim A. Monin 2009-2010 */

/* Получить список документов по сложному фильтру */

define Temp-Table CollumnData NO-UNDO
  field IdField as integer
  field fLabel as character
  field fName as character
  field fWidth as integer
  field fType as character
  field fAlign as character
  index i0 IdField asc.

define input-output parameter DocsId as integer. /* CallBack Key */
define input-output parameter ContextId as character.

define input parameter PutOff as logical.
define input parameter RidApp as integer.
define input parameter RidTypedoc as integer.
define input parameter DateFrom as date.
define input parameter DateTo as date.
define input parameter Scope as character.
define input parameter IdDocument as integer.
define input parameter RidDocument as integer.
define input parameter MaxRecCount as integer.
define input parameter DocFilterParams as character.
define input parameter FieldFilterParams as character.

define input parameter SortBy as character.

define output parameter TABLE for CollumnData.
define output parameter TABLE-HANDLE DocumentData.

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

/*
output to 1.txt.
put unformatted DocFilterParams skip.
put unformatted FieldFilterParams skip.
output close.
*/

define variable l as integer.
if lang begins "ru" then
  l = 1.
else
  l = 2.


define variable i as integer.
define variable j as integer.
define variable fieldcount as integer.
define variable rid-ff as integer.
define variable numfiles as integer.
define variable cur-scope as integer.
define variable Recid-User as integer.
DEFINE variable hQuery           AS HANDLE NO-UNDO.
DEFINE variable hBuffer          AS HANDLE NO-UNDO.
DEFINE VARIABLE hBufferField     AS HANDLE NO-UNDO.

DEF TEMP-TABLE vis-divisions NO-UNDO
 FIELD rid-div AS INTEGER
 INDEX rid-div IS PRIMARY UNIQUE rid-div.
def Temp-Table Dates NO-UNDO
 Field d as date
 index i0 d.

find first system.typedoc where system.typedoc.rid-typedoc = RidTypedoc NO-LOCK NO-ERROR.
if not available system.typedoc then RidTypedoc = ?.
find first system.applicat where system.applicat.rid-app = RidApp NO-LOCK NO-ERROR.
if not available system.applicat then RidApp = ?.
if IdDocument <= 0 then IdDocument = ?.
if RidDocument <= 0 then RidDocument = ?.
if MaxRecCount > 10000 then MaxRecCount = 10000.

if DateFrom = ? then
  DateFrom = Date ("01/01/0001").
if DateTo = ? then
  DateTo = Date ("31/12/9999").


cur-scope = -1.
FOR EACH system.doc-scope where system.doc-scope.name-scope = Scope or STRING(system.doc-scope.nmb-scope) = Scope NO-LOCK:
   cur-scope = system.doc-scope.nmb-scope.
end.

create temp-table DocumentData.

DocumentData:ADD-NEW-FIELD ("DateDoc",   "date"). 
DocumentData:ADD-NEW-FIELD ("TypedocName", "Character"). 
DocumentData:ADD-NEW-FIELD ("IdDoc",      "INTEGER"). 
DocumentData:ADD-NEW-FIELD ("SumDoc",     "decimal"). 
DocumentData:ADD-NEW-FIELD ("Error",      "Logical"). 
DocumentData:ADD-NEW-FIELD ("KeepDoc",    "Logical"). 
DocumentData:ADD-NEW-FIELD ("NeedToCalc", "Logical"). 
DocumentData:ADD-NEW-FIELD ("Exect",      "Logical"). 
DocumentData:ADD-NEW-FIELD ("filled",     "Logical"). 
DocumentData:ADD-NEW-FIELD ("Descr",      "Character"). 
DocumentData:ADD-NEW-FIELD ("App",        "Character"). 
DocumentData:ADD-NEW-FIELD ("Division",   "Character"). 
DocumentData:ADD-NEW-FIELD ("DocFiles",   "integer"). 
DocumentData:ADD-NEW-FIELD ("RidDocument","integer"). 
DocumentData:ADD-NEW-FIELD ("RidTypedoc" ,"integer"). 

/* Умалчиваемая сортировка */
DocumentData:ADD-NEW-INDEX("i0", false, true).
if RidTypedoc = ? then
do:
  DocumentData:ADD-INDEX-FIELD("i0","App").
  DocumentData:ADD-INDEX-FIELD("i0","DateDoc").
  DocumentData:ADD-INDEX-FIELD("i0","TypedocName").
  DocumentData:ADD-INDEX-FIELD("i0","IdDoc").
end.
else do:
  DocumentData:ADD-INDEX-FIELD("i0","DateDoc").
  DocumentData:ADD-INDEX-FIELD("i0","IdDoc").
end.



create CollumnData. i = 1.
assign IdField = i fLabel = ENTRY(l,"Дата,Date") fName = "DateDoc" fWidth = 10 fType = "date" fAlign = "center".
if RidTypedoc = ? then
do:
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Тип документа,Document type") fName = "TypedocName" fWidth = 20 fType = "Text" fAlign = "left".
end.
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Номер,Number") fName = "IdDoc" fWidth = 6 fType = "Text" fAlign = "right".
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Сумма,Sum") fName = "SumDoc" fWidth = 13 fType = "Text" fAlign = "right".
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Содержание,Description") fName = "Descr" fWidth = 30 fType = "Text" fAlign = "left".

define variable RecID-limit as integer.
if RidTypedoc <> ? then
do:
  RecID-limit = ?.
  FOR EACH system.limittypedoc-cathg WHERE system.limittypedoc-cathg.rid-typedoc = RidTypedoc AND
                                           system.limittypedoc-cathg.rid-cathg = currid-cathg AND
                                           system.limittypedoc-cathg.rid-ent = ? NO-LOCK:
    RecID-limit = system.limittypedoc-cathg.rid-limit.
  END.
  FOR EACH system.limittypedoc-cathg WHERE system.limittypedoc-cathg.rid-typedoc = RidTypedoc AND
                                           system.limittypedoc-cathg.rid-cathg = currid-cathg AND
                                           system.limittypedoc-cathg.rid-ent = rid-ent NO-LOCK:
    RecID-limit = system.limittypedoc-cathg.rid-limit.
  END.
  FIND FIRST system.limittypedoc-cathg WHERE
             system.limittypedoc-cathg.rid-limit = RecID-limit NO-LOCK NO-ERROR.
  IF AVAILABLE system.limittypedoc-cathg THEN
  do:

    FOR EACH system.doc-browse
      WHERE system.doc-browse.rid-typedoc = RidTypedoc NO-LOCK,
      EACH system.doc-frame-fields OF system.doc-browse NO-LOCK,
      EACH system.doc-data-type OF system.doc-frame-fields NO-LOCK,
      EACH system.basetype OF system.doc-data-type NO-LOCK
      BY system.doc-browse.number: 
  
      Find First system.field-limit 
        WHERE system.field-limit.rid-limit = RecID-limit AND
              system.field-limit.rid-ff = system.doc-frame-fields.rid-ff 
              NO-LOCK NO-ERROR.
      IF AVAILABLE system.field-limit AND system.field-limit.limit = true then NEXT.
      DocumentData:ADD-NEW-FIELD ("Field" + string(system.doc-frame-fields.rid-ff), "CHARACTER"). 
      create CollumnData. i = i + 1.
      assign 
        IdField = i 
        fLabel = system.doc-browse.field-label 
        fName = "Field" + string(system.doc-frame-fields.rid-ff)
        fWidth = system.doc-browse.width
	fType = "Text" 
	fAlign = "left".
      if system.basetype.right-align then
        CollumnData.fAlign = "right".
      if system.doc-data-type.base-type = "LOGICAL" then
      do:
        CollumnData.fType = "box".
        CollumnData.fAlign = "center".
      end.
      if system.doc-data-type.base-type = "DATE" then
      do:
        CollumnData.fType = "date".
      end.

    END.
  end.
END.

create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Ош,Err") fName = "Error" fWidth = 3 fType = "box" fAlign = "center".
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Хр,RO") fName = "KeepDoc" fWidth = 3 fType = "box" fAlign = "center".
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Пер,Calc") fName = "NeedToCalc" fWidth = 3 fType = "box" fAlign = "center".
create CollumnData. i = i + 1.
assign IdField = i fLabel = Entry(l,"Исп,Exec") fName = "Exect" fWidth = 3 fType = "box" fAlign = "center".
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Зп,Filled") fName = "filled" fWidth = 3 fType = "box" fAlign = "center".
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Прил.,Appl") fName = "App" fWidth = 5 fType = "Text" fAlign = "left".
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Подр.,Divis") fName = "Division" fWidth = 6 fType = "Text" fAlign = "left".
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Файлы,Files") fName = "DocFiles" fWidth = 5 fType = "Text" fAlign = "right".
create CollumnData. i = i + 1.
assign IdField = i fLabel = ENTRY(l,"Вн.номер,Int.number") fName = "RidDocument" fWidth = 8 fType = "Text" fAlign = "right".

DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
CREATE QUERY hQuery.
hQuery:SET-BUFFERS(hBuffer).
fieldcount = hBuffer:NUM-FIELDS.

if cur-scope < 0 then RETURN.
if RidTypedoc <> ? then /* Поправляю даты по правам на документы и заодно запоминаю последний запрос и зоны вилимости */
do:
  RUN src/kernel/setusdt.p ( RidTypedoc, INPUT-OUTPUT cur-scope, INPUT-OUTPUT DateFrom, INPUT-OUTPUT DateTo ).
end.

Find First system.users WHERE system.users.sys-name = uid NO-LOCK NO-ERROR. 
if not available system.users then RETURN.
Find First system.cathg WHERE system.cathg.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
if not available system.cathg then RETURN.

CASE cur-scope :
 WHEN 0
  then do:
    RecID-user = system.users.rid-user.
    CREATE vis-divisions.
    vis-divisions.rid-div = system.cathg.rid-division.
  end.
 WHEN 1
  then do:
   RecID-user = ?.
   FOR EACH system.ctg-division NO-LOCK :
    RUN src/system/reldivis.p ( system.cathg.rid-division, system.ctg-division.rid-division ).
    IF RETURN-VALUE = "PARENT" OR RETURN-VALUE = "EQUAL"
     then do:
      CREATE vis-divisions.
      vis-divisions.rid-div = system.ctg-division.rid-division.
     end. 
   END.
  end.
 WHEN 2
  then do:
   RecID-user = ?.
   FOR EACH system.ctg-division NO-LOCK :
    CREATE vis-divisions.
    vis-divisions.rid-div = system.ctg-division.rid-division.
   END.
  end. 

  WHEN 3 THEN
  DO:
    RecID-user = ?.
    FOR EACH system.ctg-divisions WHERE system.ctg-divisions.rid-cathg = currid-cathg NO-LOCK :
      CREATE vis-divisions.
      ASSIGN
        vis-divisions.rid-div = system.ctg-divisions.rid-division.
    END.
  END.
END CASE. 

define variable list-condfields AS CHARACTER INITIAL "" NO-UNDO.
define variable list-filters AS CHARACTER INITIAL "" NO-UNDO.
define variable fld AS CHARACTER NO-UNDO.
define variable rid-doc AS INTEGER.
define variable DocValues as character.

if NUM-ENTRIES (DocFilterParams, "^")  > 1 then
do:
  DocValues = ENTRY (2, DocFilterParams, "^").
  DocFilterParams = ENTRY (1, DocFilterParams, "^").
end.
if DocFilterParams <> "" and NUM-ENTRIES(DocFilterParams) = NUM-ENTRIES (DocValues) and 
   RidTypedoc <> ? then
do:
  do i = 1 to NUM-ENTRIES (DocFilterParams):
    rid-ff = INTEGER(ENTRY(i, DocFilterParams)).
    run src/kernel/ridtoff.p ( rid-ff ).
    fld = RETURN-VALUE.
    if list-condfields = "" then list-condfields = fld.
    else list-condfields = list-condfields + "^" + fld.

    run src/kernel/strtofld.p ( rid-ff, ENTRY(i, DocValues) ).
    if list-filters = "" then list-filters = RETURN-VALUE.
    else list-filters = list-filters + "^" + RETURN-VALUE.
  end.

  Find First system.typedoc WHERE system.typedoc.rid-typedoc = RidTypedoc NO-LOCK.
  run src/kernel/getfrddc1.p ( system.typedoc.id-typedoc, DateFrom, DateTo,
   list-condfields, list-filters, "", OUTPUT rid-doc ). 

  for each querydoc USE-INDEX num, 
      each system.document WHERE system.document.rid-document = querydoc.riddoc NO-LOCK,
      EACH system.applicat OF system.document NO-LOCK,
      EACH system.ctg-division OF system.document NO-LOCK,
      EACH system.typedoc OF system.document NO-LOCK,
      EACH vis-divisions WHERE system.document.rid-division = vis-divisions.rid-div:

    if system.document.put-off = PutOff
/*
      AND system.document.rid-ent = rid-ent
      AND system.document.date-doc >= DateFrom
      AND system.document.date-doc <= DateTo
      AND (system.document.rid-typedoc = RidTypedoc OR RidTypedoc = ?)
*/
      AND (system.document.rid-app = RidApp OR RidApp = ?)
      AND (system.document.id-document = IdDocument OR IdDocument = ?)
      AND (system.document.rid-document = RidDocument OR RidDocument = ?) 
      AND (system.document.close-doc = RecID-user OR RecID-user = ? ) then
    do:

      if MaxRecCount <= 0 then leave.
      MaxRecCount = MaxRecCount - 1.
    
      run AddRecord.
    end.
  end.
  RETURN.
end.


if RidDocument <> ? then
do:
  FOR EACH system.document NO-LOCK where system.document.rid-document = RidDocument,
    EACH system.applicat OF system.document NO-LOCK,
    EACH system.ctg-division OF system.document NO-LOCK,
    EACH system.typedoc OF system.document NO-LOCK,
    EACH vis-divisions WHERE system.document.rid-division = vis-divisions.rid-div:

    if system.document.put-off = PutOff
     AND system.document.rid-ent = rid-ent
     AND (system.document.rid-typedoc = RidTypedoc OR RidTypedoc = ?)
     AND (system.document.rid-app = RidApp OR RidApp = ? )
     AND (system.document.id-document = IdDocument OR IdDocument = ? )
     AND (system.document.close-doc = RecID-user OR RecID-user = ? )
     AND system.document.date-doc >= DateFrom
     AND system.document.date-doc <= DateTo then
    do:
      if MaxRecCount <= 0 then leave.
      MaxRecCount = MaxRecCount - 1.

      run AddRecord.
    end.
  END.
  RETURN.
END.
if IdDocument <> ? then
do:
  FOR EACH system.document NO-LOCK where system.document.id-document = idDocument,
    EACH system.applicat OF system.document NO-LOCK,
    EACH system.ctg-division OF system.document NO-LOCK,
    EACH system.typedoc OF system.document NO-LOCK,
    EACH vis-divisions WHERE system.document.rid-division = vis-divisions.rid-div:

    if system.document.put-off = PutOff
     AND system.document.rid-ent = rid-ent
     AND (system.document.rid-typedoc = RidTypedoc OR RidTypedoc = ?)
     AND (system.document.rid-app = RidApp OR RidApp = ? )
     AND (system.document.close-doc = RecID-user OR RecID-user = ? )
     AND system.document.date-doc >= DateFrom
     AND system.document.date-doc <= DateTo then
    do:
      if MaxRecCount <= 0 then leave.
      MaxRecCount = MaxRecCount - 1.

      run AddRecord.
    end.
  END.
  RETURN.
END.


if DateFrom > DATE ("01/01/0001") then
  DateFrom = DateFrom - 1.
if DateTo <> DATE (12,31,9999) then
  DateTo = DateTo + 1.

define variable sQuery as character.
DEFINE VARIABLE hQueryData  AS HANDLE   NO-UNDO.
DEFINE VARIABLE hbuf AS HANDLE NO-UNDO.

define buffer document2 for system.document.
define buffer typedoc2 for system.typedoc.
define buffer applicat2 for system.applicat.
define buffer ctg-division2 for system.ctg-division.
define buffer vis-divisions2 for vis-divisions.

sQuery = "FOR EACH document2 use-index i-id NO-LOCK where ".
sQuery = sQuery + " document2.put-off = " + STRING (PutOff).
sQuery = sQuery + " AND document2.rid-ent = " + STRING (rid-ent).
IF RidTypedoc <> ? THEN
  sQuery = sQuery + " AND document2.rid-typedoc = " + STRING (RidTypedoc).
IF RidApp <> ? THEN
  sQuery = sQuery + " AND document2.rid-app = " + STRING (RidApp).
sQuery = sQuery + " AND document2.date-doc > DATE('" + STRING (DateFrom, "99/99/9999") + "')" +
                  " AND document2.date-doc < DATE('" + STRING (DateTo, "99/99/9999") + "')".
IF RecID-user <> ? THEN
  sQuery = sQuery + " AND document2.close-doc = " + STRING (RecID-user).
sQuery = sQuery + ", EACH applicat2 OF document2 NO-LOCK, " +
     " EACH ctg-division2 OF document2 NO-LOCK, " + 
     " EACH typedoc2 OF document2 NO-LOCK, " +
     " EACH vis-divisions2 WHERE document2.rid-division = vis-divisions2.rid-div".

CREATE QUERY hQueryData.
hQueryData:FORWARD-ONLY = true.
hQueryData:SET-BUFFERS (BUFFER document2:HANDLE,
                        BUFFER applicat2:HANDLE,
                        BUFFER ctg-division2:HANDLE,
                        BUFFER typedoc2:HANDLE,
                        BUFFER vis-divisions2:HANDLE).
hQueryData:QUERY-PREPARE(sQuery).
hQueryData:QUERY-OPEN. 
hQueryData:GET-FIRST ().

repeat:
  if hQueryData:QUERY-OFF-END then leave.

  MaxRecCount = MaxRecCount - 1.
  if MaxRecCount < 0 then leave.

  run AddRecord2.

  hQueryData:GET-NEXT ().
END.
RETURN.

PROCEDURE AddRecord:
  hBuffer:BUFFER-CREATE().

  hBuffer:BUFFER-FIELD("IdDoc"):BUFFER-VALUE = system.document.id-document.
  hBuffer:BUFFER-FIELD("DateDoc"):BUFFER-VALUE = system.document.date-doc.
  hBuffer:BUFFER-FIELD("SumDoc"):BUFFER-VALUE = system.document.sum-doc.
  hBuffer:BUFFER-FIELD("Error"):BUFFER-VALUE = system.document.error.
  hBuffer:BUFFER-FIELD("KeepDoc"):BUFFER-VALUE = system.document.keep-doc.
  hBuffer:BUFFER-FIELD("NeedToCalc"):BUFFER-VALUE = system.document.NeedToCalc.
  hBuffer:BUFFER-FIELD("Exect"):BUFFER-VALUE = system.document.exect.
  hBuffer:BUFFER-FIELD("filled"):BUFFER-VALUE = system.document.filled.
  hBuffer:BUFFER-FIELD("Descr"):BUFFER-VALUE = system.document.descr-opr.
  hBuffer:BUFFER-FIELD("App"):BUFFER-VALUE = system.applicat.compres-name.
  hBuffer:BUFFER-FIELD("Division"):BUFFER-VALUE = system.ctg-division.code-division.
  hBuffer:BUFFER-FIELD("RidDocument"):BUFFER-VALUE = system.document.rid-document.
  hBuffer:BUFFER-FIELD("RidTypedoc"):BUFFER-VALUE = system.document.rid-typedoc.
  hBuffer:BUFFER-FIELD("TypedocName"):BUFFER-VALUE = "(" + STRING(system.typedoc.id-typedoc) + ") " + system.typedoc.name-typedoc.

  numfiles = 0.
  for each system.doc-files NO-LOCK WHERE system.doc-files.rid-file-list = system.document.rid-file-list:
    numfiles = numfiles + 1.
  end.
  hBuffer:BUFFER-FIELD("DocFiles"):BUFFER-VALUE = numfiles.

  if RidTypedoc <> ? then
  do:
    DO j = 1 TO fieldcount:
      hBufferField = hBuffer:BUFFER-FIELD(j).
      if hBufferField:Name begins "Field" then
      do:
        rid-ff = integer(substring (hBufferField:Name,6)).
        FIND system.doc-field-data WHERE system.doc-field-data.rid-document = system.document.rid-document 
          AND system.doc-field-data.rid-ff = rid-ff NO-LOCK NO-ERROR.
        IF AVAILABLE system.doc-field-data then
        do: 
  	  run src/kernel/strtofrm.p ( rid-ff, system.doc-field-data.field-value, "" ).
          hBufferField:BUFFER-VALUE = RETURN-VALUE.
        end.
        else
          hBufferField:BUFFER-VALUE = "".
      end.
    END.
  end.
END.

PROCEDURE AddRecord2:
  hBuffer:BUFFER-CREATE().

  hBuffer:BUFFER-FIELD("IdDoc"):BUFFER-VALUE = document2.id-document.
  hBuffer:BUFFER-FIELD("DateDoc"):BUFFER-VALUE = document2.date-doc.
  hBuffer:BUFFER-FIELD("SumDoc"):BUFFER-VALUE = document2.sum-doc.
  hBuffer:BUFFER-FIELD("Error"):BUFFER-VALUE = document2.error.
  hBuffer:BUFFER-FIELD("KeepDoc"):BUFFER-VALUE = document2.keep-doc.
  hBuffer:BUFFER-FIELD("NeedToCalc"):BUFFER-VALUE = document2.NeedToCalc.
  hBuffer:BUFFER-FIELD("Exect"):BUFFER-VALUE = document2.exect.
  hBuffer:BUFFER-FIELD("filled"):BUFFER-VALUE = document2.filled.
  hBuffer:BUFFER-FIELD("Descr"):BUFFER-VALUE = document2.descr-opr.
  hBuffer:BUFFER-FIELD("App"):BUFFER-VALUE = applicat2.compres-name.
  hBuffer:BUFFER-FIELD("Division"):BUFFER-VALUE = ctg-division2.code-division.
  hBuffer:BUFFER-FIELD("RidDocument"):BUFFER-VALUE = document2.rid-document.
  hBuffer:BUFFER-FIELD("RidTypedoc"):BUFFER-VALUE = document2.rid-typedoc.
  hBuffer:BUFFER-FIELD("TypedocName"):BUFFER-VALUE = "(" + STRING(typedoc2.id-typedoc) + ") " + typedoc2.name-typedoc.

  numfiles = 0.
  for each system.doc-files NO-LOCK WHERE system.doc-files.rid-file-list = document2.rid-file-list:
    numfiles = numfiles + 1.
  end.
  hBuffer:BUFFER-FIELD("DocFiles"):BUFFER-VALUE = numfiles.

  if RidTypedoc <> ? then
  do:
    DO j = 1 TO fieldcount:
      hBufferField = hBuffer:BUFFER-FIELD(j).
      if hBufferField:Name begins "Field" then
      do:
        rid-ff = integer(substring (hBufferField:Name,6)).
        FIND system.doc-field-data WHERE system.doc-field-data.rid-document = document2.rid-document 
          AND system.doc-field-data.rid-ff = rid-ff NO-LOCK NO-ERROR.
        IF AVAILABLE system.doc-field-data then
        do: 
  	  run src/kernel/strtofrm.p ( rid-ff, system.doc-field-data.field-value, "" ).
          hBufferField:BUFFER-VALUE = RETURN-VALUE.
        end.
        else
          hBufferField:BUFFER-VALUE = "".
      end.
    END.
  end.
END.
