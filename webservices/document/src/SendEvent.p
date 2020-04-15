/* Copyright (C) Maxim A. Monin 2009-2010 */

{connect.i}
{oblik.i}

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

define temp-table vff NO-UNDO
  field rid-ff as integer
  index io rid-ff.

DEFINE DATASET CacheTables for
  tt_document, BufferedDocument, DocumentState, BufFrameDoc, tt_doc-table-rows, DF, vff
  DATA-RELATION for tt_document, BufferedDocument RELATION-FIELDS (rid-document, recID-doc)
  DATA-RELATION for tt_document, DocumentState RELATION-FIELDS (rid-document, rid-doc)
  DATA-RELATION for tt_document, BufFrameDoc RELATION-FIELDS (rid-typedoc, rid-typedoc)
  DATA-RELATION for tt_document, tt_doc-table-rows RELATION-FIELDS (rid-document, rid-document).


define input-output parameter ContextId as character.
define input-output parameter RidDoc    as integer.
define input-output parameter ViewOnly  as logical.
define input-output parameter RidTypedoc as integer.
define input parameter NewDoc           as logical.
define input parameter EditMode         as character.

define input parameter DumpFile as character.

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

/* Security + инициализация глобальных переменных */
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

define variable maxright as integer.
define variable temp-rowid as rowid.

cash-only = true.
isnew = yes.
saved = false.
NeedSave = true.

rid-doc = RidDoc.
rid-typedoc = RidTypedoc.
isnew = NewDoc.
eMode = EditMode.
if eMode = "COPY" then eMode = "".
v-only = ViewOnly.


run LoadCache (DumpFile).

RUN src/kernel/gmaxrigh.p ( RidTypedoc ).
maxright = INTEGER(RETURN-VALUE).
if maxright = 0 then
do:
  OutMessage = Entry(l, "У вас нет прав на этот документ,You dont have a right on this document").
  RETURN.
end.
if maxright = 1 then ViewOnly = true.

run SendEvent (INPUT-OUTPUT QueryId, EventName, RidFF, row, InputValue, OUTPUT OutMessage, OUTPUT OutputValue,
  OUTPUT TABLE ModifiedFields, OUTPUT TABLE DisabledFields, OUTPUT TABLE TableOpers, OUTPUT TABLE PrintOpers).

if OutputValue = "Quit" then
  OS-DELETE VALUE(DumpFile).
else
  run DumpCache (DumpFile).

/*==========================================================================================================*/

PROCEDURE DumpCache:
  define input parameter DumpFile as character.
  DATASET CacheTables:WRITE-XML ("FILE", DumpFile, yes).
end.

PROCEDURE LoadCache:
  define input parameter DumpFile as character.
  DATASET CacheTables:READ-XML ("FILE", DumpFile, "EMPTY", ?, FALSE).
end.

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
/*
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
*/

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
