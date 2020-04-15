/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input-output parameter RidDoc    as integer.
define input-output parameter ViewOnly  as logical.
define input-output parameter RidTypedoc as integer.
define input parameter NewDoc           as logical.
define input parameter PutOff           as logical.
define input parameter RidMainDoc       as integer.
define input parameter EditMode         as character.
define output parameter OutMessage      as character initial "".
define output parameter ViewReason      as character initial "".

/* Security + инициализация глобальных переменных */
{connect.i}
{oblik.i}

SESSION:SUPPRESS-WARNINGS = TRUE.

define variable l as integer.
l = 1.

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-LOCK NO-ERROR.
if not available webdb.Context then
do:
  pause 1.                                 
  OutMessage = ENTRY(l, "Ошибка обмена данными,Data exchange error").
  return.
end.
run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId, no).
if return-value <> "" then
do:
  pause 1.
  OutMessage = ENTRY(l, "Ошибка обмена данными,Data exchange error").
  return.
end.
run webservices/main/src/InitGlobalVars.p (ContextId).
/* /Security + инициализация глобальных переменных */

if lang begins "ru" then
  l = 1.
else
  l = 2.


&Scoped-define ON-NEW-DOCUMENT        1
&Scoped-define ON-INTEGRITY           2
&Scoped-define ON-CLOSE-DOCUMENT      3
&Scoped-define ON-MODIFY              4
&Scoped-define ON-DELETE-DOCUMENT     5
&Scoped-define ON-PRINT-DOCUMENT      6
&Scoped-define ON-BUSINESS-PROCESS    7
&Scoped-define ON-AFTER-CLOSE         8
&Scoped-define ON-AFTER-SELECT        9
&Scoped-define ON-ADD-LINE           10
&Scoped-define ON-DELETE-LINE        11
&Scoped-define ON-BEFORE-ADD-LINE    12
&Scoped-define ON-BEFORE-DEL-LINE    13
&Scoped-define ON-CHOOSE             14
&Scoped-define ON-GETCONTEXT         15
&Scoped-define ON-BEFORE-PRINT       16
&Scoped-define ON-BARCODE            17
&Scoped-define ON-GETAPPENDINFO      18
&Scoped-define BEFORE-CLOSE-DOCUMENT 19
&Scoped-define ON-COPY-DOCUMENT      22
&Scoped-define ON-ROW-SELECT         23
&Scoped-define ON-CHANGE-DOCSTATUS   24
&Scoped-define ON-CHANGE-TASKSTATUS  25
&Scoped-define ON-RUNMOBILETASK      26
&Scoped-define ON-FOCUS-CHANGE       27
&Scoped-define ON-FAST-CLOSE         28
&Scoped-define ON-TIMER              29

DEFINE NEW SHARED VARIABLE put-off AS LOGICAL.

/* ================================================================================================== */
/* Переменные */

define variable cash-only as logical.    /* Режим работы с кеш-документом */
define variable v-only as logical.       /* Режим работы только на просмотр */
define variable rid-doc as integer.      /* Внутренняя ссылка на документ */
define variable rid-typedoc as integer.  /* Вид документа */
define variable isnew as logical.        /* Новый документ */
define variable saved as logical.        /* Сохранен */
define variable eMode as character.      /* Режим редактирования */
define variable NeedSave as logical.     /* Признак изменения данных документа */
/*
define variable ViewReason as character. /* Причина, по которой документ только на просмотр */
*/

define variable maxright as integer.
define variable temp-rowid as rowid.
define variable TransObj as handle. /* Текущая транзакция */
define variable ContextId2 as character.

if RidMainDoc = 0 then RidMainDoc = ?.
put-off = PutOff.
TransObj = THIS-PROCEDURE:Transaction.
ContextId2 = ContextId.

/* EditMode - режим редактирования/создания документов
   "" - обычное создание нового документа из списка документов
   "COPY" - создание документа, путем операции копирования из существующего
   "REPORT" - создание отчета
   "SERVDOC" - создание пользовательской утилиты (сервисного документа)
   "TEST" - создание документа в режиме тестирования
*/

if NewDoc then
do:
  RidDoc = ?.
  RUN src/kernel/gmaxrigh.p ( RidTypedoc ).
  maxright = INTEGER(RETURN-VALUE).
  IF maxright < 2 and EditMode <> "TEST" or 
     ((EditMode = "" or EditMode = "COPY" or EditMode = "SERVDOC") and ViewOnly) then
  do:
    if EditMode = "" or EditMode = "COPY" then
      OutMessage = ENTRY(l, "У вас нет прав на создание нового документа,You dont have a right to create new document").
    if EditMode = "SERVDOC" then
      OutMessage = ENTRY(l, "У Вас нет прав на запуск процедуры,You dont have a right to run this procedure").
    if EditMode = "REPORT" and maxright < 1 then
      OutMessage = ENTRY(l,"У вас нет прав за запуск отчета,You dont have a right to create this report").
    if OutMessage <> "" then
      RETURN.
  end.

  if EditMode = "Copy" then
  do:
    run CopyDoc ( RidTypedoc, PutOff, RidMainDoc, OUTPUT RidDoc ).
    if RidDoc = ? then
    do:
      OutMessage = ENTRY(l,"Ошибка копирования документа, Document copy error").
      RETURN.
    end.
  end.
  else do:
    run src/kernel/exectrig.p ( RidTypedoc, {&ON-BUSINESS-PROCESS}, ?, 1 , RidMainDoc).
    IF RETURN-VALUE = "ERROR" THEN
    do:
      OutMessage = ENTRY(l, "Ошибка создания документа (OnBusinessProcess),Error occured while creating new document (OnBusinessProcess)").
      RETURN.
    end.
    IF RETURN-VALUE <> "CONTINUE" THEN
    do: 
      find first DocsToEdit NO-ERROR.
      if not available DocsToEdit then
      do:
        find first WebOutMessage NO-ERROR.
        if not available WebOutMessage then
          OutMessage = ENTRY(l, "Документ нельзя создать напрямую,Document can be created as related only").
        else do:
          for each WebOutMessage by WebOutMessage.MessageId:
            if OutMessage = "" then
              OutMessage = WebOutMessage.MessageText.
            else
              OutMessage = OutMessage + chr(13) + chr(10) + WebOutMessage.MessageText.
          end.
        end.
        return.
      end.
      if DocsToEdit.NewDoc then
      do:
        if DocsToEdit.RidTypedoc <> RidTypedoc then
        do:
          OutMessage = ENTRY(l, "Сложные сценарии создания документов с изменением типа документа не поддерживаются,Rewrite business logic, this scenario is not supported by web interface").
          RETURN.
        end.
      end.
      RidDoc = DocsToEdit.RidDoc.
      RidMainDoc = DocsToEdit.RidMain.
      NewDoc = DocsToEdit.NewDoc.
      ViewOnly = DocsToEdit.ViewOnly.
    end.
  end.
  if RidDoc = ? then
  do:
    if EditMode = "" then
    do:
      run crNewDoc ( RidTypedoc, OUTPUT RidDoc ).
      if RidDoc = ? then
      do:
        OutMessage = ENTRY(l, "Не удалось создать новый документ,Error occured while creating new document").
        RETURN.
      end.
    end.
    if EditMode = "REPORT" then
    do:
      run src/kernel/new_doc6.p ( RidTypedoc, OUTPUT RidDoc ).
      if RidDoc = ? then
      do:
        OutMessage = Entry(l,"Не удалось создать новый отчет,Error occured while creating new report").
        RETURN.
      end.
    end.
    if EditMode = "SERVDOC" then
    do:
      run src/kernel/new_doc4.p ( RidTypedoc, OUTPUT RidDoc ).
      if RidDoc = ? then
      do:
        OutMessage = Entry(l,"Не удалось запустить процедуру,Error occured while running procedure").
        RETURN.
      end.
    end.
    if EditMode = "TEST" then
    do:
      run src/kernel/new_doc5.p ( RidTypedoc, OUTPUT RidDoc ).
      if RidDoc = ? then
      do:
        OutMessage = Entry(l,"Не удалось выполнить тестовую процедуру,Error occured while running test").
        RETURN.
      end.
    end.
  end.
end.
else do:
  run src/kernel/docright.p ( RidDoc ).
  maxright = INTEGER(RETURN-VALUE).
  if maxright = 0 then
  do:
    OutMessage = Entry(l, "У вас нет прав на этот документ,You dont have a right on this document").
    RETURN.
  end.
  if maxright = 1 then ViewOnly = true.
  IF ViewOnly THEN 
    RUN src/kernel/protdoc3.p ( RidDoc, 2, "Просмотр через Web", OUTPUT temp-rowid).          
  ELSE 
    RUN src/kernel/protdoc3.p ( RidDoc, 1, "Редактируется через Web", OUTPUT temp-rowid).
end.

run ToEdit.

/* ================================================================================================== */
/* Приват процедуры */

/* Копирование документа */
PROCEDURE CopyDoc:
  define input parameter rid-typedoc AS INTEGER.
  define input parameter put-offpr as logical.
  define input parameter rid-docfrom as integer.
  define output parameter rid-doc as integer initial ?.

  IF rid-docfrom = ? then RETURN.

  run src/kernel/new_doc2.p ( rid-typedoc, OUTPUT rid-doc ).
  IF rid-doc = ? then RETURN.
  find system.document where system.document.rid-document = rid-doc
    EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
  if not available system.document then 
  do:
    rid-doc = ?.
    RETURN.
  end. 
  else 
    system.document.put-off = put-offpr.
  RUN src/kernel/exectrig.p ( rid-doc, {&ON-COPY-DOCUMENT}, ?, 1 , rid-docfrom ).
END.

/* Создание нового документа */
PROCEDURE crNewDoc:
  define input parameter rid-typedoc AS INTEGER.
  define output parameter temp-rid as integer initial ?.

  DO TRANSACTION ON STOP UNDO, RETURN "CANCEL" :
    CREATE system.document.
    FIND FIRST system.users WHERE system.users.sys-name = uid NO-LOCK NO-ERROR.
    system.document.rid-user = system.users.rid-user.
    system.document.close-doc = document.rid-user.
    system.document.rid-typedoc = rid-typedoc.
    FOR FIRST typedoc WHERE typedoc.rid-typedoc = rid-typedoc NO-LOCK,
        FIRST groupdoc  
        WHERE  typedoc.rid-groupdoc = groupdoc.rid-groupdoc NO-LOCK:
      IF groupdoc.rid-app <> ? THEN  
        system.document.rid-app =  groupdoc.rid-app.
      ELSE system.document.rid-app = current-app.
  
      /* Система аудита */
      IF typedoc.AuditActivationMode = 0 THEN
        system.document.AuditEnabled = TRUE.
      /* / Система аудита */
    END.
  
    system.document.put-off = put-off.
    
    RUN src/kernel/new_dnum.p ( system.document.date-doc,  system.document.rid-document,
      OUTPUT system.document.id-document ).
    temp-rid = system.document.rid-document.
   
    FIND FIRST users WHERE users.sys-name = uid NO-LOCK NO-ERROR.
    IF NOT AVAILABLE users THEN RETURN.
    FIND FIRST journdoc WHERE journdoc.rid-document = temp-rid AND 
      journdoc.rid-user = users.rid-user NO-ERROR.  
    IF AVAILABLE journdoc THEN 
    do:
      temp-rowid = ROWID ( journdoc ).
      journdoc.append-info = "Создается".
    end.
  END.
END.

/* Заключительная подготовка перед редактированием документа */
PROCEDURE ToEdit:
  define variable id-templ as integer.

  ViewReason = ENTRY(l,"Документ доступен только на просмотр,Document available in readonly mode only").

  /* Создаем кеш заголовка документа если еще не было */
  cash-only = false.
  FIND system.document WHERE system.document.rid-document = RidDoc NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.document THEN 
  DO:
    FIND FIRST tt_document WHERE tt_document.rid-document = RidDoc NO-ERROR.
    IF NOT AVAILABLE tt_document THEN
    do:
      OutMessage = ENTRY(l,"У вас нет прав на этот документ,You dont have a right on this document").
      RETURN . 
    end.
    cash-only = true.
  END.
  ELSE DO:
    FIND FIRST tt_document WHERE tt_document.rid-document = RidDoc NO-ERROR.
    IF NOT AVAILABLE tt_document THEN
    DO:
      CREATE tt_document.
    END.
    BUFFER-COPY system.document TO tt_document.
  END.
  
  FIND typedoc OF tt_document NO-LOCK NO-ERROR.
  IF NOT AVAILABLE typedoc THEN
  do:
    OutMessage = ENTRY(l,"Неизвестный вид документа,Unknown document type").
    RETURN.
  end.

  IF NOT READ-ONLY and not ViewOnly then
  DO:
    FIND typedoc OF tt_document SHARE-LOCK NO-WAIT NO-ERROR.
    IF NOT AVAILABLE typedoc THEN
    DO:
      IF LOCKED typedoc THEN
        OutMessage = ENTRY(l,"Вид документа сейчас модифицируется, работа с документами запрещена,This document type is changing by developer").
      else
        OutMessage = ENTRY(l,"Неизвестный вид документа,Unknown document type").
      RETURN.
    END.  
  END.

  /* Кешируем данные самого документа */
/*  RUN src/kernel/bufdoc.p ( RidDoc ). */
  FOR EACH BufferedDocument WHERE BufferedDocument.Recid-Doc = RidDoc:
    DELETE BufferedDocument.
  END.
  FOR EACH doc-field-data WHERE doc-field-data.rid-document = RidDoc NO-LOCK:
/*
    RUN src/kernel/ridtoff.p (doc-field-data.rid-ff).
    RUN src/kernel/get_fts.p (string(RETURN-VALUE), RidDoc, doc-field-data.recnum).
*/
    CREATE BufferedDocument.
    ASSIGN 
      BufferedDocument.rid-ff    = doc-field-data.rid-ff
      BufferedDocument.fvalue    = doc-field-data.field-value
      BufferedDocument.row       = doc-field-data.recnum
      BufferedDocument.RecId-doc = RidDoc
      BufferedDocument.scr-value = ?.
/*    BufferedDocument.scr-value = string(RETURN-VALUE). */
  END.
  /* буферизация формы документа */
  FIND FIRST BufFrameDoc WHERE
    BufFrameDoc.rid-typedoc = tt_document.rid-typedoc NO-LOCK NO-ERROR.
  IF NOT AVAILABLE BufFrameDoc THEN
  DO:
    RUN src/kernel/buffrdoc.p ( tt_document.rid-typedoc ).
  END.   
  /* /буферизация формы документа */
  /* Буферизация числа строк в таблицах */
  IF AVAILABLE document THEN
  do:
    FOR EACH tt_doc-table-rows WHERE tt_doc-table-rows.rid-document = RidDoc:
      DELETE tt_doc-table-rows.
    END.
    FOR EACH doc-table-rows NO-LOCK WHERE doc-table-rows.rid-document = RidDoc:
      create tt_doc-table-rows.
      BUFFER-COPY doc-table-rows TO tt_doc-table-rows.
    END.
  end.
  /* /Буферизация числа строк в таблицах */

  IF not ViewOnly and NOT cash-only THEN
  DO:
    FIND system.document WHERE system.document.rid-document = RidDoc EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
    IF NOT AVAILABLE system.document THEN
    do:
      ViewOnly = true.
      ViewReason = ENTRY(l, "Документ заблокирован другим пользователем,Another user locked this document").
    end.
    else do:
      IF system.document.keep-doc THEN 
      do:
        ViewReason = ENTRY(l,"Документ на хранении. Редактирование невозможно,Document header has ReadOnly flag. Cannot edit document").
        ViewOnly = true.
      end.
    end.
  END.

  Empty TEMP-TABLE DocumentState.

  CREATE DocumentState.
  DocumentState.rid-doc = RidDoc.

  ASSIGN 
    DocumentState.BufEdit     = TRUE 
    DocumentState.cash-only   = cash-only
    DocumentState.is-docvonly = ViewOnly.

  IF NewDoc then
  DO:
    FIND FIRST tpdoc-template WHERE tpdoc-template.rid-typedoc = typedoc.rid-typedoc NO-LOCK NO-ERROR.
    IF AVAILABLE tpdoc-template THEN
    DO:
      RUN src/account/f3tdtml.w ( typedoc.rid-typedoc, OUTPUT id-templ ).
      RUN src/kernel/loaddtml.p ( RidDoc, id-templ ).
    END.
  
    RUN src/kernel/exectrig.p ( RidDoc, {&ON-NEW-DOCUMENT}, ?, 1 , RidMainDoc ).
  END.
  ELSE
  DO:
    RUN src/kernel/exectrig.p ( RidDoc, {&ON-INTEGRITY}, ?, 1 , ? ).
  END.

  FIND FIRST DocumentState WHERE DocumentState.rid-doc = RidDoc NO-ERROR.
  IF AVAILABLE DocumentState THEN
  DO:
    IF ViewOnly = FALSE THEN
      ViewOnly = DocumentState.is-docvonly.  /* Отработаем сброс v-only в OnIntegrity */
  
    IF DocumentState.NeedResave THEN
    DO:
      if not ViewOnly then 
        run SaveDoc (OUTPUT OutMessage).
    END.  
  END.

  rid-doc = RidDoc.
  rid-typedoc = RidTypedoc.
  isnew = NewDoc.
  eMode = EditMode.
  if eMode = "COPY" then eMode = "".
  v-only = ViewOnly.
  if v-only = false then
    ViewReason = "".

  for each BufferedDocument WHERE BufferedDocument.RecId-doc = RidDoc and
    BufferedDocument.is-modified = TRUE:
    BufferedDocument.is-modified = false.
  end.
  Empty Temp-Table FrameOpers.
  Empty Temp-Table FrameDisplay.

  for each WebOutMessage by WebOutMessage.MessageId:
    if OutMessage = "" then
      OutMessage = WebOutMessage.MessageText.
    else
      OutMessage = OutMessage + chr(13) + chr(10) + WebOutMessage.MessageText.
  end.

END.

/* ================================================================================================== */

/* Public процедуры */


PROCEDURE ViewStatus:
  define output parameter ViewOnly as logical.
  define output parameter Reason as character.

  run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId2, no).
  ViewOnly = v-only.
  Reason = ViewReason.
END.

PROCEDURE Ping:
  define output parameter OutMessage as character initial "OK".

  run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId2, no).
END.

/* Чтение данных документа из кеша документа */
DEFINE TEMP-TABLE FrameData NO-UNDO
  FIELD RidFF           AS integer
  FIELD InternalValue   as character
  FIELD FormValue       as character
  field ReadOnly        as logical
  field Disabled        as logical.

define TEMP-TABLE DF NO-UNDO
  field RidFrame        as integer
  field RidFF           as integer
  field TRow            as integer
  field ReadOnly        as logical
  field Disabled        as logical.

define TEMP-TABLE DisabledFields NO-UNDO
  field RidFrame        as integer
  field RidFF           as integer
  field TRow            as integer
  field ReadOnly        as logical
  field Disabled        as logical.

define temp-table ff NO-UNDO
  field rid-ff as integer
  field ftype as character
  field fformat as character
  index io rid-ff.

define temp-table vff NO-UNDO
  field rid-ff as integer
  index io rid-ff.


PROCEDURE DocHeaderData:
  define input-output parameter FrameKey as integer.
  define output parameter TABLE for FrameData.

  run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId2, no).

  define variable rid-ff as integer.
  define variable fformat as character.

  EMPTY TEMP-TABLE FrameData.

  FOR EACH doc-frame-fields
    WHERE doc-frame-fields.rid-frame = FrameKey AND
          doc-frame-fields.is-del = no NO-LOCK,
     EACH doc-data-type OF doc-frame-fields NO-LOCK,
     EACH basetype OF doc-data-type NO-LOCK:
 
    rid-ff = doc-frame-fields.rid-ff.
    find first vff where vff.rid-ff = rid-ff NO-ERROR.
    if not available vff then
    do:
      create vff.
      vff.rid-ff = rid-ff.
    end.

    fformat = "".
    if basetype.progress-type = "DECIMAL" or basetype.progress-type = "INTEGER" then
      fformat = doc-frame-fields.field-format.
 
    create FrameData.
    FrameData.RidFF = rid-ff.
    FrameData.InternalValue = "".
    FrameData.FormValue = "".
 
    FIND First BufferedDocument WHERE BufferedDocument.RecId-doc = RidDoc 
       AND BufferedDocument.rid-ff = rid-ff NO-LOCK NO-ERROR.
    IF AVAILABLE BufferedDocument then
    do: 
      if BufferedDocument.is-vonly = ? then BufferedDocument.is-vonly = false.
      FrameData.InternalValue = BufferedDocument.fvalue.
      if BufferedDocument.scr-value = ? then
      do:
        run src/kernel/strtofrm.p ( rid-ff, BufferedDocument.fvalue, fformat ).
        BufferedDocument.scr-value = RETURN-VALUE.
      end.
      FrameData.FormValue = BufferedDocument.scr-value.
      if BufferedDocument.is-enabled = false or BufferedDocument.is-vonly = true then
      do:
        find first DF where DF.RidFF = BufferedDocument.rid-ff and
            DF.TRow = BufferedDocument.row NO-ERROR.
        if not available DF then
        do:
          create DF.
          assign
            DF.RidFF = BufferedDocument.rid-ff
            DF.TRow  = BufferedDocument.row.
          find first BufFrameDoc where BufFrameDoc.rid-ff = BufferedDocument.rid-ff.
          if available BufFrameDoc then
            DF.RidFrame = BufFrameDoc.rid-frame.
          DF.ReadOnly = BufferedDocument.is-vonly.
          DF.Disabled = not BufferedDocument.is-enabled.
        end.
      end.
      FrameData.ReadOnly = BufferedDocument.is-vonly.
      FrameData.Disabled = not BufferedDocument.is-enabled.
    end.
  end.
 
  for each doc-form-fields where doc-form-fields.rid-form-frame = FrameKey NO-LOCK,
     each doc-frame-fields where doc-frame-fields.rid-ff = doc-form-fields.rid-ff NO-LOCK,
     EACH doc-data-type OF doc-frame-fields NO-LOCK,
     EACH basetype OF doc-data-type NO-LOCK:

    rid-ff = doc-form-fields.rid-ff.
    find first vff where vff.rid-ff = rid-ff NO-ERROR.
    if not available vff then
    do:
      create vff.
      vff.rid-ff = rid-ff.
    end.
 
    create FrameData.
    FrameData.RidFF = rid-ff.
    FrameData.InternalValue = "".
    FrameData.FormValue = "".
 
    fformat = "".
    if basetype.progress-type = "DECIMAL" or basetype.progress-type = "INTEGER" then
      fformat = doc-frame-fields.field-format.
 
    FIND First BufferedDocument WHERE BufferedDocument.RecId-doc = RidDoc 
       AND BufferedDocument.rid-ff = rid-ff NO-LOCK NO-ERROR.
    IF AVAILABLE BufferedDocument then
    do: 
      if BufferedDocument.is-vonly = ? then BufferedDocument.is-vonly = false.
      FrameData.InternalValue = BufferedDocument.fvalue.
      if BufferedDocument.scr-value = ? then
      do:
        run src/kernel/strtofrm.p ( rid-ff, BufferedDocument.fvalue, fformat ).
        BufferedDocument.scr-value = RETURN-VALUE.
      end.
      FrameData.FormValue = BufferedDocument.scr-value.

      if BufferedDocument.is-enabled = false or BufferedDocument.is-vonly = true then
      do:
        find first DF where DF.RidFF = BufferedDocument.rid-ff and
            DF.TRow = BufferedDocument.row NO-ERROR.
        if not available DF then
        do:
          create DF.
          assign
            DF.RidFF = BufferedDocument.rid-ff
            DF.TRow  = BufferedDocument.row.
          find first BufFrameDoc where BufFrameDoc.rid-ff = BufferedDocument.rid-ff.
          if available BufFrameDoc then
            DF.RidFrame = BufFrameDoc.rid-frame.
          DF.ReadOnly = BufferedDocument.is-vonly.
          DF.Disabled = not BufferedDocument.is-enabled.
        end.
      end.
      FrameData.ReadOnly = BufferedDocument.is-vonly.
      FrameData.Disabled = not BufferedDocument.is-enabled.
    end.
  end.
/*
  OUTPUT to 1.txt append.
    for each DF:
      display DF.
    end.
  OUTPUT CLOSE.
*/
END.

PROCEDURE DocTableData:
  define input-output parameter FrameKey as integer.
  define output parameter table for DisabledFields.
  define output parameter TABLE-HANDLE DocTableData.

  run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId2, no).

  define variable rid-ff as integer.
  define variable cur-row as integer.
  DEFINE variable hQuery           AS HANDLE NO-UNDO.
  DEFINE variable hBuffer          AS HANDLE NO-UNDO.
  DEFINE VARIABLE hBufferField     AS HANDLE NO-UNDO.
  define variable d as date.
  define variable dstr as character.

  EMPTY TEMP-TABLE ff.

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
    find first vff where vff.rid-ff = rid-ff NO-ERROR.
    if not available vff then
    do:
      create vff.
      vff.rid-ff = rid-ff.
    end.

    find first FF where FF.rid-ff = rid-ff NO-ERROR.
    if available FF then NEXT.

    create FF.
    FF.rid-ff = rid-ff.
    if basetype.progress-type = "LOGICAL" then
      FF.ftype = "LOGICAL".
    else do:
/*
      if basetype.progress-type = "DATE" then
        FF.ftype = "DATE".
      else
*/
        FF.ftype = "CHARACTER".
    end.
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
    find first vff where vff.rid-ff = rid-ff NO-ERROR.
    if not available vff then
    do:
      create vff.
      vff.rid-ff = rid-ff.
    end.

    find first FF where FF.rid-ff = rid-ff NO-ERROR.
    if available FF then NEXT.

    create FF.
    FF.rid-ff = rid-ff.
    if basetype.progress-type = "LOGICAL" then
      FF.ftype = "LOGICAL".
    else do:
/*
      if basetype.progress-type = "DATE" then
        FF.ftype = "DATE".
      else
*/
        FF.ftype = "CHARACTER".
    end.
    FF.fformat = "".
    if basetype.progress-type = "DECIMAL" or basetype.progress-type = "INTEGER" then
      FF.fformat = doc-frame-fields.field-format.

    DocTableData:ADD-NEW-FIELD ("Field" + string(rid-ff), FF.ftype). 
    DocTableData:ADD-NEW-FIELD ("Data"  + string(rid-ff), FF.ftype). 
  end.
  DocTableData:TEMP-TABLE-PREPARE ("DocTableData").
  CREATE BUFFER hBuffer FOR TABLE DocTableData:DEFAULT-BUFFER-HANDLE.

  cur-row = -1.
  for each BufferedDocument WHERE BufferedDocument.RecId-doc = RidDoc NO-LOCK,
      each FF where FF.rid-ff = BufferedDocument.rid-ff NO-LOCK
      by BufferedDocument.row:

    if BufferedDocument.is-vonly = ? then BufferedDocument.is-vonly = false.
    rid-ff = BufferedDocument.rid-ff.
    if BufferedDocument.row <> cur-row then
    do:
      cur-row = BufferedDocument.row.

      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("RowId"):BUFFER-VALUE = cur-row.
    end.
    if FF.ftype = "LOGICAL" then
    do:
      hBuffer:BUFFER-FIELD("Data" + string(rid-ff)):BUFFER-VALUE = LOGICAL(BufferedDocument.fvalue) NO-ERROR.
      hBuffer:BUFFER-FIELD("Field" + string(rid-ff)):BUFFER-VALUE = LOGICAL(BufferedDocument.fvalue) NO-ERROR.
    end.
    else do:
      if FF.ftype = "DATE" then
      do:
        d = DATE(BufferedDocument.fvalue) NO-ERROR.
        if d <> ? then
        do:
          hBuffer:BUFFER-FIELD("Data" + string(rid-ff)):BUFFER-VALUE = d NO-ERROR.
          hBuffer:BUFFER-FIELD("Field" + string(rid-ff)):BUFFER-VALUE = d NO-ERROR.
        end.
      end.
      else do:
        hBuffer:BUFFER-FIELD("Data" + string(rid-ff)):BUFFER-VALUE = BufferedDocument.fvalue.
        if BufferedDocument.scr-value = ? then
        do:
          run src/kernel/strtofrm.p ( rid-ff, BufferedDocument.fvalue, fformat ).
          BufferedDocument.scr-value = RETURN-VALUE.
        end.
        hBuffer:BUFFER-FIELD("Field" + string(rid-ff)):BUFFER-VALUE = BufferedDocument.scr-value.
      end.
    end.
    if BufferedDocument.is-enabled = false or BufferedDocument.is-vonly = true then
    do:
      find first DF where DF.RidFF = BufferedDocument.rid-ff and
          DF.TRow = BufferedDocument.row NO-ERROR.
      if not available DF then
      do:
        create DF.
        assign
          DF.RidFF = BufferedDocument.rid-ff
          DF.TRow  = BufferedDocument.row.
        find first BufFrameDoc where BufFrameDoc.rid-ff = BufferedDocument.rid-ff.
        if available BufFrameDoc then
          DF.RidFrame = BufFrameDoc.rid-frame.
        DF.ReadOnly = BufferedDocument.is-vonly.
        DF.Disabled = not BufferedDocument.is-enabled.
        create DisabledFields.
        BUFFER-COPY DF to DisabledFields.
      end.
    end.
  end.
END.

DEFINE DATASET CacheTables for
  tt_document, BufferedDocument, DocumentState, BufFrameDoc, tt_doc-table-rows, DF, vff
  DATA-RELATION for tt_document, BufferedDocument RELATION-FIELDS (rid-document, recID-doc)
  DATA-RELATION for tt_document, DocumentState RELATION-FIELDS (rid-document, rid-doc)
  DATA-RELATION for tt_document, BufFrameDoc RELATION-FIELDS (rid-typedoc, rid-typedoc)
  DATA-RELATION for tt_document, tt_doc-table-rows RELATION-FIELDS (rid-document, rid-document).

PROCEDURE DumpCache:
  define output parameter DumpFile as character.
  run src/system/getmpfi2.p ("tmp").
  DumpFile = RETURN-VALUE.
  DATASET CacheTables:WRITE-XML ("FILE", DumpFile, yes).
end.

/* ================================================================================================== */
/* Отработка событий документа                                                                        */


define TEMP-TABLE ModifiedFields NO-UNDO
  field RidFrame        as integer
  field RidFF           as integer
  field TRow            as integer
  field InternalValue   as character
  field FormValue       as character.

define TEMP-TABLE TableOpers NO-UNDO
  field RidFrame        as integer
  field OperOrder       as integer
  field OperName        as character
  field TRow            as integer
  index i0 RidFrame OperOrder.

define TEMP-TABLE PrintOpers NO-UNDO
  field Module as character
  field ViewOnly as logical
  field FileName as character
  field FileType as character
  field PrintParams as character.

PROCEDURE SendEvent:
  define input-output parameter QueryId as integer.  /* Call back key */
  define input parameter EventName as character.     /* Имя события */
  define input parameter RidFF as integer.           /* Поле документа */
  define input parameter row as integer.             /* Номер строки документа */
  define input parameter InputValue as character.    /* Новое значение поля */
  define output parameter OutMessage as character initial "".
  define output parameter OutputValue as character initial "".
  define output parameter table for ModifiedFields.
  define output parameter table for DisabledFields.
  define output parameter table for TableOpers.
  define output parameter table for PrintOpers.

  define variable rid-frame as integer.
  define variable CanTableOper as logical.
  define variable rv as character.
  define variable state as logical.
  define variable DeleteReason as character.
  define variable i as integer.

  run webservices/webdb/src/Security.p (INPUT-OUTPUT ContextId2, no).

  output to log/web_doc_events.txt append.
  put unformatted STRING(TODAY, "99/99/9999") space STRING(TIME, "HH:MM:SS") space QueryId space EventName space
    RidFF space row space InputValue SKIP.
  output close.

  Empty Temp-Table WebOutMessage.
  Empty Temp-Table ModifiedFields.
  Empty Temp-Table DisabledFields.
  Empty Temp-Table TableOpers.
  Empty Temp-Table PrintOpers.
  Empty Temp-Table tt_proc-messages.

  RUN src/kernel/cr_mess_rec.p (rid-doc, uid, "", TODAY, "", currid-cathg, OUTPUT uni-key-AppServer, FALSE, FALSE, OUTPUT TABLE tt_proc-messages).

  if EventName = "GetContext" then
  do:
    RUN src/kernel/exectrig.p ( rid-doc, {&ON-GETCONTEXT}, RidFF, row, ? ).
    OutputValue = RETURN-VALUE.
    RETURN.
  end.

  if EventName = "ValueCommit" or EventName = "ValueSelect" then
  do:
    if not v-only and row > 0 then
    do:
      NeedSave = true.
      RUN src/kernel/set_stv.p ( RidFF, rid-doc, row, InputValue ).
      if EventName = "ValueSelect" then
        RUN src/kernel/exectrig.p ( rid-doc, {&ON-AFTER-SELECT}, RidFF, row, ? ).
    end.
  end.
  if EventName = "ButtonClick" then
  do:
    if not v-only then
    do:
      NeedSave = true.
      RUN src/kernel/exectrig.p ( rid-doc, {&ON-CHOOSE}, RidFF, row, ? ).
      if RETURN-VALUE = "SAVE" then
        DocumentState.NeedResave = true.
    end.
  end.
  if EventName Begins "TableRow" then
  do:
    rid-frame = RidFF.
    if row <= 0 then row = 1.
    if not v-only then
    do:
      CanTableOper = false.
      if EventName = "TableRowAdd" or EventName = "TableRowInsert" then
      do:
        label-add:
        DO TRANSACTION:
          RUN src/kernel/exectrig.p ( rid-doc, {&ON-BEFORE-ADD-LINE}, rid-frame, ?, ? ).
          IF RETURN-VALUE = "NO-ADD" THEN UNDO label-add, leave.
          CanTableOper = true.
        END.
      end.
      if EventName = "TableRowDelete" then
      do:
        label-del:
        DO TRANSACTION:
          RUN src/kernel/exectrig.p ( rid-doc, {&ON-BEFORE-DEL-LINE}, rid-frame, row, ? ).
          IF RETURN-VALUE = "NO-DELETE" THEN UNDO label-del, leave.
          CanTableOper = true.
        END.
      end.
      if CanTableOper then
      do:
        NeedSave = true.
        if EventName = "TableRowAdd" then
          RUN src/kernel/add_tl.p ( rid-frame, rid-doc ).
        if EventName = "TableRowInsert" then
          RUN src/kernel/ins_tl.p ( rid-frame, rid-doc, row ).
        if EventName = "TableRowDelete" then
          RUN src/kernel/del_tl.p ( rid-frame, rid-doc, row ). 
      end.
      else do:
        if EventName = "TableRowDelete" then
          OutMessage = ENTRY(l,"Запрещено удалять строку,Row deletion is not permitted").
        else
          OutMessage = ENTRY(l,"Запрещено добавлять строку,Row addition is not permitted").
      end.
    end.
  end.
  if EventName = "PrintDocument" then
  do:
    RUN src/kernel/exectrig.p ( rid-doc, {&ON-BEFORE-PRINT}, ?, 1, ? ).
    rv = RETURN-VALUE.
    if rv = "NO-PRINT" then
    do:
    end.
    IF rv = "SAVE-AND-PRINT" then
    do:
      if not v-only then 
      do:
        run SaveDoc (OUTPUT OutMessage).
        if OutMessage = "" then
        do:
          rv = "PRINT".
/*
          if eMode = "" then
            OutMessage = ENTRY(l, "Документ сохранен,Document is saved").
*/
        end.
      end.
      else rv = "PRINT".
    end.

    if rv = "PRINT" then
    do:
      run src/kernel/exectrig.p ( rid-doc, {&ON-PRINT-DOCUMENT}, ?, 1, ? ).
      rv = RETURN-VALUE.
      if (rv = "Save" or rv = "SaveAndQuit") and NOT v-only THEN
        DocumentState.NeedResave = true.
      if rv = "SaveAndQuit" then
        OutputValue = "Quit".
    end.
  end.
  if EventName = "DeleteDocument" and DocumentState.cash-only = false and not v-only then
  do:
    RUN src/kernel/docright.p ( rid-doc ).
    IF INTEGER ( RETURN-VALUE ) < 3 then
      OutMessage = ENTRY(l,"У вас нет прав на удаление этого документа,You dont have a right to delete this document").
    else do:
      DeleteReason = InputValue.

      ldel:
      DO ON STOP UNDO, LEAVE ldel
         ON ERROR UNDO, LEAVE ldel
         ON END-KEY UNDO, LEAVE ldel:
          
        FIND FIRST typedoc OF tt_document NO-LOCK.
          
        RUN src/protokl2.p ( "src/account/document.w", 9051,
            string(typedoc.id-typedoc) + ";" + string (rid-doc) + " " +
            typedoc.name-typedoc + " за " + STRING ( tt_document.date-doc ) + 
            " с номером " + STRING ( tt_document.id-document ) + " ( " + DeleteReason + " )" ).
  
        RUN includes/src/account/makedoc_win/del_doc.p ( rid-doc ).
        rv = RETURN-VALUE.
  
        IF rv BEGINS "ERROR " THEN
        DO:
          rv = SUBSTRING (rv, 7).
          RUN src/textmesl.p (rv, 1, OUTPUT state).
          STOP.
        END.
        IF rv = "ERROR" THEN
        do:
          RUN src/textmesl.p (ENTRY(l,"Невозможно удалить документ,Cannot delete document"), 1, OUTPUT state).
          STOP.
        end.
        DocumentState.NeedResave = false.
        OutputValue = "Quit".
      END.
    END.
  END.
  /* Завершающие действия перед закрытием окна */
  if EventName = "WindowClose" then
  DO TRANSACTION:
    if isnew and not saved then
    do:
      /* Удалим новый документ, который ни разу не сохранили */
      FIND document WHERE document.rid-document = rid-doc
        EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
      IF AVAILABLE document THEN
        DELETE document NO-ERROR.
    end.
    else do:
      FIND FIRST journdoc WHERE ROWID ( journdoc ) = temp-rowid NO-ERROR.
      IF AVAILABLE journdoc THEN 
      DO:   
        if not isnew then
        do:
          if saved then
            journdoc.typeoper = 1.
          else
            journdoc.typeoper = 2.
        end.
        journdoc.append-info = "по " + STRING ( TODAY ) + " " + STRING ( TIME, "HH:MM:SS" ). 
      END.  
      if list-prnprotdate <> "" THEN 
      DO i = 1 TO NUM-ENTRIES ( list-prnprotdate ) : 
        RUN src/kernel/protdoc2.p ( DATE ( ENTRY ( i, list-prnprotdate ) ),                                
        ENTRY ( i, list-prnprottime ), rid-doc, 3, "" ).  
      END.
    end.

    OutputValue = "Quit".
  end.

  if EventName = "SaveDocument" or DocumentState.NeedResave then
  do:
    run SaveDoc (OUTPUT OutMessage).
/*
    if OutMessage = "" and eMode = "" then
      OutMessage = ENTRY(l, "Документ сохранен,Document is saved").
*/
  end.

  /* Отслеживаем изменения данных документа, которые произошли по тригерам и 
     формируем ответ по модифицации данных.
  */

  for each BufferedDocument WHERE BufferedDocument.RecId-doc = RidDoc and
    BufferedDocument.is-modified = TRUE:

    if BufferedDocument.scr-value = ? then
    do:
      run src/kernel/strtofrm.p ( BufferedDocument.rid-ff, BufferedDocument.fvalue, "" ).
      BufferedDocument.scr-value = RETURN-VALUE.

      find first vff where vff.rid-ff = BufferedDocument.rid-ff NO-ERROR.
      if available vff then
      do:
        create ModifiedFields.
        assign
          ModifiedFields.RidFF = BufferedDocument.rid-ff
          ModifiedFields.TRow = BufferedDocument.row
          ModifiedFields.InternalValue = BufferedDocument.fvalue
          ModifiedFields.FormValue = BufferedDocument.scr-value.
        find first BufFrameDoc where BufFrameDoc.rid-ff = BufferedDocument.rid-ff.
        if available BufFrameDoc then
          ModifiedFields.RidFrame = BufFrameDoc.rid-frame.
      end.
    end.
    BufferedDocument.is-modified = false.

    if BufferedDocument.is-enabled = false or BufferedDocument.is-vonly = true then
    do:
      find first DF where DF.RidFF = BufferedDocument.rid-ff and
          DF.TRow = BufferedDocument.row NO-ERROR.
      if not available DF then
      do:
        create DF.
        assign
          DF.RidFF = BufferedDocument.rid-ff
          DF.TRow  = BufferedDocument.row.
        find first BufFrameDoc where BufFrameDoc.rid-ff = BufferedDocument.rid-ff.
        if available BufFrameDoc then
          DF.RidFrame = BufFrameDoc.rid-frame.
        DF.ReadOnly = BufferedDocument.is-vonly.
        DF.Disabled = not BufferedDocument.is-enabled.
        create DisabledFields.
        BUFFER-COPY DF to DisabledFields.
      end.
      else do:
        if not (BufferedDocument.is-enabled <> DF.Disabled and BufferedDocument.is-vonly = DF.ReadOnly) then
        do:
          DF.ReadOnly = BufferedDocument.is-vonly.
          DF.Disabled = not BufferedDocument.is-enabled.
          create DisabledFields.
          BUFFER-COPY DF to DisabledFields.
        end.
      end.
    end.
    else do:
      find first DF where DF.RidFF = BufferedDocument.rid-ff and
          DF.TRow = BufferedDocument.row NO-ERROR.
      if available DF then
      do:
        delete DF.
        create DisabledFields.
        assign
          DisabledFields.RidFF = BufferedDocument.rid-ff
          DisabledFields.TRow  = BufferedDocument.row.
        find first BufFrameDoc where BufFrameDoc.rid-ff = BufferedDocument.rid-ff.
        if available BufFrameDoc then
          DisabledFields.RidFrame = BufFrameDoc.rid-frame.
        DisabledFields.ReadOnly = BufferedDocument.is-vonly.
        DisabledFields.Disabled = not BufferedDocument.is-enabled.
      end.
    end.
  end.

  for each FrameOpers:
    create TableOpers.
    TableOpers.RidFrame  = FrameOpers.RidFrame.
    TableOpers.OperOrder = FrameOpers.OperId.
    TableOpers.OperName  = FrameOpers.OperName.
    TableOpers.TRow   = FrameOpers.OperRow.
  end.
  Empty Temp-Table FrameOpers.
  Empty Temp-Table FrameDisplay.

  for each WebOutMessage by WebOutMessage.MessageId:
    if OutMessage = "" then
      OutMessage = WebOutMessage.MessageText.
    else
      OutMessage = OutMessage + chr(13) + chr(10) + WebOutMessage.MessageText.
  end.

  /* Интерфейс с системой печати. События OnPrintDocument/OnCloseDocument
     могут вызывать модули src/editor.w (просмотр текста), 
     src/prn_dvs.w (система печати через драйвера для tty/windows).
     Расшифровываем параметры и формируем результат */

  define variable module as character.
  define variable param1 as logical.
  define variable param2 as character.
  define variable param3 as character.
  define variable file-param as character.
  define variable N as integer.
  define variable M as integer.

  for each tt_proc-messages:
    module = tt_proc-messages.module.
    param1 = tt_proc-messages.v-only.
    param2 = tt_proc-messages.file-path.
    param3 = tt_proc-messages.params.
/*
  output to log/web_doc_events.txt append.
  put unformatted STRING(TODAY, "99/99/9999") space STRING(TIME, "HH:MM:SS") space QueryId space EventName space
    module space param1 space param2 space param3 SKIP.
  output close.
*/
    IF module <> "" THEN
    DO:
      DO N = 1 TO NUM-ENTRIES (module) :
        file-param = ENTRY (N, param2).
        DO M = 1 TO NUM-ENTRIES (file-param, ";"):
          if module <> "src/editor.w" then
          do:
            if NUM-ENTRIES (ENTRY(M,file-param,";"), "#") < 2 then NEXT.
            if ENTRY(2,ENTRY(M,file-param,";"),"#") = "" then NEXT.
          end.
          create PrintOpers.
          assign
            PrintOpers.Module = ENTRY (N, module).
            PrintOpers.ViewOnly = param1.
          if PrintOpers.Module = "src/editor.w" then
          do:
            PrintOpers.FileName = ENTRY(M,file-param,";").
            PrintOpers.FileType = "TEXT".
            PrintOpers.PrintParams = ENTRY (N, param3, "|").
          end.
          else do:
            PrintOpers.FileName = ENTRY(2,ENTRY(M,file-param,";"),"#").
            PrintOpers.FileType = ENTRY(1,ENTRY(M,file-param,";"),"#").
            PrintOpers.PrintParams = ENTRY (N, param3, "|").
          end.
          if PrintOpers.Module = "src/editor.w" then
            PrintOpers.Module = "ViewText".
          if PrintOpers.Module = "src/prn_dvs.w" then
            PrintOpers.Module = "PrintFile".
        END.
      END.
    END.
  END.
END.

PROCEDURE SaveDoc:
  define output parameter OutMessage as character initial "".
  define variable flag-ok as logical initial false.
  define variable begin-date as date.
  define variable end-date as date.

  if v-only then RETURN.
  RUN src/kernel/exectrig.p ( rid-doc, {&BEFORE-CLOSE-DOCUMENT}, ?, 1, ? ).
  IF RETURN-VALUE = "ERROR" THEN 
  do:
    if eMode = "" then
      OutMessage = ENTRY(l, "Документ не сохранен. Не соблюдены правила ввода документа,Document is not saved. Check fill fields rules").
    else
      OutMessage = ENTRY(l, "Не соблюдены правила ввода,Check fill fields rules").
    RETURN.
  end.

  DO TRANSACTION ON ERROR UNDO, LEAVE
    ON STOP UNDO, LEAVE
    ON END-KEY UNDO, LEAVE:

    flag-ok = TRUE.

    FIND FIRST DocumentState WHERE DocumentState.rid-doc = rid-doc NO-ERROR.
    IF AVAILABLE DocumentState THEN
    DO:
      IF DocumentState.BufEdit and DocumentState.cash-only = false THEN
        RUN src/kernel/savebufdoc.p ( rid-doc ).
      if NOT DocumentState.cash-only then
        DocumentState.BufEdit = FALSE.   /* Выключает режим редактирования только буфера документа, чтобы отразить изменения OnCloseDocument */
      IF NOT DocumentState.cash-only THEN
        RUN src/kernel/saverowdoc.p (rid-typedoc, rid-doc).
    END.

    FIND FIRST users WHERE users.sys-name = uid NO-LOCK NO-ERROR.

    FIND tt_document WHERE tt_document.rid-document = rid-doc EXCLUSIVE-LOCK NO-ERROR.
    ASSIGN
      tt_document.close-doc = users.rid-user
      tt_document.rid-cathg = currid-cathg.

    IF NOT DocumentState.cash-only THEN
    DO:
      FIND document WHERE document.rid-document = rid-doc EXCLUSIVE-LOCK NO-ERROR.
      ASSIGN
        document.close-doc = users.rid-user
        document.rid-cathg = currid-cathg.
    END.     

    RUN src/kernel/exectrig.p ( rid-doc, {&ON-CLOSE-DOCUMENT}, ?, 1, ? ).

    IF cash-only THEN 
    DO:
      FIND tt_document WHERE tt_document.rid-document = rid-doc EXCLUSIVE-LOCK.
      RUN src/kernel/eperiod.p ( rid-typedoc, OUTPUT begin-date, OUTPUT end-date ).
      IF tt_document.date-doc < begin-date OR tt_document.date-doc > end-date then
      DO:
        IF tt_document.date-doc > end-date THEN
          tt_document.date-doc = end-date.
        RUN src/kernel/seterror.p ( rid-doc, "Неверная дата документа" ).
      END.
    END.
    ELSE 
    DO:
      FIND document WHERE document.rid-document = rid-doc EXCLUSIVE-LOCK.
      RUN src/kernel/eperiod.p ( rid-typedoc, OUTPUT begin-date, OUTPUT end-date ).
      IF document.date-doc < begin-date OR document.date-doc > end-date then
      DO:
        IF document.date-doc > end-date THEN
          document.date-doc = end-date.
        RUN src/kernel/seterror.p ( rid-doc, "Неверная дата документа" ).

        FIND tt_document WHERE tt_document.rid-document = rid-doc EXCLUSIVE-LOCK.
        tt_document.date-doc = document.date-doc.
      END.
    END.
  end.
  if not flag-ok then
  do:
    OutMessage = ENTRY(l, "Неизвестная ошибка при обработке документа,Unknown error while processing document").
    RETURN.
  end.

  /* Выполнить код после сохранения документа вне рамок транзакции */
  DO:
/*
    output to 1.txt append.
    put unformatted string(transObj) transobj:is-open transobj:Default-commit transaction skip.
    output close.
*/

    RUN src/kernel/exectrig.p ( rid-doc, {&ON-AFTER-CLOSE}, ?, 1, ? ).
  END.

  /* Вернуть назад параметры кеширования */
  FIND FIRST DocumentState WHERE DocumentState.rid-doc = rid-doc NO-ERROR.
  IF AVAILABLE DocumentState THEN
  do:
    DocumentState.NeedResave = False.
    DocumentState.BufEdit = TRUE.
  end.
  NeedSave = FALSE.
  saved = true.
END.
