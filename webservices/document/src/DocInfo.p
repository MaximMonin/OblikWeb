/* Copyright (C) Maxim A. Monin 2009-2010 */

/* Получить учетную и связанную операцию по документу */

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
define input-output parameter InfoType as character.
define input parameter RidDoc as integer.
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

define variable l as integer.
if lang begins "ru" then
  l = 1.
else
  l = 2.

define variable i as integer.
define variable fieldcount as integer.
DEFINE variable hQuery           AS HANDLE NO-UNDO.
DEFINE variable hBuffer          AS HANDLE NO-UNDO.
DEFINE VARIABLE hBufferField     AS HANDLE NO-UNDO.

if InfoType = "OPERAT" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("IdOper",    "integer"). 
  DocumentData:ADD-NEW-FIELD ("DateOper",  "date"). 
  DocumentData:ADD-NEW-FIELD ("CountD",    "character"). 
  DocumentData:ADD-NEW-FIELD ("AnobjD",    "character"). 
  DocumentData:ADD-NEW-FIELD ("AnobjAD",   "character"). 
  DocumentData:ADD-NEW-FIELD ("CountK",    "character"). 
  DocumentData:ADD-NEW-FIELD ("AnobjK",    "character"). 
  DocumentData:ADD-NEW-FIELD ("AnobjAK",   "character"). 
  DocumentData:ADD-NEW-FIELD ("Currency",  "character"). 
  DocumentData:ADD-NEW-FIELD ("CurSum",    "character"). 
  DocumentData:ADD-NEW-FIELD ("Sum",       "character"). 
  DocumentData:ADD-NEW-FIELD ("Quan",      "character"). 
  DocumentData:ADD-NEW-FIELD ("Order",     "integer"). 
  DocumentData:ADD-NEW-FIELD ("Descr",     "character"). 
  DocumentData:ADD-NEW-FIELD ("Fil",       "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","IdOper").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Номер,Number") fName = "IdOper" fWidth = 6 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Дата,Date") fName = "DateOper" fWidth = 10 fType = "date" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Сумма,Sum") fName = "Sum" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Дебет,Debet") fName = "CountD" fWidth = 10 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = Entry(l,"Аналитика Дебет,Debet analitic") fName = "AnobjD" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = Entry(l,"Аналитика Дебет+,Debet analitics+") fName = "AnobjAD" fWidth = 12 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Кредит,Credit") fName = "CountK" fWidth = 10 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Аналитика Кредит,Credit analitic") fName = "AnobjK" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Аналитика Кредит+,Credit analitics+") fName = "AnobjAK" fWidth = 12 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Валюта,Currency") fName = "Currency" fWidth = 10 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Сумма валютная,Currency sum") fName = "CurSum" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Количество,Quantity") fName = "Quan" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Ордер,Memo") fName = "Order" fWidth = 6 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Содержание операции,Description") fName = "Descr" fWidth = 40 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l, "Центр,Workcenter") fName = "Fil" fWidth = 20 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  define variable ancode as character.
  define variable ad as character.
  define variable ak as character.
  define buffer anobject2 for system.anobject.
  define buffer accounts2 for system.accounts.
  DEFINE TEMP-TABLE access-plans NO-UNDO
    FIELD plan AS INTEGER
    INDEX i0 IS PRIMARY UNIQUE plan.

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.
  RUN src/kernel/isavgen.p ( 1 ).
  IF RETURN-VALUE = "NO" then RETURN.

  Find First system.cathg WHERE system.cathg.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.cathg then RETURN.
  Find First system.ctg-options OF system.cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.ctg-options then RETURN.

  if system.ctg-options.is-allaccplan then 
  do:
    FOR EACH system.acc-plan NO-LOCK :
      CREATE access-plans.
      access-plans.plan = system.acc-plan.plan.
    END.
  end.
  else do:
    FOR EACH system.acc-plan NO-LOCK,
        EACH system.ctg-accplan where system.ctg-accplan.plan = system.acc-plan.plan and 
             system.ctg-accplan.rid-cathg = system.ctg-options.rid-cathg NO-LOCK :
      CREATE access-plans.
      access-plans.plan = system.acc-plan.plan.
    END.
  end.  

  FOR EACH system.operat USE-INDEX i-id WHERE system.operat.rid-document = RidDoc 
      and system.operat.rid-ent = rid-ent NO-LOCK,
      EACH system.accounts WHERE system.accounts.count1 = system.operat.count1-d NO-LOCK,
      EACH accounts2 WHERE accounts2.count1 = system.operat.count1-k NO-LOCK,
      EACH access-plans WHERE system.accounts.plan = access-plans.plan NO-LOCK,
      EACH system.anobject where system.anobject.rid-anobject = system.operat.anobject-d NO-LOCK,
      EACH anobject2 where anobject2.rid-anobject = system.operat.anobject-k NO-LOCK:

    hBuffer:BUFFER-CREATE().

    hBuffer:BUFFER-FIELD("IdOper"):BUFFER-VALUE = system.operat.id-operat.
    hBuffer:BUFFER-FIELD("DateOper"):BUFFER-VALUE = system.operat.date-oper.

    for each apnd-operat-obj where apnd-operat-obj.rid-operat = system.operat.rid-operat NO-LOCK 
        BREAK BY apnd-operat-obj.is-debet BY apnd-operat-obj.rid-apnd-count-obj :
      if apnd-operat-obj.is-debet = yes then 
      do:
        if ad = "" then ad = apnd-operat-obj.screenval.
        else ad = ad + "," + apnd-operat-obj.screenval.
      end.
      else do:
        if ak = "" then ak = apnd-operat-obj.screenval.
        else ak = ak + "," + apnd-operat-obj.screenval.
      end. 
    end.
    hBuffer:BUFFER-FIELD("CountD"):BUFFER-VALUE = system.operat.count1-d + " " + system.accounts.account-name.
    run src/kernel/ridtoobj.p ( system.anobject.rid-anobject, OUTPUT ancode ). 
    hBuffer:BUFFER-FIELD("AnobjD"):BUFFER-VALUE = ancode + " " + system.anobject.name-anobject.
    hBuffer:BUFFER-FIELD("AnobjAD"):BUFFER-VALUE = ad.

    hBuffer:BUFFER-FIELD("CountK"):BUFFER-VALUE = system.operat.count1-d + " " + accounts2.account-name.
    run src/kernel/ridtoobj.p ( anobject2.rid-anobject, OUTPUT ancode ). 
    hBuffer:BUFFER-FIELD("AnobjK"):BUFFER-VALUE = ancode + " " + anobject2.name-anobject.
    hBuffer:BUFFER-FIELD("AnobjAK"):BUFFER-VALUE = ak.

    find first system.currency of system.operat NO-LOCK NO-ERROR.
    if available system.currency then
      hBuffer:BUFFER-FIELD("Currency"):BUFFER-VALUE = system.currency.name-currency.
    find first system.filials of system.operat NO-LOCK NO-ERROR.
    if available system.filials then
      hBuffer:BUFFER-FIELD("Fil"):BUFFER-VALUE = system.filials.name-filial.

    hBuffer:BUFFER-FIELD("CurSum"):BUFFER-VALUE = STRING(system.operat.sum-curr, "->>>,>>>,>>9.99").
    hBuffer:BUFFER-FIELD("Sum"):BUFFER-VALUE    = STRING(system.operat.sum, "->>>,>>>,>>9.99").
    hBuffer:BUFFER-FIELD("Quan"):BUFFER-VALUE   = STRING(system.operat.quantity, "->>,>>>,>>9.999").
    hBuffer:BUFFER-FIELD("Order"):BUFFER-VALUE = system.operat.NumOrder. 
    hBuffer:BUFFER-FIELD("Descr"):BUFFER-VALUE = system.operat.descr.
  end.
end.

if InfoType = "WHOPERAT" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("IdOper",    "integer"). 
  DocumentData:ADD-NEW-FIELD ("DateOper",  "date"). 
  DocumentData:ADD-NEW-FIELD ("CountFrom", "character"). 
  DocumentData:ADD-NEW-FIELD ("CountTo",   "character"). 
  DocumentData:ADD-NEW-FIELD ("Anobj",     "character"). 
  DocumentData:ADD-NEW-FIELD ("Quan",      "character"). 
  DocumentData:ADD-NEW-FIELD ("Sum",       "character"). 
  DocumentData:ADD-NEW-FIELD ("BackFlag",  "logical"). 
  DocumentData:ADD-NEW-FIELD ("Motion",    "logical"). 
  DocumentData:ADD-NEW-FIELD ("Own",       "logical"). 
  DocumentData:ADD-NEW-FIELD ("Granted",   "logical"). 
  DocumentData:ADD-NEW-FIELD ("UseType",   "character"). 
  DocumentData:ADD-NEW-FIELD ("ObjectParam","character"). 
  DocumentData:ADD-NEW-FIELD ("BackDoc",   "character"). 
  DocumentData:ADD-NEW-FIELD ("Supplier",  "character"). 
  DocumentData:ADD-NEW-FIELD ("Buyer",     "character"). 
  DocumentData:ADD-NEW-FIELD ("SalePrice", "character"). 
  DocumentData:ADD-NEW-FIELD ("SumSecure", "character"). 
  DocumentData:ADD-NEW-FIELD ("SumChange", "character"). 
  DocumentData:ADD-NEW-FIELD ("SumChange2","character"). 
  DocumentData:ADD-NEW-FIELD ("SumToKeep", "character"). 
  DocumentData:ADD-NEW-FIELD ("SelMethod", "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","IdOper").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Дата,Date") fName = "DateOper" fWidth = 10 fType = "date" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Cчет с,Count from") fName = "CountFrom" fWidth = 15 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Счет на,Count to") fName = "CountTo" fWidth = 15 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Товар,Ware") fName = "Anobj" fWidth = 30 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Серия,Serial") fName = "ObjectParam" fWidth = 10 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Количество,Quantity") fName = "Quan" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Сумма,Sum") fName = "Sum" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Возврат,Return") fName = "BackFlag" fWidth = 6 fType = "box" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Парт.уч,LotAcc") fName = "Motion" fWidth = 6 fType = "box" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = Entry(l,"Собств.,Own") fName = "Own" fWidth = 6 fType = "box" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Дотация,Grant") fName = "Granted" fWidth = 6 fType = "box" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Возврат по,Return Doc") fName = "BackDoc" fWidth = 15 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Тип использования,Use type") fName = "UseType" fWidth = 15 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Поставщик,Supplier") fName = "Supplier" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Покупатель,Buyer") fName = "Buyer" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Цена продажи,Sale price") fName = "SalePrice" fWidth = 10 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Зал. Сумма,Sum2") fName = "SumSecure" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Измен. суммы,Sum change") fName = "SumChange" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Измен. зал.суммы,Sum2 change") fName = "SumChange2" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Стоим.хранения,Sum3") fName = "SumToKeep" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Метод выбора,Lot method") fName = "SelMethod" fWidth = 15 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.
  RUN src/kernel/isavgen.p ( 2 ).
  IF RETURN-VALUE = "NO" then RETURN.

  Find First system.cathg WHERE system.cathg.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.cathg then RETURN.
  Find First system.ctg-options OF system.cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.ctg-options then RETURN.

  DEFINE TEMP-TABLE work NO-UNDO
   FIELD count as character
   Field CountName as character
   INDEX i0 IS PRIMARY UNIQUE count.
  DEFINE BUFFER work2 FOR work.

  create work.
  work.count = "".
  work.CountName = "".
  create work.
  work.count = "0".
  work.CountName = "".

  IF system.ctg-options.is-allextacc then 
  do:
    FOR EACH system.ext-acc NO-LOCK :
      CREATE work.
      work.count = system.ext-acc.count.
      work.CountName = system.ext-acc.count + " " + system.ext-acc.acc-name.
    END.
  end.
  else do:
    for each system.ext-acc NO-LOCK,
        each system.ctg-extacc OF system.ext-acc
        where system.ctg-extacc.rid-cathg = currid-cathg NO-LOCK :
      create work.
      work.count = system.ext-acc.count.
      work.CountName = system.ext-acc.count + " " + system.ext-acc.acc-name.
    end.
  end.
  FOR EACH system.wh-operat WHERE system.wh-operat.rid-document = RidDoc NO-LOCK,
      EACH system.anobject OF system.wh-operat NO-LOCK,
      EACH work WHERE work.count = system.wh-operat.count-from,
      EACH work2 WHERE work2.count = system.wh-operat.count-to:

    hBuffer:BUFFER-CREATE().

    hBuffer:BUFFER-FIELD("IdOper"):BUFFER-VALUE = system.wh-operat.id-wh-operat.
    hBuffer:BUFFER-FIELD("DateOper"):BUFFER-VALUE = system.wh-operat.date-oper.
    hBuffer:BUFFER-FIELD("CountFrom"):BUFFER-VALUE = work.CountName.
    hBuffer:BUFFER-FIELD("CountTo"):BUFFER-VALUE = work2.CountName.
    hBuffer:BUFFER-FIELD("Anobj"):BUFFER-VALUE = system.anobject.name-anobject.
    hBuffer:BUFFER-FIELD("Quan"):BUFFER-VALUE = STRING(system.wh-operat.quantity, "->>,>>>,>>9.999").
    hBuffer:BUFFER-FIELD("Sum"):BUFFER-VALUE = STRING(system.wh-operat.sum, "->>>,>>>,>>9.99").
    hBuffer:BUFFER-FIELD("BackFlag"):BUFFER-VALUE = system.wh-operat.back-flag.
    hBuffer:BUFFER-FIELD("Motion"):BUFFER-VALUE = system.wh-operat.motion.
    hBuffer:BUFFER-FIELD("Own"):BUFFER-VALUE = system.wh-operat.own.
    hBuffer:BUFFER-FIELD("Granted"):BUFFER-VALUE = system.wh-operat.granted.

    hBuffer:BUFFER-FIELD("UseType"):BUFFER-VALUE = system.wh-operat.use-type.
    hBuffer:BUFFER-FIELD("ObjectParam"):BUFFER-VALUE = system.wh-operat.object-param.
    hBuffer:BUFFER-FIELD("SalePrice"):BUFFER-VALUE = STRING(system.wh-operat.sale-price, "->>>,>>9.99").
    hBuffer:BUFFER-FIELD("SumSecure"):BUFFER-VALUE = STRING(system.wh-operat.sum-secure, "->>>,>>>,>>9.99").
    hBuffer:BUFFER-FIELD("SumChange"):BUFFER-VALUE = STRING(system.wh-operat.sum-change, "->>>,>>>,>>9.99").
    hBuffer:BUFFER-FIELD("SumChange2"):BUFFER-VALUE = STRING(system.wh-operat.sum-sec-change, "->>>,>>>,>>9.99").
    hBuffer:BUFFER-FIELD("SumToKeep"):BUFFER-VALUE = STRING(system.wh-operat.sum-tokeep, "->>>,>>>,>>9.99").

    find first system.document where system.document.rid-document = system.wh-operat.rid-wh-operat NO-LOCK NO-ERROR.
    if available system.document then
    do:
      find first system.typedoc of system.document NO-LOCK NO-ERROR.
      if available system.typedoc then
        hBuffer:BUFFER-FIELD("BackDoc"):BUFFER-VALUE = system.typedoc.name-typedoc + " " + STRING(system.document.id-document).
    end.
    find first system.clients where system.clients.rid-clients = system.wh-operat.rid-clients NO-LOCK NO-ERROR.
    if available system.clients then
      hBuffer:BUFFER-FIELD("Supplier"):BUFFER-VALUE = string(system.clients.id-client) + " " + system.clients.name-client.
    find first system.clients where system.clients.rid-clients = system.wh-operat.rid-buyer NO-LOCK NO-ERROR.
    if available system.clients then
      hBuffer:BUFFER-FIELD("Buyer"):BUFFER-VALUE = string(system.clients.id-client) + " " + system.clients.name-client.

    if system.wh-operat.sel-method >= 1 and system.wh-operat.sel-method <= 6 then
      hBuffer:BUFFER-FIELD("SelMethod"):BUFFER-VALUE = ENTRY (system.wh-operat.sel-method, "FIFO,LIFO,Самый дешевый,Самый дорогой,Мин.Дельта,Мин.срок годности").
  end.                                                                            
END.

if InfoType = "PLANWHOPERAT" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("IdOper",    "integer"). 
  DocumentData:ADD-NEW-FIELD ("DateOper",  "date"). 
  DocumentData:ADD-NEW-FIELD ("Count",     "character"). 
  DocumentData:ADD-NEW-FIELD ("Ware" ,     "character"). 
  DocumentData:ADD-NEW-FIELD ("Quan",      "character"). 
  DocumentData:ADD-NEW-FIELD ("Sum",       "character"). 
  DocumentData:ADD-NEW-FIELD ("ObjectParam","character"). 
  DocumentData:ADD-NEW-FIELD ("Status",    "character"). 
  DocumentData:ADD-NEW-FIELD ("Model",     "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","IdOper").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Дата,Date") fName = "DateOper" fWidth = 10 fType = "date" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Cчет,Count") fName = "Count" fWidth = 15 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Товар,Ware") fName = "Ware" fWidth = 30 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Серия,Serial") fName = "ObjectParam" fWidth = 10 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Количество,Quantity") fName = "Quan" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Сумма,Sum") fName = "Sum" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Статус,Status") fName = "Status" fWidth = 15 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Плановая модель,Model") fName = "Model" fWidth = 15 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.

  Find First system.cathg WHERE system.cathg.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.cathg then RETURN.
  Find First system.ctg-options OF system.cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.ctg-options then RETURN.

  create work.
  work.count = "".
  work.CountName = "".
  create work.
  work.count = "0".
  work.CountName = "".

  IF system.ctg-options.is-allextacc then 
  do:
    FOR EACH system.ext-acc NO-LOCK :
      CREATE work.
      work.count = system.ext-acc.count.
      work.CountName = system.ext-acc.count + " " + system.ext-acc.acc-name.
    END.
  end.
  else do:
    for each system.ext-acc NO-LOCK,
        each system.ctg-extacc OF system.ext-acc
        where system.ctg-extacc.rid-cathg = currid-cathg NO-LOCK :
      create work.
      work.count = system.ext-acc.count.
      work.CountName = system.ext-acc.count + " " + system.ext-acc.acc-name.
    end.
  end.
  FOR EACH system.plan-wh-operat WHERE system.plan-wh-operat.rid-document = RidDoc NO-LOCK,
      EACH system.wares OF system.plan-wh-operat NO-LOCK,
      EACH work WHERE work.count = system.plan-wh-operat.count:

    hBuffer:BUFFER-CREATE().

    hBuffer:BUFFER-FIELD("IdOper"):BUFFER-VALUE = system.plan-wh-operat.id-plan-wh-operat.
    hBuffer:BUFFER-FIELD("DateOper"):BUFFER-VALUE = system.plan-wh-operat.date-oper.
    hBuffer:BUFFER-FIELD("Count"):BUFFER-VALUE = work.CountName.
    hBuffer:BUFFER-FIELD("Ware"):BUFFER-VALUE = system.wares.wares-name.
    hBuffer:BUFFER-FIELD("ObjectParam"):BUFFER-VALUE = system.plan-wh-operat.object-param.
    hBuffer:BUFFER-FIELD("Quan"):BUFFER-VALUE = STRING(system.plan-wh-operat.quantity, "->>,>>>,>>9.999").
    hBuffer:BUFFER-FIELD("Sum"):BUFFER-VALUE = STRING(system.plan-wh-operat.sum, "->>>,>>>,>>9.99").
    hBuffer:BUFFER-FIELD("Status"):BUFFER-VALUE = system.plan-wh-operat.op-status.

    find first system.PlanModel where system.PlanModel.rid-model = system.plan-wh-operat.rid-model NO-LOCK NO-ERROR.
    if available system.PlanModel then
      hBuffer:BUFFER-FIELD("Model"):BUFFER-VALUE = system.PlanModel.name-model.
  end.                                                                            
END.

if InfoType = "MROPERAT" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("DateOper",  "date"). 
  DocumentData:ADD-NEW-FIELD ("Fil",       "character"). 
  DocumentData:ADD-NEW-FIELD ("Count",     "character"). 
  DocumentData:ADD-NEW-FIELD ("Sum",       "character"). 
  DocumentData:ADD-NEW-FIELD ("Fact",      "logical"). 
  DocumentData:ADD-NEW-FIELD ("Plan",      "integer"). 
  DocumentData:ADD-NEW-FIELD ("Comment",   "character"). 
  DocumentData:ADD-NEW-FIELD ("FilFrom",   "character"). 
  DocumentData:ADD-NEW-FIELD ("Anobj",     "character"). 
  DocumentData:ADD-NEW-FIELD ("Ware",      "character"). 
  DocumentData:ADD-NEW-FIELD ("Client",    "character"). 
  DocumentData:ADD-NEW-FIELD ("Emp",       "character"). 
  DocumentData:ADD-NEW-FIELD ("Scenareio", "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","Count").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Дата,Date") fName = "DateOper" fWidth = 10 fType = "date" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Центр,WorkCenter") fName = "Fil" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Показатель,Indicator") fName = "Count" fWidth = 25 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Сумма,Sum") fName = "Sum" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Факт,FactValue") fName = "Fact" fWidth = 6 fType = "box" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"План,Acc.Plan") fName = "Plan" fWidth = 6 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Содержание операции,Description") fName = "Comment" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Центр с,Workcenter from") fName = "FilFrom" fWidth = 15 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Статья,Item") fName = "Anobj" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Товар,Ware") fName = "Ware" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Клиент,Client") fName = "Client" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Менеджер,Employeer") fName = "Emp" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Сценарий,Scenario") fName = "Scenario" fWidth = 20 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  define buffer filials2 for system.filials.

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.
  RUN src/kernel/isavgen.p ( 5 ).
  IF RETURN-VALUE = "NO" then RETURN.

  Find First system.cathg WHERE system.cathg.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.cathg then RETURN.
  Find First system.ctg-options OF system.cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.ctg-options then RETURN.

  if system.ctg-options.is-allaccplan then 
  do:
    FOR EACH system.acc-plan NO-LOCK :
      CREATE access-plans.
      access-plans.plan = system.acc-plan.plan.
    END.
  end.
  else do:
    FOR EACH system.acc-plan NO-LOCK,
        EACH system.ctg-accplan where system.ctg-accplan.plan = system.acc-plan.plan and 
             system.ctg-accplan.rid-cathg = system.ctg-options.rid-cathg NO-LOCK :
      CREATE access-plans.
      access-plans.plan = system.acc-plan.plan.
    END.
  end.  

  FOR EACH system.mr-operat WHERE system.mr-operat.rid-document = RidDoc NO-LOCK, 
      EACH system.mr-counts OF system.mr-operat NO-LOCK, 
      EACH system.filials OF system.mr-operat NO-LOCK:

    find first access-plans where access-plans.plan = system.mr-operat.plan NO-ERROR.
    if not available access-plans then NEXT.

    hBuffer:BUFFER-CREATE().

    hBuffer:BUFFER-FIELD("DateOper"):BUFFER-VALUE = system.mr-operat.oper-date.
    hBuffer:BUFFER-FIELD("Fil"):BUFFER-VALUE = system.filials.name-filial.
    hBuffer:BUFFER-FIELD("Count"):BUFFER-VALUE = system.mr-counts.count + " " + system.mr-counts.count-name.
    hBuffer:BUFFER-FIELD("Sum"):BUFFER-VALUE = STRING(system.mr-operat.sum, "->>>,>>>,>>9.99").
    hBuffer:BUFFER-FIELD("Fact"):BUFFER-VALUE = system.mr-operat.fact.
    hBuffer:BUFFER-FIELD("Plan"):BUFFER-VALUE = system.mr-operat.plan.
    hBuffer:BUFFER-FIELD("Comment"):BUFFER-VALUE = system.mr-operat.comment.

    find first filials2 where Filials2.rid-filials = system.mr-operat.from-filial NO-LOCK NO-ERROR.
    if available filials2 then
      hBuffer:BUFFER-FIELD("FilFrom"):BUFFER-VALUE = filials2.name-filial.
    find first system.anobject of system.mr-operat NO-LOCK NO-ERROR.
    if available system.anobject then
      hBuffer:BUFFER-FIELD("Anobj"):BUFFER-VALUE = system.anobject.name-anobject.
    find first system.wares where system.mr-operat.rid-wares = system.wares.rid-wares NO-LOCK NO-ERROR.
    if available system.wares then
      hBuffer:BUFFER-FIELD("Ware"):BUFFER-VALUE = system.wares.wares-name.
    find first system.clients where system.clients.rid-clients = system.mr-operat.rid-client NO-LOCK NO-ERROR.
    if available system.clients then
      hBuffer:BUFFER-FIELD("Client"):BUFFER-VALUE = string(system.clients.id-client) + " " + system.clients.name-client.
    find first system.employeers where system.employeers.rid-emp = system.mr-operat.rid-emp NO-LOCK NO-ERROR.
    if available system.employeers then
      hBuffer:BUFFER-FIELD("Emp"):BUFFER-VALUE = system.employeers.name-emp.
    find first system.bgt-scenario of system.mr-operat NO-LOCK NO-ERROR.
    if available system.bgt-scenario then
      hBuffer:BUFFER-FIELD("Scenario"):BUFFER-VALUE = system.bgt-scenario.name-scenario.
  END.
END.

if InfoType = "DOCRELATION" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("RidDocument", "integer"). 
  DocumentData:ADD-NEW-FIELD ("RidTypedoc" , "integer"). 
  DocumentData:ADD-NEW-FIELD ("DateDoc",     "date"). 
  DocumentData:ADD-NEW-FIELD ("TypedocName", "character"). 
  DocumentData:ADD-NEW-FIELD ("IdDoc",       "integer"). 

  DocumentData:ADD-NEW-FIELD ("Direction",   "character").
  DocumentData:ADD-NEW-FIELD ("RefType",     "character"). 
  DocumentData:ADD-NEW-FIELD ("Anobj",       "character").
  DocumentData:ADD-NEW-FIELD ("Sum",         "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","RefType").
  DocumentData:ADD-INDEX-FIELD("i0","RidDoc").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Связь,Direction") fName = "Direction" fWidth = 5 fType = "Text" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Дата,Date") fName = "DateDoc" fWidth = 10 fType = "date" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Тип документа,Document type") fName = "TypedocName" fWidth = 25 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Номер,Number") fName = "IdDoc" fWidth = 6 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Тип связи,Type") fName = "RefType" fWidth = 15 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Объект,Item") fName = "Anobj" fWidth = 25 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Сумма (Кол-во),Sum (Qnty)") fName = "Sum" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Вн.номер документа,Int.doc.number") fName = "RidDocument" fWidth = 15 fType = "Text" fAlign = "right".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.
  RUN src/kernel/isavgen.p ( 3 ).
  IF RETURN-VALUE = "NO" then RETURN.

  FOR EACH system.doc-relation WHERE system.doc-relation.rid-document = RidDoc NO-LOCK,
      EACH system.document WHERE system.document.rid-document = system.doc-relation.ref-document NO-LOCK,
      EACH system.typedoc OF system.document NO-LOCK :
      
    RUN src/kernel/docright.p ( system.document.rid-document ).
    IF INTEGER(RETURN-VALUE) < 1 THEN NEXT.

    hBuffer:BUFFER-CREATE().

    hBuffer:BUFFER-FIELD("Direction"):BUFFER-VALUE = "- >".
    hBuffer:BUFFER-FIELD("DateDoc"):BUFFER-VALUE = system.document.date-doc.
    hBuffer:BUFFER-FIELD("RidDocument"):BUFFER-VALUE = system.document.rid-document.
    hBuffer:BUFFER-FIELD("RidTypedoc"):BUFFER-VALUE = system.document.rid-typedoc.
    hBuffer:BUFFER-FIELD("TypedocName"):BUFFER-VALUE = "(" + STRING(system.typedoc.id-typedoc) + ") " + system.typedoc.name-typedoc.
    hBuffer:BUFFER-FIELD("IdDoc"):BUFFER-VALUE = system.document.id-document.
    hBuffer:BUFFER-FIELD("RefType"):BUFFER-VALUE = system.doc-relation.ref-type.
    hBuffer:BUFFER-FIELD("Sum"):BUFFER-VALUE = system.doc-relation.sum.

    IF system.doc-relation.rid-anobject <> RootOfAnobject THEN
    DO:
      FIND FIRST system.anobject WHERE system.anobject.rid-anobject = system.doc-relation.rid-anobject NO-LOCK NO-ERROR.
      IF AVAILABLE system.anobject THEN
        hBuffer:BUFFER-FIELD("Anobj"):BUFFER-VALUE = system.anobject.name-anobject.
    END.
  END.     

  FOR EACH system.doc-relation WHERE system.doc-relation.ref-document = RidDoc NO-LOCK,
      EACH system.document WHERE system.document.rid-document = system.doc-relation.rid-document NO-LOCK,
      EACH system.typedoc OF system.document NO-LOCK:
      
    RUN src/kernel/docright.p ( system.document.rid-document ).
    IF INTEGER(RETURN-VALUE) < 1 THEN NEXT.

    hBuffer:BUFFER-CREATE().

    hBuffer:BUFFER-FIELD("Direction"):BUFFER-VALUE = "< -".
    hBuffer:BUFFER-FIELD("DateDoc"):BUFFER-VALUE = system.document.date-doc.
    hBuffer:BUFFER-FIELD("RidDocument"):BUFFER-VALUE = system.document.rid-document.
    hBuffer:BUFFER-FIELD("RidTypedoc"):BUFFER-VALUE = system.document.rid-typedoc.
    hBuffer:BUFFER-FIELD("TypedocName"):BUFFER-VALUE = "(" + STRING(system.typedoc.id-typedoc) + ") " + system.typedoc.name-typedoc.
    hBuffer:BUFFER-FIELD("IdDoc"):BUFFER-VALUE = system.document.id-document.
    hBuffer:BUFFER-FIELD("RefType"):BUFFER-VALUE = system.doc-relation.ref-type.
    hBuffer:BUFFER-FIELD("Sum"):BUFFER-VALUE = system.doc-relation.sum.

    IF system.doc-relation.rid-anobject <> RootOfAnobject THEN
    DO:
      FIND FIRST system.anobject WHERE system.anobject.rid-anobject = system.doc-relation.rid-anobject NO-LOCK NO-ERROR.
      IF AVAILABLE system.anobject THEN
        hBuffer:BUFFER-FIELD("Anobj"):BUFFER-VALUE = system.anobject.name-anobject.
    END.
  END. 
END.

if InfoType = "WAGE" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("IdEmp",     "integer"). 
  DocumentData:ADD-NEW-FIELD ("IdItem",    "integer"). 
  DocumentData:ADD-NEW-FIELD ("DateWage",  "date"). 
  DocumentData:ADD-NEW-FIELD ("NameEmp",   "character"). 
  DocumentData:ADD-NEW-FIELD ("NameItem",  "character"). 
  DocumentData:ADD-NEW-FIELD ("ItemType",  "character"). 
  DocumentData:ADD-NEW-FIELD ("Sum",       "character"). 
  DocumentData:ADD-NEW-FIELD ("Days",      "character"). 
  DocumentData:ADD-NEW-FIELD ("Hours",     "character"). 
  DocumentData:ADD-NEW-FIELD ("Period",    "character"). 
  DocumentData:ADD-NEW-FIELD ("Fil",       "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","IdEmp").
  DocumentData:ADD-INDEX-FIELD("i0","IdItem").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Дата,Date") fName = "DateWage" fWidth = 10 fType = "date" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"ТабN,Id Emp") fName = "IdEmp" fWidth = 6 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Сотрудник,Employeer") fName = "NameEmp" fWidth = 25 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Код,Code") fName = "IdItem" fWidth = 6 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Статья,Item") fName = "NameItem" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Сумма,Sum") fName = "Sum" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Тип,Type") fName = "ItemType" fWidth = 5 fType = "Text" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Дней,Days") fName = "Days" fWidth = 10 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Часов,Hours") fName = "Hours" fWidth = 10 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Период,Period") fName = "Period" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Центр,Workcenter") fName = "Fil" fWidth = 20 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.
  RUN src/kernel/isavgen.p ( 4 ).
  IF RETURN-VALUE = "NO" then RETURN.

  FOR EACH system.wage NO-LOCK WHERE system.wage.rid-document = RidDoc,
      EACH system.vcalc-item OF system.wage NO-LOCK,
      EACH system.employeers OF system.wage NO-LOCK,
      EACH system.period NO-LOCK WHERE system.period.rid-period = system.wage.rid-per-rel
      BY system.employeers.id-emp
      BY system.vcalc-item.id-user-item:

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("DateWage"):BUFFER-VALUE = system.wage.date-wage.
    hBuffer:BUFFER-FIELD("IdEmp"):BUFFER-VALUE = system.employeers.id-emp.
    hBuffer:BUFFER-FIELD("NameEmp"):BUFFER-VALUE = system.employeers.name-emp.
    hBuffer:BUFFER-FIELD("IdItem"):BUFFER-VALUE = system.vcalc-item.id-user-item.
    hBuffer:BUFFER-FIELD("NameItem"):BUFFER-VALUE = system.vcalc-item.name-vcalc-item.
    if system.vcalc-item.flag-vcalc-item = true then
      hBuffer:BUFFER-FIELD("ItemType"):BUFFER-VALUE = ENTRY(l,"Начис,Ch.On").
    if system.vcalc-item.flag-vcalc-item = false then
      hBuffer:BUFFER-FIELD("ItemType"):BUFFER-VALUE = ENTRY(l,"Удер.,Ch.Off").
    if system.vcalc-item.flag-vcalc-item = ? then
      hBuffer:BUFFER-FIELD("ItemType"):BUFFER-VALUE = ENTRY(l,"Фонд,Fond").
    hBuffer:BUFFER-FIELD("Sum"):BUFFER-VALUE = STRING(system.wage.sum-wage, "->>>,>>>,>>9.99").
    if system.wage.quantity = ? then
      hBuffer:BUFFER-FIELD("Days"):BUFFER-VALUE = STRING(0, ">>>>9.9").
    else
      hBuffer:BUFFER-FIELD("Days"):BUFFER-VALUE = STRING(system.wage.quantity, ">>>>9.9").
    hBuffer:BUFFER-FIELD("Hours"):BUFFER-VALUE = STRING(system.wage.quan-hour, ">>>>9.9").
    hBuffer:BUFFER-FIELD("Period"):BUFFER-VALUE = STRING (system.period.date-begin,"99/99/9999") + "-" +  STRING (system.period.date-end,"99/99/9999").

    find first system.filials WHERE system.filials.rid-filials = system.wage.rid-filials NO-LOCK NO-ERROR.
    if available system.filials then
      hBuffer:BUFFER-FIELD("Fil"):BUFFER-VALUE = system.filials.name-filial.
  end.

END.

if InfoType = "RESERV" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("ReservType", "character"). 
  DocumentData:ADD-NEW-FIELD ("IdWh",       "integer"). 
  DocumentData:ADD-NEW-FIELD ("NameWh",     "character"). 
  DocumentData:ADD-NEW-FIELD ("WaresCode",  "character"). 
  DocumentData:ADD-NEW-FIELD ("WaresName",  "character"). 
  DocumentData:ADD-NEW-FIELD ("DateFrom",   "date"). 
  DocumentData:ADD-NEW-FIELD ("DateTo",     "date"). 
  DocumentData:ADD-NEW-FIELD ("Quan",       "character"). 
  DocumentData:ADD-NEW-FIELD ("Client",     "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","ReservType").
  DocumentData:ADD-INDEX-FIELD("i0","IdWh").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Тип резерва,Type") fName = "ReservType" fWidth = 10 fType = "Text" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Номер,Number") fName = "IdWh" fWidth = 6 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Склад,Warehouse") fName = "NameWh" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Код,Code") fName = "WaresCode" fWidth = 10 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Товар,Ware") fName = "WaresName" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Резерв с,From") fName = "DateFrom" fWidth = 10 fType = "date" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Резерв по,To") fName = "DateTo" fWidth = 10 fType = "date" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Количество,Quantity") fName = "Quan" fWidth = 15 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Клиент,Client") fName = "Client" fWidth = 30 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.

  FOR EACH system.reserv WHERE system.reserv.rid-document = RidDoc NO-LOCK,
      EACH system.warehouse OF system.reserv NO-LOCK,
      EACH system.wares OF system.reserv NO-LOCK,
      EACH system.clients OF system.reserv NO-LOCK
      BY system.reserv.reserv-type
      BY system.warehouse.id-wh:

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("ReservType"):BUFFER-VALUE = system.reserv.reserv-type.
    hBuffer:BUFFER-FIELD("IdWh"):BUFFER-VALUE = system.warehouse.id-wh.
    hBuffer:BUFFER-FIELD("NameWh"):BUFFER-VALUE = system.warehouse.name-wh.
    hBuffer:BUFFER-FIELD("WaresCode"):BUFFER-VALUE = system.wares.alfa-cod.
    hBuffer:BUFFER-FIELD("WaresName"):BUFFER-VALUE = system.wares.wares-name.
    hBuffer:BUFFER-FIELD("DateFrom"):BUFFER-VALUE = system.reserv.date-from.
    hBuffer:BUFFER-FIELD("DateTo"):BUFFER-VALUE = system.reserv.date-to.
    hBuffer:BUFFER-FIELD("Quan"):BUFFER-VALUE = STRING(system.reserv.quant, "->>>,>>>,>>9.999").
    hBuffer:BUFFER-FIELD("Client"):BUFFER-VALUE = string(system.clients.id-client) + " " + system.clients.name-client.
  END.
END.

if InfoType = "PARAM" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("IdParam",    "integer"). 
  DocumentData:ADD-NEW-FIELD ("NameParam",  "character"). 
  DocumentData:ADD-NEW-FIELD ("Value",      "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","IdParam").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Номер,Number") fName = "IdParam" fWidth = 6 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Параметр,Parameter") fName = "NameParam" fWidth = 30 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Значение,Value") fName = "Value" fWidth = 50 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.

  FOR EACH system.doc-param-val WHERE system.doc-param-val.rid-document = RidDoc NO-LOCK,
      EACH system.doc-param of system.doc-param-val NO-LOCK:

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IdParam"):BUFFER-VALUE = system.doc-param.id-param.
    hBuffer:BUFFER-FIELD("NameParam"):BUFFER-VALUE = system.doc-param.name.
    hBuffer:BUFFER-FIELD("Value"):BUFFER-VALUE = system.doc-param-val.val.
  end.
END.

if InfoType = "HISTORY" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("OperDate",   "date"). 
  DocumentData:ADD-NEW-FIELD ("OperTime",   "character"). 
  DocumentData:ADD-NEW-FIELD ("OperName",   "character"). 
  DocumentData:ADD-NEW-FIELD ("User",       "character"). 
  DocumentData:ADD-NEW-FIELD ("Cathg",      "character"). 
  DocumentData:ADD-NEW-FIELD ("Div",        "character"). 
  DocumentData:ADD-NEW-FIELD ("AppendInfo", "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","OperDate", "DESC").
  DocumentData:ADD-INDEX-FIELD("i0","OperTime", "DESC").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Дата,Date") fName = "OperDate" fWidth = 10 fType = "date" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Время,Time") fName = "OperTime" fWidth = 8 fType = "Text" fAlign = "center".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Oперация,Operation") fName = "OperName" fWidth = 15 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Пользователь,User") fName = "User" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Должность,Role") fName = "Cathg" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Подразделение,Division") fName = "Div" fWidth = 30 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Дополнительно,Append info") fName = "AppendInfo" fWidth = 50 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.

  FOR EACH system.journdoc WHERE system.journdoc.rid-document = RidDoc NO-LOCK,
      EACH system.typeoperdoc OF system.journdoc NO-LOCK,
      EACH system.cathg OF system.journdoc NO-LOCK,
      EACH system.ctg-division OF system.journdoc NO-LOCK,
      EACH system.users OF system.journdoc NO-LOCK:

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("OperDate"):BUFFER-VALUE = system.journdoc.operdate.
    hBuffer:BUFFER-FIELD("OperTime"):BUFFER-VALUE = system.journdoc.opertime.
    hBuffer:BUFFER-FIELD("OperName"):BUFFER-VALUE = system.typeoperdoc.oper-name2.
    hBuffer:BUFFER-FIELD("User"):BUFFER-VALUE = system.users.name.
    hBuffer:BUFFER-FIELD("Cathg"):BUFFER-VALUE = system.cathg.name.
    hBuffer:BUFFER-FIELD("Div"):BUFFER-VALUE = LEFT-TRIM ( system.ctg-division.code-division + " " + system.ctg-division.name-division ).
    hBuffer:BUFFER-FIELD("AppendInfo"):BUFFER-VALUE = system.journdoc.append-info.
  end.
END.

if InfoType = "AUDIT" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("OperDateTime",   "datetime-tz"). 
  DocumentData:ADD-NEW-FIELD ("OperName",   "character"). 
  DocumentData:ADD-NEW-FIELD ("User",       "character"). 
  DocumentData:ADD-NEW-FIELD ("UserName",   "character"). 
  DocumentData:ADD-NEW-FIELD ("UserIp",     "character"). 
  DocumentData:ADD-NEW-FIELD ("Cathg",      "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","OperDateTime", "DESC").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Дата и время,DateTime") fName = "OperDateTime" fWidth = 20 fType = "datetime" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Oперация,Operation") fName = "OperName" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Пользователь,User") fName = "User" fWidth = 10 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"ФИО,User name") fName = "UserName" fWidth = 25 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"IP адрес,IP address") fName = "UserIp" fWidth = 20 fType = "Text" fAlign = "left".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Должность,Role") fName = "Cathg" fWidth = 20 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.
  run src/system/auditright.p (uid, "read").
  if RETURN-VALUE <> "YES" then RETURN.

  /* Временно */
  if SETUSERID ("auditadmin", "auditadmin", "system") = false then RETURN.
  /* /Временно */

  run webservices/document/src/DocAuditInfo.p (INPUT-OUTPUT TABLE-HANDLE DocumentData, RidDoc) NO-ERROR.
END.

if InfoType = "ERRORS" then
do:
  create temp-table DocumentData.

  DocumentData:ADD-NEW-FIELD ("IdError",    "integer"). 
  DocumentData:ADD-NEW-FIELD ("Error",      "character"). 

  /* Умалчиваемая сортировка */
  DocumentData:ADD-NEW-INDEX("i0", false, true).
  DocumentData:ADD-INDEX-FIELD("i0","IdError", "ASC").

  create CollumnData. i = 1.
  assign IdField = i fLabel = ENTRY(l,"Номер,Number") fName = "IdError" fWidth = 10 fType = "Text" fAlign = "right".
  create CollumnData. i = i + 1.
  assign IdField = i fLabel = ENTRY(l,"Текст ошибки,Error") fName = "Error" fWidth = 80 fType = "Text" fAlign = "left".

  DocumentData:TEMP-TABLE-PREPARE ("DocumentData").
  CREATE BUFFER hBuffer FOR TABLE DocumentData:DEFAULT-BUFFER-HANDLE.
  CREATE QUERY hQuery.
  hQuery:SET-BUFFERS(hBuffer).

  run src/kernel/docright.p ( RidDoc ).
  if INTEGER(RETURN-VALUE) < 1 then RETURN.

  define variable j as integer.
  define variable N as integer.
  define variable k as integer.
  find first document where document.rid-document = RidDoc NO-LOCK NO-ERROR.
  if available document then
  do:
    N = NUM-ENTRIES(document.error-descr, "#").
    k = 0.
    do j = 1 to N:
      if ENTRY(j,document.error-descr, "#") = "" then NEXT.
      k = k + 1.
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IdError"):BUFFER-VALUE = k.
      hBuffer:BUFFER-FIELD("Error"):BUFFER-VALUE = ENTRY(j,document.error-descr, "#").
    end.
  end.
END.
