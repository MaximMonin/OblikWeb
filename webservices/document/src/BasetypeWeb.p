/* Copyright (C) Maxim A. Monin 2009-2010 */

define input parameter basetype as character.
define input parameter AppendParam as character.
define input parameter ContextParam as character.
define input parameter SearchString as character.
define input-output parameter AllRecords as logical.
define output parameter TABLE-HANDLE SearchData.

define shared variable currid-cathg as integer.
define shared variable RootOfAnobject as integer.
define shared variable rid-ent as integer.
define shared variable uid as character.
DEF SHARED TEMP-TABLE querydoc NO-UNDO
  FIELD recnum AS INTEGER
  FIELD riddoc LIKE system.document.rid-document
  INDEX num IS PRIMARY recnum
  INDEX doc riddoc.

DEFINE variable hQuery           AS HANDLE NO-UNDO.
DEFINE variable hBuffer          AS HANDLE NO-UNDO.
DEFINE VARIABLE hBufferField     AS HANDLE NO-UNDO.
define variable itemcount        as integer no-undo.
define variable btime            as datetime.

&Scoped-define STR-TO-FLD             1
&Scoped-define STR-TO-FRM             2

create temp-table SearchData.
SearchData:ADD-NEW-FIELD   ("IntValue", "character"). 
SearchData:ADD-NEW-FIELD   ("FormValue", "character"). 

if basetype = "DOCUMENT" or basetype = "DOC_W_SEL" then
do:
  SearchData:ADD-NEW-FIELD   ("IdDoc", "integer"). 
  SearchData:ADD-NEW-FIELD   ("DateDoc", "date"). 
  SearchData:ADD-NEW-FIELD   ("DateDoc1", "character"). 
  SearchData:ADD-NEW-FIELD   ("Descr", "character"). 
  SearchData:ADD-NEW-FIELD   ("SumDoc", "decimal"). 
  SearchData:ADD-NEW-INDEX   ("i0", false, true).
  SearchData:ADD-INDEX-FIELD ("i0","DateDoc", "desc").
  SearchData:ADD-INDEX-FIELD ("i0","IdDoc", "desc").
end.

if basetype = "ACCOUNT" or basetype = "AMORT-ID" or basetype begins "RECID" or 
   basetype = "ANIMINV" or basetype = "APND-OBJ" or basetype = "APPLICAT" or
   basetype = "BLREGION" or basetype = "CAR" or basetype = "CAR2" or 
   basetype = "CAREXT" or basetype = "CITY" or basetype = "CLNBANKACC" or
   basetype = "CONTRACT" or basetype = "COUNTRY" or basetype = "CTGDIVIS" or
   basetype = "DIRTOPIC" or basetype = "DIRTOPI2" or basetype = "DIVISION" or
   basetype = "DIVISION2" or basetype = "DOG-CLN" or basetype = "DRIVER2" or
   basetype = "ENTLIST" or basetype = "EXTACC" or basetype = "FILE" or
   basetype = "HOUSE" or basetype = "INVENTORY" or basetype = "LS" or
   basetype = "MEASUNIT" or basetype = "MRCOUNT" or basetype = "PRODUCT" or
   basetype = "REGION" or basetype = "STREET" or basetype = "GEO-TERRIT" or
   basetype = "ROUTING" or basetype = "SEC-OWNER" or basetype = "SECTOR" or
   basetype = "SERIES" or basetype = "SERIESDT" or basetype = "SERIESWH" or
   (basetype matches "*WARE*" and not basetype matches "WAREH*") or 
   basetype = "TIMETYPE" or basetype = "TIMETYPE2" or
   basetype = "TRANSORDER" or basetype = "TWORK" or basetype = "USERS" or
   basetype = "VPOS-DIV" or basetype = "VPOSITCLS" or basetype = "WRPARVAL"
then do:
  SearchData:ADD-NEW-FIELD   ("IdValue", "character"). 
end.
else if basetype = "PERIOD" or basetype = "PERIOD2" or basetype = "SEC-ISSUE" then
do:
  SearchData:ADD-NEW-FIELD   ("IdValue", "date"). 
  SearchData:ADD-NEW-INDEX   ("i0", false, true).
  SearchData:ADD-INDEX-FIELD ("i0","IdValue", "desc").
end.
else do:
  SearchData:ADD-NEW-FIELD   ("IdValue", "integer"). 
end.

if not (basetype = "DOCUMENT" or basetype = "DOC_W_SEL" or 
   basetype = "PERIOD" or basetype = "PERIOD2" or basetype = "SEC-ISSUE") then
do:
  SearchData:ADD-NEW-INDEX   ("i0", false, true).
  SearchData:ADD-INDEX-FIELD ("i0","IdValue").
end.

SearchData:TEMP-TABLE-PREPARE ("SearchData").
CREATE BUFFER hBuffer FOR TABLE SearchData:DEFAULT-BUFFER-HANDLE.

if AllRecords then
  itemcount = 1000.
else
  itemcount = 10.


if basetype = "ACC-PLAN" then
do:
  for each system.acc-plan no-lock where AllRecords OR
    (string(system.acc-plan.plan) + " " + system.acc-plan.name-plan) matches "*" + searchstring + "*":

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.acc-plan.plan).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.acc-plan.plan.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.acc-plan.plan) + " " + system.acc-plan.name-plan.
  end.
end.

if basetype = "ACC-TYPE" then
do:
  for each system.acc-type no-lock where AllRecords OR
    system.acc-type.name-acc-type matches "*" + searchstring + "*":

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.acc-type.rid-acc-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.acc-type.id-acc-type.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      system.acc-type.name-acc-type.
  end.
end.

if basetype = "ACCOUNT" then
do:
  define Temp-Table AvailPlans NO-UNDO
    field plan as integer
    index i0 plan.
  define Temp-Table anal-filter NO-UNDO
    field rid-anobject as integer
    index i0 rid-anobject.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  run AccountFilter (AppendParam).

  for each system.accounts no-lock where (AllRecords OR
      (system.accounts.count1 + " " + system.accounts.account-name) matches "*" + searchstring + "*"
    )
    and system.accounts.transit = false,
    each AvailPlans where AvailPlans.plan = system.accounts.plan,
    EACH anal-filter WHERE anal-filter.rid-anobject = system.accounts.rid-anobject
    by system.accounts.count1:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.accounts.count1).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.accounts.count1.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      system.accounts.count1 + " " + system.accounts.account-name.
  end.
end.

if basetype = "AMORT-ID" then
do:
  DEFINE VARIABLE rid-acc-type AS INTEGER NO-UNDO.
  DEFINE VARIABLE id-acc-type  AS INTEGER NO-UNDO.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  id-acc-type = INTEGER (AppendParam) NO-ERROR.
  FIND FIRST acc-type WHERE
             acc-type.id-acc-type = id-acc-type NO-LOCK NO-ERROR.
  IF AVAILABLE acc-type THEN
    rid-acc-type = acc-type.rid-acc-type.
  
  for each system.amort-group no-lock
      WHERE system.amort-group.rid-acc-type = rid-acc-type,
      each system.amort-code of system.amort-group NO-LOCK
      where system.amort-code.hidden = false and
      (AllRecords OR (system.amort-code.id-ac + " " + system.amort-code.name-ac) 
      matches "*" + searchstring + "*"):

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.amort-code.rid-ac).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.amort-code.id-ac.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      system.amort-code.id-ac + " " + system.amort-code.name-ac.
  end.
end.
if basetype = "INV-GROUP" then
do:
  if ContextParam <> "" then
    AppendParam = ContextParam.
  id-acc-type = INTEGER (AppendParam) NO-ERROR.
  FIND FIRST acc-type WHERE
             acc-type.id-acc-type = id-acc-type NO-LOCK NO-ERROR.
  IF AVAILABLE acc-type THEN
    rid-acc-type = acc-type.rid-acc-type.
  
  for each system.amort-group no-lock
      WHERE system.amort-group.rid-acc-type = rid-acc-type
      and
      (AllRecords OR (STRING(system.amort-group.id-ag) + " " + system.amort-group.name-ag) 
      matches "*" + searchstring + "*"):

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.amort-group.rid-ag).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.amort-group.id-ag.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      STRING(system.amort-group.id-ag) + " " + system.amort-group.name-ag.
  end.
end.


if basetype = "AN-TYPE" then
do:
  for each system.anobject no-lock where (AllRecords OR
    (string(system.anobject.id-anobject) + " " + system.anobject.name-anobject matches "*" + searchstring + "*"))
    and system.anobject.rid-upobject = RootOfAnobject
    by system.anobject.id-anobject:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.anobject.rid-anobject).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.anobject.id-anobject.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.anobject.id-anobject) + " " + system.anobject.name-anobject.
  end.
end.
if basetype = "RECID" or basetype = "RECID2" then
do:
  define variable an-code as character.
  define variable rootan-code as character.
  define variable root-an as integer.
  define buffer anobject2 for system.anobject.

  btime = now.
  if ContextParam <> "" then AppendParam = ContextParam.
  root-an = INTEGER(AppendParam) NO-ERROR.
  RUN src/kernel/ridtoobj.p ( root-an, OUTPUT rootan-code ).

  if INDEX ("0123456789", substring (searchstring, 1, 1)) > 0 then
  do:
    for each system.anobject no-lock 
      by system.anobject.id-anobject:

      RUN src/kernel/ridtoobj.p ( system.anobject.rid-anobject, OUTPUT an-code ).

      if not (an-code begins searchstring) then NEXT.
      if root-an <> 0 and root-an <> RootOfAnobject then
      do:
        if not (an-code + ":" begins rootan-code + ":") then NEXT.
      end.

      if basetype = "RECID" then
      do:
        if can-find ( first anobject2 where anobject2.rid-upobject = system.anobject.rid-anobject ) then
          NEXT.
      end.

      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.

      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.anobject.rid-anobject).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  an-code.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = an-code + " " + system.anobject.name-anobject.
/*
      if now - btime > 500 and not AllRecords then leave.
*/
    end.
  end.
  else
  do:
    for each system.anobject no-lock where /* AllRecords OR */
      (system.anobject.name-anobject matches "*" + searchstring + "*")
      by system.anobject.id-anobject:

      RUN src/kernel/ridtoobj.p ( system.anobject.rid-anobject, OUTPUT an-code ).
      if root-an <> 0 and root-an <> RootOfAnobject then
      do:
        if not (an-code + ":" begins rootan-code + ":") then NEXT.
      end.

      if basetype = "RECID" then
      do:
        if can-find ( first anobject2 where anobject2.rid-upobject = system.anobject.rid-anobject ) then
          NEXT.
      end.

      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.

      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.anobject.rid-anobject).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  an-code.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = an-code + " " + system.anobject.name-anobject.
/*
      if now - btime > 500 and not AllRecords then leave.
*/
    end.
  end.
  AllRecords = false.
end.

if basetype = "ANIMINV" then
do:
  for each system.animal-card no-lock where AllRecords OR
    system.animal-card.inv-number + " " + system.animal-card.animal-name matches "*" + searchstring + "*"
    by system.animal-card.inv-number:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.animal-card.rid-animal).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.animal-card.inv-number.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      system.animal-card.inv-number + " " + system.animal-card.animal-name.
  end.
end.
if basetype = "BREED" then
do:
  for each system.animal-breed no-lock where AllRecords OR
    STRING(system.animal-breed.id-breed) + " " + system.animal-breed.name-breed matches "*" + searchstring + "*"
    by system.animal-breed.id-breed:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.animal-breed.rid-ab).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.animal-breed.id-breed.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      STRING(system.animal-breed.id-breed) + " " + system.animal-breed.name-breed.
  end.
end.

if basetype = "ANY" then
do:
end.

if basetype = "APND-OBJ" then
do:
  define variable ao-count as character.
  define variable id-apndobj as integer.
  define variable ao-bstype as character.
  define variable bstype-proc as character.
  define variable ao-name as character.

  def var ridval as character.
  def var idval as character.
  def var scrval as character.
  ao-count = ContextParam.

  if ao-count = "" then
  do:
    ao-bstype = "RECID2".
    AppendParam = STRING (RootOfAnobject).
    ao-name = "Аналитика".
  end.
  else do:
    id-apndobj = INTEGER ( AppendParam ).
    Find First apnd-count-obj WHERE
               apnd-count-obj.count = ao-count and
               apnd-count-obj.id-obj = id-apndobj NO-LOCK NO-ERROR.
    IF NOT AVAILABLE apnd-count-obj then RETURN.

    ao-bstype = apnd-count-obj.basetype.
    AppendParam = apnd-count-obj.append-info.
    ao-name = apnd-count-obj.name-obj.
  end.

  Find First system.basetype WHERE system.basetype.base-type = ao-bstype NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.basetype then RETURN.
  bstype-proc = system.basetype.procfile.

  if ao-bstype = "DIRCONST" then ContextParam = AppendParam.
  else ContextParam = "".
  
  define variable SearchData2      as HANDLE NO-UNDO.
  DEFINE variable hQueryData       AS HANDLE NO-UNDO.
  DEFINE variable hBufferData      AS HANDLE NO-UNDO.

  run webservices/document/src/BasetypeWeb.p ( ao-bstype, AppendParam, ContextParam, 
    SearchString, input-output AllRecords, output table-handle SearchData2).

  CREATE QUERY hQueryData.
  CREATE BUFFER hBufferData FOR TABLE SearchData2.
  hQueryData:SET-BUFFERS(hBufferData).
  hQueryData:QUERY-PREPARE("FOR EACH SearchData NO-LOCK").
  hQueryData:QUERY-OPEN.
  hQueryData:GET-FIRST ().
  repeat:
    if hQueryData:QUERY-OFF-END then leave.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    ridval = hBufferData:BUFFER-FIELD("IntValue"):BUFFER-VALUE.
    idval = ridval.
    scrval = ridval.
    RUN VALUE ( bstype-proc ) ( {&STR-TO-FLD},
       input-output idval, "", INPUT-OUTPUT AppendParam ). 
    if ao-bstype = "WARE" then /* Для товаров храниться код аналитики а не код товара */ 
      run src/kernel/wr_toobj.p ( idval, OUTPUT idval ).
    RUN VALUE ( bstype-proc ) ( {&STR-TO-FRM},
      input-output scrval, "", INPUT-OUTPUT AppendParam ).   
    ridval = ridval + "|" + idval + "|" + scrval + "|" + ao-name.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = ridval.
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  idval.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = scrval.
    hQueryData:GET-NEXT ().
  end.
end.

if basetype = "APPLICAT" then
do:
  for each system.applicat no-lock where AllRecords OR
    system.applicat.compres-name + " " + system.applicat.name matches "*" + searchstring + "*"
    by system.applicat.compres-name:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.applicat.rid-app).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.applicat.name.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      system.applicat.compres-name + " " + system.applicat.name.
  end.
end.

if basetype = "ASSET" then basetype = "WARE".
if basetype = "ASSETLIST" then basetype = "WARELIST".

if basetype = "AUTOCADE" then
do:
  for each system.autocade no-lock where AllRecords OR
    string(system.autocade.id-autocade) + " " + system.autocade.name-autocade matches "*" + searchstring + "*"
    by system.autocade.id-autocade:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.autocade.rid-autocade).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.autocade.id-autocade.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.autocade.id-autocade) + " " + system.autocade.name-autocade.
  end.
end.

if basetype = "BANKACC" then
do:
  for each system.bankacc no-lock where AllRecords OR
    string(system.bankacc.id-bankacc) + " " + system.bankacc.ba-name matches "*" + searchstring + "*"
    by system.bankacc.id-bankacc:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bankacc.rid-bankacc).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bankacc.id-bankacc.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.bankacc.id-bankacc) + " " + system.bankacc.ba-name.
  end.
end.

if basetype = "BANKPAY" then
do:
  for each system.bank-pay no-lock where AllRecords OR
    string(system.bank-pay.mfo-bank-pay) + " " + system.bank-pay.name-bank-pay matches "*" + searchstring + "*"
    by system.bank-pay.mfo-bank-pay:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bank-pay.rid-bank-pay).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bank-pay.mfo-bank-pay.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.bank-pay.mfo-bank-pay) + " " + system.bank-pay.name-bank-pay.
  end.
end.

if basetype = "BGTPER" then
do:
  define variable rid-scen as integer.

  if ContextParam <> "" then AppendParam = ContextParam.
  rid-scen = INTEGER(AppendParam).

  for each system.bgt-period no-lock where (AllRecords OR
    string(system.bgt-period.id-step) + " " + system.bgt-period.name-step matches "*" + searchstring + "*")
    and system.bgt-period.rid-scenario = rid-scen
    by system.bgt-period.id-step:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bgt-period.rid-bgt-period).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bgt-period.id-step.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.bgt-period.id-step) + " " + system.bgt-period.name-step.
  end.
end.
if basetype = "BGTSCEN" then
do:
  for each system.bgt-scenario no-lock where AllRecords OR
    system.bgt-scenario.name-scenario matches "*" + searchstring + "*"
    by system.bgt-scenario.id-scenario:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bgt-scenario.rid-scenario).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bgt-scenario.id-scenario.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.bgt-scenario.name-scenario.
  end.
end.

if basetype = "BLCLIENT" then
do:
  for each system.bl-client no-lock,
      each clients NO-LOCK where bl-client.rid-clients = clients.rid-clients AND
      ( AllRecords OR
       string(system.clients.id-client) + " " + system.clients.name-client matches "*" + searchstring + "*")
      by system.clients.id-client:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bl-client.id-client).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.clients.id-client.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.clients.id-client) + " " + system.clients.name-client + " " + bl-client.seq_name.
  end.
end.
if basetype = "BLCORP" then
do:
  for each system.bl-corp no-lock where AllRecords OR
    string(system.bl-corp.id-corp) + " " + system.bl-corp.name-corp matches "*" + searchstring + "*"
    by system.bl-corp.id-corp:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bl-corp.rid-corp).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bl-corp.id-corp.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = STRING(system.bl-corp.id-corp) + " " + system.bl-corp.name-corp.
  end.
end.
if basetype = "BLDEVICE" then
do:
  for each system.bl-device no-lock where AllRecords OR
    string(system.bl-device.id-device) + " " + system.bl-device.name-device matches "*" + searchstring + "*"
    by system.bl-device.id-device:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bl-device.rid-device).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bl-device.id-device.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = STRING(system.bl-device.id-device) + " " + system.bl-device.name-device.
  end.
end.
if basetype = "BLREGION" then
do:
  for each system.bl-region no-lock where AllRecords OR
    system.bl-region.region matches "*" + searchstring + "*"
    by system.bl-region.region:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bl-region.rid-region).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bl-region.region.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.bl-region.region.
  end.
end.
if basetype = "BLSIGN" then
do:
  for each system.bl-sign no-lock where AllRecords OR
    system.bl-sign.name-sign matches "*" + searchstring + "*"
    by system.bl-sign.id-sign:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bl-sign.id-sign).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bl-sign.id-sign.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.bl-sign.name-sign.
  end.
end.

if basetype = "BOM" then
do:
  define variable bom-wares as integer.
  define variable bom-date as date.
  bom-date = today.

  if ContextParam <> "" then AppendParam = ContextParam.
  if AppendParam <> "" then
  do:
    bom-wares = integer(entry(1, AppendParam)).
    if num-entries (AppendParam) > 1 then
      bom-date = date(entry(2, AppendParam)).

    for each system.bom-item no-lock where AllRecords OR
      string(system.bom-item.id-bom-item) + " " + system.bom-item.name-bom-item matches "*" + searchstring + "*",
      each system.bom-wares of system.bom-item NO-LOCK
      WHERE system.bom-wares.rid-wares = bom-wares
      AND (system.bom-wares.bom-w-date-b <= bom-date or
           system.bom-wares.bom-w-date-b = ?) 
      AND (system.bom-wares.bom-w-date-e >= bom-date or
           system.bom-wares.bom-w-date-e = ?)
      by system.bom-item.id-bom-item:
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bom-item.rid-bom-item).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bom-item.id-bom-item.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(system.bom-item.id-bom-item) + " " + system.bom-item.name-bom-item.
    end.
  end.
  else do:
    for each system.bom-item no-lock where AllRecords OR
      string(system.bom-item.id-bom-item) + " " + system.bom-item.name-bom-item matches "*" + searchstring + "*"
      by system.bom-item.id-bom-item:
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.bom-item.rid-bom-item).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.bom-item.id-bom-item.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(system.bom-item.id-bom-item) + " " + system.bom-item.name-bom-item.
    end.
  end.
end.

if basetype = "CALCTYPE" then
do:
  for each system.tr-cal-type no-lock where AllRecords OR
    string(system.tr-cal-type.id-cal-type) + " " + system.tr-cal-type.name-cal-type matches "*" + searchstring + "*"
    by system.tr-cal-type.id-cal-type:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.tr-cal-type.rid-cal-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.tr-cal-type.id-cal-type.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.tr-cal-type.id-cal-type) + " " + system.tr-cal-type.name-cal-type.
  end.
end.

if basetype = "CAPACITY" then
do:
  define variable cap-wc as integer.
  
  if ContextParam <> "" then AppendParam = ContextParam.
  if AppendParam <> "" then cap-wc = INTEGER(AppendParam).
  else cap-wc = ?.

  for each system.capacity no-lock where (cap-wc = ? or system.capacity.rid-workcenter = cap-wc) AND
    (AllRecords OR
    string(system.capacity.id-capacity) + " " + system.capacity.name-capacity matches "*" + searchstring + "*")
    by system.capacity.id-capacity:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.capacity.rid-capacity).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.capacity.id-capacity.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.capacity.id-capacity) + " " + system.capacity.name-capacity.
  end.
end.

if basetype = "CAR" or basetype = "CAR2" or basetype = "TRAKT" then
do:
  define variable car-form-value as character.
  define variable car-cad as integer. /* Автоколонна */
  define variable car-date as date.
  define variable car-mark as integer.
  define variable car-group as integer.
  define variable cstr as character.
  define variable cstr1 as character.
  define variable car-found as logical.
  car-date = today.
  car-mark = ?.
  car-group = ?.
  car-cad = ?.

  if ContextParam <> "" then AppendParam = ContextParam.
  if AppendParam begins "par:" then
  do:
    cstr = AppendParam.
    cstr1 = ENTRY( 1, cstr, ":").
    cstr  = SUBSTRING( cstr, LENGTH(cstr1) + 2 ).
    cstr1 = ENTRY( 1, cstr, ":").
    car-date = DATE (cstr1).
    cstr  = SUBSTRING( cstr, LENGTH(cstr1) + 2 ).

    do while cstr <> "":
      cstr1 = ENTRY( 1, cstr, ":").
      cstr  = SUBSTRING( cstr, LENGTH(cstr1) + 2 ).

      case ENTRY (1, cstr1):
        when "mark" then
        do:
          if ENTRY(2, cstr1) = "?" then
            car-mark = ?.
          else
            car-mark = INTEGER(ENTRY(2, cstr1)).
        end.
        when "autocad" then
        do:
          if ENTRY(2, cstr1) = "?" then
            car-cad = ?.
          else
            car-cad = INTEGER(ENTRY(2, cstr1)).
        end.
        when "group" then
        do:
          if ENTRY(2, cstr1) = "?" then
            car-group = ?.
          else
            car-group = INTEGER(ENTRY(2, cstr1)).
        end.
      end.
    end.
  end.
  else do:
    if AppendParam <> "" then
    do:
      car-cad = integer (entry(1,AppendParam)).
      if num-entries (AppendParam) > 1 then
        car-date = date (entry(2,AppendParam)).
    end.
  end.

  FOR EACH system.car NO-LOCK WHERE AllRecords OR
    system.car.car-numb MATCHES "*" + searchstring + "*"
    by system.car.car-numb:

    if car-cad <> ? then
    do:
      car-found = false.
      FOR FIRST system.car-appoint of system.car NO-LOCK WHERE
         system.car-appoint.date-rec <= car-date,
          FIRST system.autocade of system.car-appoint NO-LOCK WHERE
         system.autocade.id-autocade = car-cad:

         car-found = true.
      END.
      if car-found = false then NEXT.
    end.
    if car-mark <> ? then
    do:
      find first system.car-mark of system.car where system.car-mark.id-car-mark = car-mark NO-LOCK NO-ERROR.
      if not available system.car-mark then NEXT.
    end.
    if car-group <> ? then
    do:
      find first system.car-group of system.car where system.car-group.id-car-group = car-group NO-LOCK NO-ERROR.
      if not available system.car-group then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    car-form-value = system.car.car-numb.
    if basetype = "CAR" or basetype = "TRAKT" then
    do:
      find first system.wares of system.car no-lock no-error.
      IF AVAILABLE system.wares THEN
        car-form-value = car-form-value + " " + system.wares.wares-name.
      else do:
        find first system.car-mark of system.car NO-LOCK NO-ERROR.
        if available system.car-mark then
          car-form-value = car-form-value + " " + system.car-mark.pasp-name.
      end.
    end.

    if basetype = "CAR2" then
    do:
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = car-form-value.
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  car-form-value.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = car-form-value.
    end.
    else do:
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.car.rid-car).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.car.car-numb.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = car-form-value.
    end.
  end.
end.
if basetype = "CAREXT" then
do:
  FOR EACH system.carext NO-LOCK WHERE AllRecords OR
    system.carext.carext-numb MATCHES "*" + searchstring + "*"
    by system.carext.carext-numb:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    car-form-value = system.carext.carext-numb.
    find first system.carext-mark of system.carext NO-LOCK NO-ERROR.
    if available system.carext-mark then
      car-form-value = car-form-value + " " + system.carext-mark.name-carext-mark.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.carext.rid-carext).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.carext.carext-numb.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = car-form-value.
  end.
end.
if basetype = "CAR-MARK" or basetype = "CAR-MARK2" then
do:
  for each system.car-mark no-lock where AllRecords OR
    string(system.car-mark.id-car-mark) + " " + system.car-mark.pasp-name matches "*" + searchstring + "*"
    by system.car-mark.id-car-mark:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    if basetype = "CAR-MARK2" then
    do:
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = system.car-mark.pasp-name.
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.car-mark.id-car-mark.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.car-mark.pasp-name.
    end.
    else do:
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.car-mark.rid-car-mark).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.car-mark.id-car-mark.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(system.car-mark.id-car-mark) + " " + system.car-mark.pasp-name.
    end.
  end.
end.
if basetype = "CAREXTMARK" then
do:
  for each system.carext-mark no-lock where AllRecords OR
    string(system.carext-mark.id-carext-mark) + " " + system.carext-mark.name-carext-mark matches "*" + searchstring + "*"
    by system.carext-mark.id-carext-mark:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.carext-mark.rid-carext-mark).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.carext-mark.id-carext-mark.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.carext-mark.id-carext-mark) + " " + system.carext-mark.name-carext-mark.
  end.
end.
if basetype = "CAR-GROUP" then
do:
  for each system.car-group no-lock where AllRecords OR
    string(system.car-group.id-car-group) + " " + system.car-group.name-car-group matches "*" + searchstring + "*"
    by system.car-group.id-car-group:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.car-group.rid-car-group).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.car-group.id-car-group.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.car-group.id-car-group) + " " + system.car-group.name-car-group.
  end.
end.

if basetype = "CASHBOOK" then
do:
  for each system.cashbooks no-lock where AllRecords OR
    string(system.cashbooks.id-cb) + " " + system.cashbooks.name-cb matches "*" + searchstring + "*"
    by system.cashbooks.id-cb:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.cashbooks.rid-cb).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.cashbooks.id-cb.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.cashbooks.id-cb) + " " + system.cashbooks.name-cb.
  end.
end.

if basetype = "CL-PARAM" then
do:
  for each system.client-param no-lock where AllRecords OR
    string(system.client-param.id-param) + " " + system.client-param.name-param matches "*" + searchstring + "*"
    by system.client-param.id-param:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.client-param.rid-param).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.client-param.id-param.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.client-param.id-param) + " " + system.client-param.name-param.
  end.
end.
if basetype = "CLIENTS" or basetype = "CLI-CONTR" then
do:
  define variable con-found as logical.
  define variable con-fvalue as character.

  if AllRecords then itemcount = 5000.
  for each system.clients no-lock where AllRecords OR
    string(system.clients.id-client) + " " + system.clients.name-client matches "*" + searchstring + "*"
    by system.clients.id-client:

    con-found = false.
    if basetype = "CLI-CONTR" then
    do:
      for each anobject WHERE anobject.rid-upobject = system.clients.rid-anobject NO-LOCK,
          EACH contract NO-LOCK WHERE contract.rid-anobject = anobject.rid-anobject AND contract.fl_closed = no:
        con-found = true.
      end.
    end.

    if con-found then
    do:
      for each anobject WHERE anobject.rid-upobject = system.clients.rid-anobject NO-LOCK,
           EACH contract NO-LOCK WHERE contract.rid-anobject = anobject.rid-anobject AND contract.fl_closed = no:

        itemcount = itemcount - 1.
        if itemcount < 0 /* and not AllRecords */ then leave.
  
        con-fvalue = string(system.clients.id-client) + " " + system.clients.name-client + " (Дог. № ".
        if contract.reg-contract <> ? then
          con-fvalue = con-fvalue + STRING( contract.reg-contract  ).
        else
          con-fvalue = con-fvalue + "?".
        con-fvalue = con-fvalue + " от ".
        if contract.date-contract <> ? then
          con-fvalue = con-fvalue + STRING( contract.date-contract ).
        else
          con-fvalue = con-fvalue + "?".
        con-fvalue = con-fvalue + ")".
        hBuffer:BUFFER-CREATE().
        hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.contract.rid-contract).
        hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.clients.id-client.
        hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = con-fvalue.

      end.
    end.
    else do:
      itemcount = itemcount - 1.
      if itemcount < 0 /* and not AllRecords */ then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.clients.rid-clients).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.clients.id-client.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(system.clients.id-client) + " " + system.clients.name-client.
    end.
  end.
  if itemcount < 0 then AllRecords = false.
end.
if basetype = "CLNADR" then
do:
  define variable id-cln as integer.

  if ContextParam <> "" then AppendParam = ContextParam.
  if AppendParam <> "" then id-cln = INTEGER(AppendParam).

  find first system.clients where system.clients.id-client = id-cln no-lock no-error.
  if available system.clients then
  do:
    for each system.cln-address of system.clients no-lock where AllRecords OR
      system.cln-address.address matches "*" + searchstring + "*"
      by system.cln-address.id-address:
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = "###" + string(system.cln-address.rid-clients) +
                ":" + string(system.cln-address.id-address).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.cln-address.id-address.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.cln-address.address.
    end.
  end.
end.
if basetype = "CLNBANKACC" then
do:
  define variable main-ba as character.
  main-ba = "Основной расчетный счет".

  if ContextParam <> "" then AppendParam = ContextParam.
  if AppendParam <> "" then id-cln = INTEGER(AppendParam).

  find first system.clients where system.clients.id-client = id-cln no-lock no-error.
  if available system.clients then
  do:
    if AllRecords OR main-ba matches "*" + searchstring + "*" then
    do:
      itemcount = itemcount - 1.
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string ( system.clients.id-client ) + "#" +
         string( system.clients.mfo) + "#" + system.clients.account-code + "#" + system.clients.bank-name.
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  main-ba.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = main-ba.
    end.
    for each system.cln-bankacc no-lock where 
      system.cln-bankacc.rid-clients = system.clients.rid-clients AND
      (AllRecords OR
      system.cln-bankacc.cba-description matches "*" + searchstring + "*")
      by system.cln-bankacc.cba-description:
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string ( system.clients.id-client ) + "#" + 
         string ( system.cln-bankacc.mfo ) + "#" + system.cln-bankacc.account-code + "#" + system.cln-bankacc.bank-name.
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.cln-bankacc.cba-description.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.cln-bankacc.cba-description.
    end.
  end.
end.

if basetype = "CONTR-SUBJ" then
do:
  for each system.contract-subj no-lock where AllRecords OR
    string(system.contract-subj.id-contr-subj) + " " + system.contract-subj.subject matches "*" + searchstring + "*"
    by system.contract-subj.id-contr-subj:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.contract-subj.rid-contr-subj).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.contract-subj.id-contr-subj.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.contract-subj.id-contr-subj) + " " + system.contract-subj.subject.
  end.
end.
if basetype = "CONTR-TYPE" then
do:
  for each system.contract-type no-lock where AllRecords OR
    system.contract-type.name-contrtype matches "*" + searchstring + "*"
    by system.contract-type.id-contrtype:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.contract-type.rid-contrtype).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.contract-type.id-contrtype.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.contract-type.name-contrtype.
  end.
end.
if basetype = "CONTRACT" OR basetype = "DOG-CLN" then
do:
  define variable rid-cln as integer.
  define variable cf-value as character.

  if ContextParam <> "" then AppendParam = ContextParam.
  if AppendParam <> "" then rid-cln = INTEGER(AppendParam).
  
  if rid-cln = 0 then
  do:
    for each system.clients no-lock where AllRecords OR
      string(system.clients.id-client) + " " + system.clients.name-client matches "*" + searchstring + "*"
      by system.clients.id-client:

      for each anobject WHERE anobject.rid-upobject = system.clients.rid-anobject NO-LOCK,
          EACH contract NO-LOCK WHERE contract.rid-anobject = anobject.rid-anobject:

        itemcount = itemcount - 1.
        if itemcount < 0 /* and not AllRecords */ then leave.
  
        con-fvalue = string(system.clients.id-client) + " " + system.clients.name-client + " (Дог. № ".
        if contract.reg-contract <> ? then
          con-fvalue = con-fvalue + STRING( contract.reg-contract  ).
        else
          con-fvalue = con-fvalue + "?".
        con-fvalue = con-fvalue + " от ".
        if contract.date-contract <> ? then
          con-fvalue = con-fvalue + STRING( contract.date-contract ).
        else
          con-fvalue = con-fvalue + "?".
        con-fvalue = con-fvalue + ")".
        hBuffer:BUFFER-CREATE().
        hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.contract.rid-contract).
        hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  string(system.clients.id-client, "9999999999") + " " + system.contract.reg-contract.
        hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = con-fvalue.
      end.
    end.
  end.

  for each contract where contract.rid-clients = rid-cln no-lock    
    by system.contract.reg-contract:
    
    find first system.contract-subj of contract no-lock no-error.
    if available system.contract-subj then
      cf-value = string(system.contract.reg-contract) + " " + system.contract-subj.subject.
    else
      cf-value = string(system.contract.reg-contract).

    if not (AllRecords OR cf-value matches "*" + searchstring + "*") then NEXT.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.contract.rid-contract).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.contract.reg-contract.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = cf-value.
  end.
end.

if basetype = "COSTGROUP" then
do:
  for each system.cost-groups no-lock where AllRecords OR
    string(system.cost-groups.id-kind) + " " + system.cost-groups.name-kind matches "*" + searchstring + "*"
    by system.cost-groups.id-kind:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.cost-groups.rid-kind).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.cost-groups.id-kind.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.cost-groups.id-kind) + " " + system.cost-groups.name-kind.
  end.
end.
if basetype = "COSTITEM" then
do:
  for each system.cost-item no-lock where AllRecords OR
    string(system.cost-item.id-cost-item) + " " + system.cost-item.name-cost-item matches "*" + searchstring + "*"
    by system.cost-item.id-cost-item:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.cost-item.rid-cost-item).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.cost-item.id-cost-item.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.cost-item.id-cost-item) + " " + system.cost-item.name-cost-item.
  end.
end.
if basetype = "COSTPAR" then
do:
  for each system.cost-params no-lock where AllRecords OR
    string(system.cost-params.id-param) + " " + system.cost-params.name-param matches "*" + searchstring + "*"
    by system.cost-params.id-param:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.cost-params.rid-param).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.cost-params.id-param.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.cost-params.id-param) + " " + system.cost-params.name-param.
  end.
end.
if basetype = "COSTSCH" then
do:
  for each system.filial-cost-scheme no-lock where AllRecords OR
    string(system.filial-cost-scheme.id-scheme) + " " + system.filial-cost-scheme.name-scheme matches "*" + searchstring + "*"
    by system.filial-cost-scheme.id-scheme:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.filial-cost-scheme.rid-fcs).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.filial-cost-scheme.id-scheme.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.filial-cost-scheme.id-scheme) + " " + system.filial-cost-scheme.name-scheme.
  end.
end.

if basetype = "COUNTRY" then
do:
  for each system.countries no-lock where AllRecords OR
    system.countries.name-country matches "*" + searchstring + "*"
    by system.countries.name-country:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.countries.rid-country).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.countries.name-country.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.countries.name-country.
  end.
end.

if basetype = "CTGDIVIS" then
do:
  for each system.ctg-division no-lock where AllRecords OR
    string(system.ctg-division.code-division) + " " + system.ctg-division.name-division matches "*" + searchstring + "*"
    by system.ctg-division.code-division:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.ctg-division.rid-division).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.ctg-division.code-division.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.ctg-division.code-division) + " " + system.ctg-division.name-division.
  end.
end.

if basetype = "CURRENCY" then
do:
  for each system.currency no-lock where AllRecords OR
    string(system.currency.id-currency) + " " + system.currency.name-currency matches "*" + searchstring + "*"
    by system.currency.id-currency:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.currency.rid-currency).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.currency.id-currency.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.currency.id-currency) + " " + system.currency.name-currency.
  end.
end.

if basetype = "DIRCONST" or basetype = "DIRCNST2" or basetype = "DIRCONSP" then
do:
  define variable dc-date as date initial ?.
  define variable rid-dc as integer.
  define variable dc-ent as integer.
  define variable dc-value as character.

  if basetype begins "DIRCONS" then dc-date = DATE("31/12/9999").
  else dc-date = TODAY.

  if ContextParam <> "" and basetype = "DIRCNST2" then
  do:
    dc-date = DATE (ContextParam).
  end.
  rid-dc = INTEGER(AppendParam).
  if ContextParam <> "" and basetype <> "DIRCNST2" then
  do:
    find system.dir-topics where 
         system.dir-topics.id-topic = INTEGER ( ContextParam ) and
         system.dir-topics.is-enter = false NO-LOCK NO-ERROR.
    IF AVAILABLE system.dir-topics then 
      rid-dc = system.dir-topics.rid-dirtopic.
  end.

  Find First system.dir-topics WHERE system.dir-topics.rid-dirtopic = rid-dc NO-LOCK NO-ERROR.
  if available system.dir-topics then 
  do:
    dc-ent = if (system.dir-topics.by-ent) then (rid-ent) else (?).

    for each system.contents-topics OF system.dir-topics NO-LOCK WHERE
        system.contents-topics.rid-ent = dc-ent AND
        system.contents-topics.contents-date <= dc-date AND
        (AllRecords OR STRING ( system.contents-topics.id-contents ) + " " + 
          system.contents-topics.contents matches "*" + searchstring + "*")
      by system.contents-topics.id-contents:
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.

      dc-value = STRING ( system.contents-topics.id-contents ) + " " + 
          system.contents-topics.contents.
      dc-value = REPLACE (dc-value, chr(13), " ").
      dc-value = REPLACE (dc-value, chr(10), "").
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = system.contents-topics.rid-contents.
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.contents-topics.id-contents.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = dc-value.
    end.
  end.
end.

if basetype = "DIRTOPIC" or basetype = "DIRTOPI2" then
do:
  define variable dt-date as date initial ?.
  define variable rid-dt as integer.
  define variable dt-ent as integer.
  define variable dt-value as character.
  if ContextParam <> "" then
  do:
    dt-date = DATE (ContextParam).
  end.
  if dt-date = ? then
  do:
    if basetype = "DIRTOPIC" then dt-date = DATE("31/12/9999").
    else dt-date = TODAY.
  end.
  rid-dt = INTEGER(AppendParam).

  Find First system.dir-topics WHERE system.dir-topics.rid-dirtopic = rid-dt NO-LOCK NO-ERROR.
  if available system.dir-topics then 
  do:
    dt-ent = if (system.dir-topics.by-ent) then (rid-ent) else (?).

    for each system.contents-topics OF system.dir-topics NO-LOCK WHERE
        system.contents-topics.rid-ent = dt-ent AND
        system.contents-topics.contents-date <= dt-date AND
        (AllRecords OR system.contents-topics.contents matches "*" + searchstring + "*")
      by system.contents-topics.contents:
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.

      dt-value = system.contents-topics.contents.
      dt-value = REPLACE (dt-value, chr(13), " ").
      dt-value = REPLACE (dt-value, chr(10), "").
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = dt-value.
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  dt-value.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = dt-value.
    end.
  end.
end.

if basetype = "DIVISION" or basetype = "DIVISION2" then
do:
  define variable div-ent as integer.
  define variable div-ctg as integer.
  
  div-ent = ?.
  div-ctg = ?.
  if basetype = "DIVISION" then
    div-ent = rid-ent.
  if basetype = "DIVISION2" then
  do:
    find first cathg where cathg.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
    if available cathg then
      div-ctg = cathg.rid-division.
  end.
  for each system.division no-lock where (system.division.rid-ent = div-ent OR div-ent = ?) AND
    (AllRecords OR
    system.division.code-division + " " + system.division.name-division matches "*" + searchstring + "*")
    by system.division.code-division:

    if div-ctg <> ? then
    do:
      run CheckDiv ( div-ctg, system.division.rid-division).
      if return-value = "NO" then NEXT.
    end.
    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.division.rid-division).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.division.code-division.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      system.division.code-division + " " + system.division.name-division.
  end.
end.

if basetype = "DOCUMENT" or basetype = "DOC_W_SEL" then
do:
  define variable id-typedoc as integer.
  define variable rid-typedoc as integer.
  define variable id-doc as integer.
  define variable year-doc as integer.
  define variable i as integer.
  define variable fld-list as character.
  define variable value-list as character.
  define variable rid-document as integer.

  rid-typedoc = ?.
  fld-list = "".
  value-list = "".
  if ContextParam <> "" and basetype = "DOCUMENT" then
  do:
    run src/kernel/tidtorid.p ( INTEGER (ContextParam), output rid-typedoc ).
    ContextParam = "".
  end.
  if ContextParam <> "" and basetype = "DOC_W_SEL" then
  do:
    if NUM-ENTRIES (ContextParam, "|") > 1 then
    do:
      AppendParam = ENTRY(1,ContextParam,"|").
      ContextParam = ENTRY(2,ContextParam,"|").
      id-typedoc = INTEGER(ENTRY(1,AppendParam,",")).
      run src/kernel/tidtorid.p ( id-typedoc, output rid-typedoc ).
    end.
    else
      rid-typedoc = INTEGER(ENTRY(1,AppendParam,",")).
  end.
  if rid-typedoc = ? then
    rid-typedoc = INTEGER(AppendParam).

  find first system.document where system.document.rid-typedoc = rid-typedoc no-lock no-error.
  if not available system.document then RETURN.

  SearchString = trim (SearchString).
  if NUM-ENTRIES (searchstring, "/") > 1 then
  do:
    id-doc   = integer (entry(1,searchstring, "/")) NO-ERROR.
    year-doc = integer (entry(2,searchstring, "/")) NO-ERROR.
  end.
  else do:
    id-doc = integer (searchstring) NO-ERROR.
    year-doc = ?.
  end.
  if year-doc <> ? and year-doc < 100 then
    year-doc = YEAR (DATE (1, 1, 2000 + year-doc)).

  if AllRecords then
  do:
    id-doc = ?.
    year-doc = ?.
  end.
  if trim(searchstring) = "" then
    id-doc = ?.

  if ContextParam = "" or ContextParam = "?" OR id-doc <> ? OR
     (NUM-ENTRIES ( ContextParam ) <> NUM-ENTRIES ( AppendParam ) - 1) then
  do:
    for each system.document NO-LOCK where 
        (system.document.id-document = id-doc or id-doc = ?) and
        system.document.rid-ent = rid-ent and
        system.document.rid-typedoc = rid-typedoc and
        (system.document.year = year-doc or year-doc = ?)
       by system.document.date-doc desc
       by system.document.id-document desc:
  
      itemcount = itemcount - 1.
      if itemcount < 0 /* and not AllRecords */ then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.document.rid-document).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.document.id-document.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = string(system.document.id-document) + "/" +
        substring ( string ( year ( system.document.date-doc ) ), 3, 2 ).
  
      hBuffer:BUFFER-FIELD("IdDoc"):BUFFER-VALUE =  system.document.id-document.
      hBuffer:BUFFER-FIELD("DateDoc"):BUFFER-VALUE =  system.document.date-doc.
      hBuffer:BUFFER-FIELD("DateDoc1"):BUFFER-VALUE =  STRING(system.document.date-doc, "99/99/9999").
      hBuffer:BUFFER-FIELD("Descr"):BUFFER-VALUE =  system.document.descr-opr.
      hBuffer:BUFFER-FIELD("SumDoc"):BUFFER-VALUE =  system.document.sum-doc.
    end.
  end.
  else do:
    fld-list = "".
    value-list = "".
    i = INDEX ( AppendParam, "," ).
    if i > 0 then
      AppendParam = SUBSTRING ( AppendParam, i + 1 ).    

    do i = 1 to NUM-ENTRIES ( ContextParam ) :
      if ENTRY ( i, ContextParam ) = "" then NEXT.
      if fld-list = "" then fld-list = ENTRY ( i, AppendParam ).
                       else fld-list = fld-list + "," + ENTRY ( i, AppendParam ).
      if value-list = "" then value-list = ENTRY ( i, ContextParam ).
                         else value-list = value-list + "," + ENTRY ( i, ContextParam ).
    end. 
    Find First system.typedoc WHERE system.typedoc.rid-typedoc = rid-typedoc NO-LOCK NO-ERROR.
    if available system.typedoc then
    do:
      id-typedoc = system.typedoc.id-typedoc.
      RUN src/kernel/getfrddc.p ( id-typedoc, date ("01/01/0001"), date("31/12/9999"), 
        fld-list, value-list, "", OUTPUT rid-document ).
    end.
    FOR EACH querydoc,
        EACH system.document WHERE system.document.rid-document = querydoc.riddoc
       by system.document.date-doc desc
       by system.document.id-document desc:
  
      itemcount = itemcount - 1.
      if itemcount < 0 /* and not AllRecords */ then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.document.rid-document).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.document.id-document.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = string(system.document.id-document) + "/" +
        substring ( string ( year ( system.document.date-doc ) ), 3, 2 ).
  
      hBuffer:BUFFER-FIELD("IdDoc"):BUFFER-VALUE =  system.document.id-document.
      hBuffer:BUFFER-FIELD("DateDoc"):BUFFER-VALUE =  system.document.date-doc.
      hBuffer:BUFFER-FIELD("DateDoc1"):BUFFER-VALUE =  STRING(system.document.date-doc, "99/99/9999").
      hBuffer:BUFFER-FIELD("Descr"):BUFFER-VALUE =  system.document.descr-opr.
      hBuffer:BUFFER-FIELD("SumDoc"):BUFFER-VALUE =  system.document.sum-doc.
    end.
  end.
  if itemcount < 0 then AllRecords = false.
end.

if basetype = "DRIVER" then
do:
  for each system.driver no-lock where AllRecords OR
    string(system.driver.id-driver) + " " + system.driver.name-driver matches "*" + searchstring + "*"
    by system.driver.id-driver:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.driver.rid-driver).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.driver.id-driver.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.driver.id-driver) + " " + system.driver.name-driver.
  end.
end.
if basetype = "DRIVER2" then
do:
  for each system.driver no-lock where AllRecords OR
    system.driver.name-driver matches "*" + searchstring + "*"
    by system.driver.name-driver:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = system.driver.name-driver.
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.driver.name-driver.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.driver.name-driver.
  end.
end.
if basetype = "DRIVER-CL" then
do:
  for each system.driver-class no-lock where AllRecords OR
    string(system.driver-class.id-driver-class) + " " + system.driver-class.name-driver-class matches "*" + searchstring + "*"
    by system.driver-class.id-driver-class:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.driver-class.rid-driver-class).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.driver-class.id-driver-class.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.driver-class.id-driver-class) + " " + system.driver-class.name-driver-class.
  end.
end.
if basetype = "DRIVERSALM" then
do:
  for each system.driver-salmet no-lock where AllRecords OR
    string(system.driver-salmet.id-driver-salmet) + " " + system.driver-salmet.name-driver-salmet matches "*" + searchstring + "*"
    by system.driver-salmet.id-driver-salmet:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.driver-salmet.rid-driver-salmet).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.driver-salmet.id-driver-salmet.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.driver-salmet.id-driver-salmet) + " " + system.driver-salmet.name-driver-salmet.
  end.
end.
if basetype = "DRVWORK" then
do:
  for each system.driver-work no-lock where AllRecords OR
    string(system.driver-work.id-driver-work) + " " + system.driver-work.name-driver-work matches "*" + searchstring + "*"
    by system.driver-work.id-driver-work:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.driver-work.rid-driver-work).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.driver-work.id-driver-work.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.driver-work.id-driver-work) + " " + system.driver-work.name-driver-work.
  end.
end.

if basetype = "EMPCAT" then
do:
  for each system.emp-cat no-lock where AllRecords OR
    string(system.emp-cat.id-emp-cat) + " " + system.emp-cat.name-emp-cat matches "*" + searchstring + "*"
    by system.emp-cat.id-emp-cat:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.emp-cat.rid-emp-cat).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.emp-cat.id-emp-cat.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.emp-cat.id-emp-cat) + " " + system.emp-cat.name-emp-cat.
  end.
end.
if basetype = "EMPCTG" then
do:
  for each system.emp-ctg no-lock where AllRecords OR
    string(system.emp-ctg.id-emp-ctg) + " " + system.emp-ctg.name-emp-ctg matches "*" + searchstring + "*"
    by system.emp-ctg.id-emp-ctg:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.emp-ctg.rid-emp-ctg).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.emp-ctg.id-emp-ctg.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.emp-ctg.id-emp-ctg) + " " + system.emp-ctg.name-emp-ctg.
  end.
end.
if basetype = "EMPDIV" then
do:
  define variable rid-div as integer.
  define variable rid-per as integer.
  define variable empdiv as character.
  define variable div-bdate as date.
  define variable div-edate as date.

  rid-div = ?.
  if ContextParam <> "" and ContextParam <> ? then
  do:
    if num-entries(ContextParam) > 1 then
    do:
      rid-per = INTEGER(ENTRY(2,ContextParam)).
      ContextParam = entry (1, ContextParam).
    end.
    else 
      rid-per = 0.
    FOR FIRST division WHERE division.code-division = ContextParam and division.rid-ent = rid-ent NO-LOCK:
      rid-div = division.rid-division.
    END.
  end.

  if rid-per <> 0 then
  do:
    run src/wage/g_ridper.p ( rid-per, output div-bdate, output div-edate ).
  end.
  for each system.employeers NO-LOCK WHERE
    string(system.employeers.id-emp) + " " + system.employeers.name-emp matches "*" + searchstring + "*",
      EACH system.emp-div of system.employeers NO-LOCK WHERE
           system.emp-div.rid-ent = rid-ent 
/*         ( rid-div = ? or system.emp-div.rid-division  = rid-div ) */ , 
      EACH system.vposition of system.emp-div NO-LOCK
        BY system.employeers.id-emp
        BY system.emp-div.bdate DESC:

    if rid-div <> ? then
    do:
      run CheckDiv ( rid-div, system.emp-div.rid-division).
      if return-value = "NO" then NEXT.
    end.
    if rid-per <> 0 then
    do:
      if not ((system.emp-div.edate = ? or system.emp-div.edate >= div-bdate) and system.emp-div.bdate <= div-edate) then NEXT.
    end.
    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    run src/custom/cut_fio.p ( system.employeers.name-emp ).
    empdiv = string(system.employeers.id-emp) + " " + STRING ( system.emp-div.is-main, "X/ " ) + " " + return-value.
    empdiv = empdiv + " " + system.vposition.name-vposition.
    if system.emp-div.bdate <> ? then
      empdiv = empdiv + " с " + STRING(system.emp-div.bdate, "99/99/9999").
    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.emp-div.rid-empdiv).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.employeers.id-emp.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = empdiv.
  end.
end.
if basetype = "EMPDIV2" then
do:
  define variable id-emp as integer.
  define variable is-main as logical.

  id-emp = INTEGER(ENTRY(1, ContextParam)) NO-ERROR.
  is-main = ?.
  IF NUM-ENTRIES ( ContextParam ) > 1
  then do: 
   if ENTRY(2, ContextParam) = "NO" then is-main = no.
   if ENTRY(2, ContextParam) = "YES" then is-main = yes.
  end.
  
  for each system.employeers NO-LOCK WHERE system.employeers.id-emp = id-emp,
      EACH system.emp-div of system.employeers NO-LOCK WHERE
           system.emp-div.rid-ent = rid-ent and
         ( is-main = ? or system.emp-div.is-main = is-main ), 
      EACH system.vposition of system.emp-div NO-LOCK 
      BY system.emp-div.bdate DESC:

    empdiv = STRING ( system.emp-div.is-main, "X/ " ) + " " + STRING(system.emp-div.bdate, "99/99/9999").
    if system.emp-div.edate = ? then empdiv = empdiv + "-...". 
    else empdiv = empdiv + "-" + STRING (system.emp-div.edate, "99/99/9999").                       
    empdiv = empdiv + " " + system.vposition.name-vposition.

    if not AllRecords then
    do:
      if not (empdiv matches "*" + searchstring + "*") then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.


    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.emp-div.rid-empdiv).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.employeers.id-emp.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = empdiv.
  end.
end.
if basetype = "EMPLOYEER" or basetype = "EMPLOYEER2" or basetype = "EMPLOYEER4" then
do:
  define variable rid-empdiv as integer.
  rid-div = ?.
  div-bdate = ?.
  if ContextParam <> "" then
  do:
    rid-div = INTEGER ( ENTRY (1, ContextParam) ) NO-ERROR.
    if NUM-ENTRIES (ContextParam) > 1 then
      div-bdate = DATE ( ENTRY (2, ContextParam) ) NO-ERROR.
  end.
  Find system.division WHERE system.division.rid-division = rid-div NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.division then rid-div = ?.

  for each system.employeers NO-LOCK WHERE
    string(system.employeers.id-emp) + " " + system.employeers.name-emp matches "*" + searchstring + "*"
    BY system.employeers.id-emp:

    if basetype = "EMPLOYEER2" and rid-div <> ? then
    do:
      run src/wage/g_empdv2.p ( system.employeers.id-emp, "", TODAY, OUTPUT rid-empdiv ).
      Find First system.emp-div WHERE system.emp-div.rid-empdiv = rid-empdiv NO-LOCK NO-ERROR.
      if not available system.emp-div then NEXT.

      if rid-div <> system.emp-div.rid-division then NEXT. 
    end.
    if rid-div <> ? and (basetype = "EMPLOYEER" or basetype = "EMPLOYEER4") then
    do:
      find first system.emp-div of system.employeers WHERE
           system.emp-div.rid-ent = rid-ent and
          (system.emp-div.bdate <= div-bdate AND
          (system.emp-div.edate >= div-bdate OR system.emp-div.edate = ?) OR div-bdate = ?)
          NO-LOCK NO-ERROR.
      if not available system.emp-div then NEXT.

      run CheckDiv ( rid-div, system.emp-div.rid-division).
      if return-value = "NO" then NEXT.
    end.
    if basetype = "EMPLOYEER" and system.employeers.flag-emp = true then NEXT.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.employeers.rid-emp).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.employeers.id-emp.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = string(system.employeers.id-emp) + " " + system.employeers.name-emp.
  end.
end.
if basetype = "EMPRANK" then
do:
  for each system.emp-rank no-lock where AllRecords OR
    system.emp-rank.name-emp-rank matches "*" + searchstring + "*"
    by system.emp-rank.id-emp-rank:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.emp-rank.rid-emp-rank).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.emp-rank.id-emp-rank.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      system.emp-rank.name-emp-rank.
  end.
end.

if basetype = "ENT" then
do:
  for each system.ent no-lock where AllRecords OR
    system.ent.name-ent matches "*" + searchstring + "*"
    by system.ent.id-ent:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.ent.rid-ent).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.ent.id-ent.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.ent.name-ent.
  end.
end.

define stream s1.
if basetype = "ENTLIST" then
do:
  define variable dbtable-file as character.
  define variable db-id as character.
  define variable db-name as character.
  define variable db-host as character.
  define variable db-port as character.
  define variable db-list as character.

  dbtable-file = "appserv/dbtable.txt".
  input stream s1 from value(dbtable-file).
  repeat:
    import stream s1 db-id db-name db-host db-port.
    if db-id begins "#" then NEXT.
    
    db-list = db-id + " (" + REPLACE (db-name, ",", " ") + ")".

    if not AllRecords then
    do:
      if not (db-list matches "*" + searchstring + "*") then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = db-id.
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  db-id.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = db-list.
  end.
  input stream s1 close.
end.

if basetype = "EXTACC" then
do:
  Find First system.ctg-options WHERE system.ctg-options.rid-cathg = currid-cathg
    NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.ctg-options then RETURN.

  for each system.ext-acc no-lock where AllRecords OR
    system.ext-acc.count + " " + system.ext-acc.acc-name matches "*" + searchstring + "*"
    by system.ext-acc.count:

    if not system.ctg-options.is-allextacc then
    do:
      find first system.ctg-extacc of system.ext-acc where
        system.ctg-extacc.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
      if not available system.ctg-extacc then NEXT.
    end.
    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = system.ext-acc.count.
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.ext-acc.count.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      system.ext-acc.count + " " + system.ext-acc.acc-name.
  end.
end.

define stream dirlist.
if basetype = "FILE" then
do:
  define variable fpath as character.
  define variable fext as character.
  define variable f-name as character.
  define variable full-name as character.

  case NUM-ENTRIES( ContextParam, ";"):
    when 1 then
      assign fpath   = ENTRY( 1, ContextParam,";")
             fext    = "*.*".
    when 2 then
      assign fpath   = ENTRY( 1, ContextParam, ";")
             fext    = ENTRY( 2, ContextParam, ";").
    otherwise
      assign fpath   = ""
             fext    = "*.*".
  end.
  if fpath = "" then fpath = "./".

  INPUT STREAM dirlist FROM OS-DIR (fpath).
  repeat:
    IMPORT STREAM dirlist f-name full-name .
    FILE-INFO:FILENAME = dir + f-name.
    if f-name = ".." or f-name = "." then NEXT.
    if not f-name matches fext then NEXT.

    if not AllRecords and not (dir + f-name) matches "*" + searchstring + "*" then NEXT.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = dir + f-name.
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  dir + f-name.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = dir + f-name.
  end.
  INPUT STREAM dirlist CLOSE.
end.

if basetype = "FILIAL" then
do:
  for each system.filials no-lock where (AllRecords OR
    string(system.filials.id-filials) + " " + system.filials.name-filial matches "*" + searchstring + "*")
    and system.filials.hidden = false
    by system.filials.id-filials:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.filials.rid-filials).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.filials.id-filials.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.filials.id-filials) + " " + system.filials.name-filial.
  end.
end.
if basetype = "FILPARAM" then
do:
  for each system.filial-params no-lock where AllRecords OR
    string(system.filial-params.id-param) + " " + system.filial-params.name-param matches "*" + searchstring + "*"
    by system.filial-params.id-param:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.filial-params.rid-param).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.filial-params.id-param.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.filial-params.id-param) + " " + system.filial-params.name-param.
  end.
end.

if basetype = "FUEL-CH" then
do:
  for each system.fuel-changes no-lock where AllRecords OR
    string(system.fuel-changes.id-fuel-changes) + " " + system.fuel-changes.name-fuel-changes matches "*" + searchstring + "*"
    by system.fuel-changes.id-fuel-changes:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.fuel-changes.rid-fuel-changes).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.fuel-changes.id-fuel-changes.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.fuel-changes.id-fuel-changes) + " " + system.fuel-changes.name-fuel-changes.
  end.
end.

if basetype = "CITY" then
do:
  for each system.city no-lock where AllRecords OR
    system.city.name-city matches "*" + searchstring + "*"
    by system.city.name-city:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.city.rid-city).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.city.name-city.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.city.name-city.
  end.
end.
if basetype = "REGION" then
do:
  define variable rid-city as integer.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  rid-city = INTEGER (AppendParam) NO-ERROR.
  
  for each system.region no-lock where
    (system.region.rid-city = rid-city or rid-city = 0) and 
    (AllRecords OR
    /* string(system.region.id-region) + " " + */ system.region.name-region matches "*" + searchstring + "*")
    by system.region.name-region:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.region.rid-region).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.region.name-region.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
    /*  string(system.region.id-region) + " " + */ system.region.name-region.
  end.
end.
if basetype = "STREET" then
do:
  if ContextParam <> "" then
    AppendParam = ContextParam.
  rid-city = INTEGER (AppendParam) NO-ERROR.
  
  for each system.street no-lock where
    (system.street.rid-city = rid-city or rid-city = 0 ) and
    (AllRecords OR
    /* string(system.street.id-street) + " " + */ system.street.name-street matches "*" + searchstring + "*")
    by system.street.name-street:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.street.rid-street).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.street.name-street.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
    /*  string(system.street.id-street) + " " + */ system.street.name-street.
  end.
end.
if basetype = "HOUSE" then
do:
  define variable rid-street as integer.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  rid-street = INTEGER (AppendParam) NO-ERROR.
  for each system.house no-lock where (AllRecords OR
    string(system.house.id-house) matches "*" + searchstring + "*")
    and system.house.rid-street = rid-street
    by system.house.id-house:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.house.rid-house).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.house.id-house.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = string(system.house.id-house).
  end.
end.
if basetype = "GEO-TERRIT" then
do:
  define variable geo-name as character.
  define variable geo-code as character.

  searchstring = replace (searchstring, " ", "*").
  for each system.geo-territ no-lock:
    run CalcGeo (system.geo-territ.rid-territ, OUTPUT geo-code, OUTPUT geo-name ).

    if not AllRecords then
    do:
      if not (geo-name matches "*" + searchstring + "*") then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.geo-territ.rid-territ).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  geo-code.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = geo-name.
  end.
end.

if basetype = "INVENTORY" or basetype = "INV-REST" then
do:
  define variable inv-emp as integer.
  define variable invdate as date.
  define variable invrest as decimal.

  inv-emp = ?.
  invdate = today.
  if ContextParam <> "" then
    AppendParam = ContextParam.
  IF NUM-ENTRIES (AppendParam) > 1 then 
  do:
    inv-emp = INTEGER (ENTRY (1, AppendParam )).
    invdate = DATE (ENTRY (2, AppendParam )).
  end.

  find first employeers where employeers.id-emp = inv-emp NO-LOCK NO-ERROR.

  for each system.inventory no-lock where (AllRecords OR
    string(system.inventory.id-inventory) + " " + system.inventory.inv-name matches "*" + searchstring + "*")
    and system.inventory.rid-ent = rid-ent
    by system.inventory.id-inventory:

    if available employeers then
    do:
      invrest = 0.
      for each wares of system.inventory NO-LOCK,
          each wh-object where
          wh-object.rid-anobject = wares.rid-anobject and
          wh-object.count = employeers.count and
          wh-object.object-param = inventory.id-inventory NO-LOCK:
  
          run src/kernel/gwh_rq.p ( wh-object.count, wh-object.rid-anobject,
            wh-object.object-param, invdate, OUTPUT invrest ).
      end.
      if invrest <= 0 then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.inventory.rid-inventory).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.inventory.id-inventory.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.inventory.id-inventory) + " " + system.inventory.inv-name.
  end.
end.

if basetype = "LANGUAGE" then
do:
  for each system.language no-lock where AllRecords OR
    system.language.IntCode + " " + system.language.name-language matches "*" + searchstring + "*"
    by system.language.nmb-lang:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.language.nmb-lang).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.language.nmb-lang.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.language.IntCode) + " " + system.language.name-language.
  end.
end.

if basetype = "LOADTYPE" then
do:
  for each system.loadtype no-lock where AllRecords OR
    string(system.loadtype.id-loadtype) + " " + system.loadtype.name-loadtype matches "*" + searchstring + "*"
    by system.loadtype.id-loadtype:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.loadtype.rid-loadtype).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.loadtype.id-loadtype.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.loadtype.id-loadtype) + " " + system.loadtype.name-loadtype.
  end.
end.

if basetype = "LS" then
do:
  define variable ls-mfo as character.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  ls-mfo = TRIM(AppendParam).
  if ls-mfo = "000000" or ls-mfo = "" then
  do:
    for each system.ls no-lock where AllRecords OR
      system.ls.name-ls matches "*" + searchstring + "*"
      by system.ls.name-ls:
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.ls.rid-ls).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.ls.name-ls.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.ls.name-ls.
    end.
  end.
  else do:
    FOR EACH bank-pay NO-LOCK WHERE bank-pay.mfo-bank-pay = ls-mfo,
        EACH sheme-calc NO-LOCK WHERE sheme-calc.rid-bank-pay = bank-pay.rid-bank-pay,
        EACH ls NO-LOCK WHERE ls.name-ls = sheme-calc.corrac-sheme-calc AND 
        ls.name-ls matches "*" + searchstring + "*"
      by system.ls.name-ls:

      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.ls.rid-ls).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.ls.name-ls.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.ls.name-ls.
    END.
  end.
end.
if basetype = "LS-TYPEOP" then
do:
  for each system.ls-typeoper no-lock where AllRecords OR
    string(system.ls-typeoper.id-ls-typeoper) + " " + system.ls-typeoper.name-ls-typeoper matches "*" + searchstring + "*"
    by system.ls-typeoper.id-ls-typeoper:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.ls-typeoper.rid-ls-typeoper).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.ls-typeoper.id-ls-typeoper.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.ls-typeoper.id-ls-typeoper) + " " + system.ls-typeoper.name-ls-typeoper.
  end.
end.

if basetype = "MEASUNIT" then
do:
  for each system.measureUnit no-lock where AllRecords OR
    system.measureUnit.Unit matches "*" + searchstring + "*"
    by system.measureUnit.Unit:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.measureUnit.Unit).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.measureUnit.Unit.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.measureUnit.Unit.
  end.
end.
if basetype = "WR-UNITS" or basetype = "WRUNITS" then
do:
  define variable mu-i as integer initial 0.
  if ContextParam <> "" then 
    AppendParam = ContextParam.
  if AppendParam <> "" and AllRecords then
  do:
    find first system.wares where system.wares.alfa-cod = AppendParam NO-LOCK NO-ERROR.
    if available system.wares then
    do:
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.wares.unit).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  mu-i.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.wares.unit.

      for each WaresMeasureUnit where WaresMeasureUnit.rid-wares = rid-wares and
        WaresMeasureUnit.UnitFrom <> system.wares.unit BY WaresMeasureUnit.UnitFrom:
        mu-i = mu-i + 1.

        hBuffer:BUFFER-CREATE().
        hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(WaresMeasureUnit.UnitFrom).
        hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  mu-i.
        hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = WaresMeasureUnit.UnitFrom.
      end.
      RETURN.
    end.
  end.

  for each system.measureUnit no-lock where AllRecords OR
    system.measureUnit.Unit matches "*" + searchstring + "*"
    by system.measureUnit.Unit:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    mu-i = mu-i + 1.
    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.measureUnit.Unit).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  mu-i.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.measureUnit.Unit.
  end.
end.

if basetype = "MEMORDER" then
do:
  for each system.MemOrder no-lock where AllRecords OR
    STRING(system.MemOrder.NumOrder) + " " + system.MemOrder.NameOrder matches "*" + searchstring + "*"
    by system.MemOrder.NumOrder:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.MemOrder.NumOrder).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.MemOrder.NumOrder.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = string(system.MemOrder.NumOrder) + " " + system.MemOrder.NameOrder.
  end.
end.

if basetype = "METHOD" then
do:
  define variable vcalc-item as integer initial ?.
  define variable flag-vcl as logical initial ?.

  ContextParam = trim (ContextParam).
  if ContextParam <> "" then 
  do: 
    if ContextParam = "yes"  then
       flag-vcl = yes.
    else
       flag-vcl = no.
  end.
  if AppendParam <> "" then
    vcalc-item = INTEGER(AppendParam) NO-ERROR.

  for each system.calc-met-item no-lock,
      each system.vcalc-item of system.calc-met-item where 
   (system.vcalc-item.id-vcalc-item = vcalc-item or vcalc-item = ?) and
   (system.vcalc-item.flag-vcalc-item = flag-vcl or flag-vcl = ?) and
   (AllRecords OR
    (STRING ( system.vcalc-item.id-user-item ) + "-" +
     STRING ( system.vcalc-item.name-vcalc-item ) + ", " +
     string(system.calc-met-item.id-calc-met-item) + " " + system.calc-met-item.name-calc-met-item) matches "*" + searchstring + "*")
    by system.vcalc-item.id-user-item by system.calc-met-item.id-calc-met-item:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.calc-met-item.rid-calc-met-item).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.vcalc-item.id-user-item.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      STRING ( system.vcalc-item.id-user-item ) + "-" +
      STRING ( system.vcalc-item.name-vcalc-item ) + ", " +
    string(system.calc-met-item.id-calc-met-item) + " " + system.calc-met-item.name-calc-met-item.
  end.
end.

if basetype = "MRCOUNT" then
do:
  for each system.mr-counts no-lock where AllRecords OR
    string(system.mr-counts.count) + " " + system.mr-counts.count-name matches "*" + searchstring + "*"
    by system.mr-counts.count:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.mr-counts.rid-count).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.mr-counts.count.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.mr-counts.count) + " " + system.mr-counts.count-name.
  end.
end.

if basetype = "OMPARAM" then
do:
  for each system.om-params no-lock where AllRecords OR
    string(system.om-params.id-param) + " " + system.om-params.name-param matches "*" + searchstring + "*"
    by system.om-params.id-param:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.om-params.rid-param).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.om-params.id-param.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.om-params.id-param) + " " + system.om-params.name-param.
  end.
end.
if basetype = "OMTYPEOP" then
do:
  for each system.om-typeoper no-lock where AllRecords OR
    string(system.om-typeoper.id-oper) + " " + system.om-typeoper.name-oper matches "*" + searchstring + "*"
    by system.om-typeoper.id-oper:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.om-typeoper.rid-typeoper).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.om-typeoper.id-oper.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.om-typeoper.id-oper) + " " + system.om-typeoper.name-oper.
  end.
end.

if basetype = "OPER-TYPE" then
do:
  for each system.typeoperdoc no-lock where AllRecords OR
    string(system.typeoperdoc.typeoper) + " " + system.typeoperdoc.oper-name2 matches "*" + searchstring + "*"
    by system.typeoperdoc.typeoper:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.typeoperdoc.typeoper).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.typeoperdoc.typeoper.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.typeoperdoc.typeoper) + " " + system.typeoperdoc.oper-name2.
  end.
end.

if basetype = "PACK" then
do:
  for each system.pack no-lock where AllRecords OR
    string(system.pack.id-pack) + " " + system.pack.name-pack matches "*" + searchstring + "*"
    by system.pack.id-pack:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.pack.rid-pack).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.pack.id-pack.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.pack.id-pack) + " " + system.pack.name-pack.
  end.
end.

if basetype = "PERIOD" or basetype = "PERIOD2" then
do:
  define variable id-vper as integer initial ?.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  if AppendParam <> "" AND AppendParam <> "0" then
    id-vper = INTEGER (AppendParam) NO-ERROR.

  if basetype = "PERIOD" then
  do:
    for each system.period no-lock where (AllRecords OR
      string(system.period.date-begin, "99/99/9999") + "-" + string (system.period.date-end, "99/99/9999") matches "*" + searchstring + "*")
      and (system.period.id-vperiod = id-vper or id-vper = ?)
      by system.period.date-begin desc:
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.period.rid-period).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.period.date-begin.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(system.period.date-begin, "99/99/9999") + "-" + string (system.period.date-end, "99/99/9999").
    end.
  end.
  else do:
    for each system.period no-lock where (AllRecords OR
      string(MONTH(system.period.date-end), "99") + "/" + string (YEAR(system.period.date-end), "9999") matches "*" + searchstring + "*")
      and (system.period.id-vperiod = id-vper or id-vper = ?)
      by system.period.date-begin desc:
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.period.rid-period).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.period.date-begin.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(MONTH(system.period.date-end), "99") + "/" + string (YEAR(system.period.date-end), "9999").
    end.
  end.
end.

if basetype = "PLANMODEL" then
do:
  for each system.PlanModel no-lock where AllRecords OR
    string(system.PlanModel.id-model) + " " + system.PlanModel.name-model matches "*" + searchstring + "*"
    by system.PlanModel.id-model:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.PlanModel.rid-model).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.PlanModel.id-model.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.PlanModel.id-model) + " " + system.PlanModel.name-model.
  end.
end.

if basetype = "POINT" or basetype = "TPOINT" or basetype = "T-CLNPOINT" then
do:
  define variable padr as character.
  define variable pcln as integer initial ?.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  if AppendParam <> "" then
  do:
    find first system.clients where
               system.clients.rid-clients = integer(AppendParam)
    no-lock no-error.
    if not available system.clients
    then pcln = ?.
    else pcln = system.clients.rid-clients.
  end.

  searchstring = REPLACE(searchstring, " ", "*").

  for each system.point no-lock where 
    (system.point.rid-clients = pcln or pcln = ?) and
    (AllRecords OR
    string(system.point.id-point) + " " + system.point.name-point + "," +
    system.point.street + " " + system.point.house + " " + system.point.city matches "*" + searchstring + "*")
    by system.point.id-point:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    padr = string(system.point.id-point) + " " + system.point.name-point + "," +
    system.point.street + " " + system.point.house.
    if system.point.city <> "" then
      padr = padr + ", " + system.point.city.
    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.point.rid-point).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.point.id-point.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = padr.
  end.
end.

if basetype = "PRICETYPE" then
do:
  define variable avail-pt as character.
  define variable is-avail-pt as logical.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  avail-pt = AppendParam.
  if avail-pt = "*" then avail-pt = "".

  for each system.price-type no-lock where 
    (lookup(string(system.price-type.id-pt), avail-pt) <> 0 or avail-pt = "") and
    (AllRecords OR
    string(system.price-type.id-pt) + " " + system.price-type.name-pt matches "*" + searchstring + "*")
    by system.price-type.id-pt:

    run src/kernel/pt_avail.p ( system.price-type.id-pt, output is-avail-pt ).  
    if not is-avail-pt then next.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.price-type.rid-pt).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.price-type.id-pt.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.price-type.id-pt) + " " + system.price-type.name-pt.
  end.
end.

if basetype = "PROCPROD" then
do:
  for each system.process-production no-lock where AllRecords OR
    string(system.process-production.id-pp) + " " + system.process-production.name-pp matches "*" + searchstring + "*"
    by system.process-production.id-pp:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.process-production.rid-pp).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.process-production.id-pp.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.process-production.id-pp) + " " + system.process-production.name-pp.
  end.
end.

if basetype = "PRODADD" then
do:
  for each system.prod-addition no-lock where AllRecords OR
    string(system.prod-addition.id-addition) + " " + system.prod-addition.name-addition matches "*" + searchstring + "*"
    by system.prod-addition.id-addition:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.prod-addition.rid-prod-addition).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.prod-addition.id-addition.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.prod-addition.id-addition) + " " + system.prod-addition.name-addition.
  end.
end.
if basetype = "PRODCLASS" then
do:
  for each system.prod-class no-lock where AllRecords OR
    string(system.prod-class.id-class) + " " + system.prod-class.name-class matches "*" + searchstring + "*"
    by system.prod-class.id-class:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.prod-class.rid-class).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.prod-class.id-class.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.prod-class.id-class) + " " + system.prod-class.name-class.
  end.
end.
if basetype = "PRODDIV" then
do:
  for each system.prod-division no-lock where AllRecords OR
    string(system.prod-division.id-prod-division) + " " + system.prod-division.name-prod-division matches "*" + searchstring + "*"
    by system.prod-division.id-prod-division:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.prod-division.rid-prod-division).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.prod-division.id-prod-division.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.prod-division.id-prod-division) + " " + system.prod-division.name-prod-division.
  end.
end.
if basetype = "PRODGENER" then
do:
  for each system.prod-gener no-lock where AllRecords OR
    string(system.prod-gener.id-prod-gener) + " " + system.prod-gener.generic-name matches "*" + searchstring + "*"
    by system.prod-gener.id-prod-gener:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.prod-gener.rid-prod-gener).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.prod-gener.id-prod-gener.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.prod-gener.id-prod-gener) + " " + system.prod-gener.generic-name.
  end.
end.
if basetype = "PRODKIND" then
do:
  for each system.prod-kind no-lock where AllRecords OR
    string(system.prod-kind.id-prod-kind) + " " + system.prod-kind.name-prod-kind matches "*" + searchstring + "*"
    by system.prod-kind.id-prod-kind:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.prod-kind.rid-prod-kind).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.prod-kind.id-prod-kind.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.prod-kind.id-prod-kind) + " " + system.prod-kind.name-prod-kind.
  end.
end.
if basetype = "PRODUCER" then
do:
  for each system.producer no-lock where AllRecords OR
    string(system.producer.id-producer) + " " + system.producer.name-producer matches "*" + searchstring + "*"
    by system.producer.id-producer:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.producer.rid-producer).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.producer.id-producer.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.producer.id-producer) + " " + system.producer.name-producer.
  end.
end.
if basetype = "PRODUCT" then
do:
  for each system.product no-lock where AllRecords OR
    system.product.product-name matches "*" + searchstring + "*"
    by system.product.product-name:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.product.rid-product).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.product.product-name.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.product.product-name.
  end.
end.

if basetype = "PROJECT" then
do:
  for each system.crm-cq-projects no-lock where AllRecords OR
    string(system.crm-cq-projects.id-cq-projects) + " " + system.crm-cq-projects.name-cq-projects matches "*" + searchstring + "*"
    by system.crm-cq-projects.id-cq-projects:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.crm-cq-projects.rid-cq-projects).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.crm-cq-projects.id-cq-projects.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.crm-cq-projects.id-cq-projects) + " " + system.crm-cq-projects.name-cq-projects.
  end.
end.
if basetype = "PRJ-MODULE" then
do:
  define variable rid-project as integer initial ?.
  define variable name-project as character.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  rid-project = INTEGER(AppendParam) NO-ERROR.
  FIND FIRST crm-cq-projects WHERE crm-cq-projects.rid-cq-projects = rid-project NO-LOCK NO-ERROR.
  IF NOT AVAILABLE crm-cq-projects THEN rid-project = ?.

  for each system.crm-cq-project-module no-lock where 
    (system.crm-cq-project-module.rid-cq-projects = rid-project or rid-project = ?) and
    (AllRecords OR
    string(system.crm-cq-project-module.id-cq-project-module) + " " + system.crm-cq-project-module.name-cq-project-module matches "*" + searchstring + "*")
    by system.crm-cq-project-module.id-cq-project-module:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    name-project = string(system.crm-cq-project-module.id-cq-project-module) + " " + system.crm-cq-project-module.name-cq-project-module.
    if rid-project = ? then
    do:
      FIND FIRST crm-cq-projects WHERE crm-cq-projects.rid-cq-projects = system.crm-cq-project-module.rid-cq-projects NO-LOCK NO-ERROR.
      if available crm-cq-projects then
        name-project = name-project + " (" + system.crm-cq-projects.name-cq-projects + ")".
    end.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.crm-cq-project-module.rid-cq-project-module).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.crm-cq-project-module.id-cq-project-module.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = name-project.
  end.
end.
if basetype = "PRJ-TASK" then
do:
  if ContextParam <> "" then
    AppendParam = ContextParam.
  rid-project = INTEGER(AppendParam) NO-ERROR.
  FIND FIRST crm-cq-projects WHERE crm-cq-projects.rid-cq-projects = rid-project NO-LOCK NO-ERROR.
  IF NOT AVAILABLE crm-cq-projects THEN rid-project = ?.

  for each system.crm-cq-tasks no-lock where 
    (system.crm-cq-tasks.rid-cq-projects = rid-project or rid-project = ?) and
    (AllRecords OR
    string(system.crm-cq-tasks.id-cq-tasks) + " " + system.crm-cq-tasks.contents-cq-tasks matches "*" + searchstring + "*")
    by system.crm-cq-tasks.id-cq-tasks:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.crm-cq-tasks.rid-cq-tasks).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.crm-cq-tasks.id-cq-tasks.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.crm-cq-tasks.id-cq-tasks) + " " + system.crm-cq-tasks.contents-cq-tasks.
  end.
end.
if basetype = "PRJ-TASKTP" then
do:
  for each system.crm-cq-task-type no-lock where AllRecords OR
    string(system.crm-cq-task-type.id-task-type) + " " + system.crm-cq-task-type.name-task-type matches "*" + searchstring + "*"
    by system.crm-cq-task-type.id-task-type:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.crm-cq-task-type.rid-task-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.crm-cq-task-type.id-task-type.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.crm-cq-task-type.id-task-type) + " " + system.crm-cq-task-type.name-task-type.
  end.
end.

if basetype = "REROLL-TP" then
do:
  for each system.rerolling-tp no-lock where AllRecords OR
    string(system.rerolling-tp.id-reroll-tp) + " " + system.rerolling-tp.name-reroll-tp matches "*" + searchstring + "*"
    by system.rerolling-tp.id-reroll-tp:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.rerolling-tp.rid-reroll-tp).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.rerolling-tp.id-reroll-tp.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.rerolling-tp.id-reroll-tp) + " " + system.rerolling-tp.name-reroll-tp.
  end.
end.

if basetype = "RER-STOCK" then
do:
  for each system.reroll-stock no-lock where AllRecords OR
    system.reroll-stock.reroll-stock-numb matches "*" + searchstring + "*"
    by system.reroll-stock.id-reroll-stock:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.reroll-stock.rid-reroll-stock).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.reroll-stock.id-reroll-stock.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.reroll-stock.reroll-stock-numb.
  end.
end.
if basetype = "RER-STT" then
do:
  for each system.rerollst-type no-lock where AllRecords OR
    string(system.rerollst-type.id-rerollst-type) + " " + system.rerollst-type.name-rerollst-type matches "*" + searchstring + "*"
    by system.rerollst-type.id-rerollst-type:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.rerollst-type.rid-rerollst-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.rerollst-type.id-rerollst-type.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.rerollst-type.id-rerollst-type) + " " + system.rerollst-type.name-rerollst-type.
  end.
end.

if basetype = "ROUTE" then
do:
  define variable rid-start as integer.
  define variable rid-stop as integer.

  if ContextParam <> "" then
  do:
    if entry(1, ContextParam,"#") = "" then
    do:
      rid-start = ?.
    end. else
    do:
      find first system.point where
                 system.point.id-point =  integer( entry(1, ContextParam,"#")) 
      no-lock no-error.
      if available system.point then rid-start = system.point.rid-point.
                                else rid-start = ?.
    end.   

    if entry(2, ContextParam,"#") = "" then
    do:
      rid-stop = ?.
    end. else
    do:
      find first system.point where 
                 system.point.id-point =  integer( entry(2, ContextParam,"#")) 
      no-lock no-error.
      if available system.point then rid-stop = system.point.rid-point.
                                else rid-stop = ?.
    end.   
  end.
  else do:
    rid-start = ?.
    rid-stop = ?.
  end.

  for each system.route no-lock where 
    (system.route.rid-start-point = rid-start or rid-start = ?) and
    (system.route.rid-stop-point = rid-stop or rid-stop = ?) and
    (AllRecords OR
    string(system.route.id-route) + " " + system.route.name-route matches "*" + searchstring + "*")
    by system.route.id-route:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.route.rid-route).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.route.id-route.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.route.id-route) + " " + system.route.name-route.
  end.
end.

if basetype = "ROUTING" then
do:
  for each system.routing no-lock where AllRecords OR
    system.routing.code-routing + " " + system.routing.name-routing matches "*" + searchstring + "*"
    by system.routing.code-routing:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.routing.rid-routing).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.routing.code-routing.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      system.routing.code-routing + " " + system.routing.name-routing.
  end.
end.

if basetype = "SCATMETH" then
do:
  for each system.mr-scat-method no-lock where AllRecords OR
    string(system.mr-scat-method.id-method) + " " + system.mr-scat-method.name-method matches "*" + searchstring + "*"
    by system.mr-scat-method.id-method:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.mr-scat-method.rid-scat-method).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.mr-scat-method.id-method.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.mr-scat-method.id-method) + " " + system.mr-scat-method.name-method.
  end.
end.
if basetype = "SCHEME" then
do:
  for each system.mr-scheme no-lock where AllRecords OR
    string(system.mr-scheme.id-scheme) + " " + system.mr-scheme.name + " " +
    STRING(system.mr-scheme.date-from, "99/99/9999") matches "*" + searchstring + "*"
    by system.mr-scheme.id-scheme:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.mr-scheme.rid-scheme).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.mr-scheme.id-scheme.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.mr-scheme.id-scheme) + " " + system.mr-scheme.name + " от " + 
      STRING(system.mr-scheme.date-from, "99/99/9999").
  end.
end.

if basetype = "SCH-ROUTE" then
do:
  for each system.sch-route no-lock where AllRecords OR
    string(system.sch-route.id-sch-route) + " " + system.sch-route.name-sch-route matches "*" + searchstring + "*"
    by system.sch-route.id-sch-route:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.sch-route.rid-sch-route).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.sch-route.id-sch-route.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.sch-route.id-sch-route) + " " + system.sch-route.name-sch-route.
  end.
end.

if basetype = "SEC-DEAL" then
do:
  for each system.sec-deal no-lock where AllRecords OR
    string(system.sec-deal.code) + " " + system.sec-deal.name matches "*" + searchstring + "*"
    by system.sec-deal.code:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.sec-deal.rid-sec-deal).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.sec-deal.code.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.sec-deal.code) + " " + system.sec-deal.name.
  end.
end.
if basetype = "SEC-GROUP" then
do:
  for each system.sec-group no-lock where AllRecords OR
    string(system.sec-group.code) + " " + system.sec-group.name matches "*" + searchstring + "*"
    by system.sec-group.code:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.sec-group.rid-sec-group).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.sec-group.code.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.sec-group.code) + " " + system.sec-group.name.
  end.
end.
if basetype = "SEC-ISSUE" then
do:
  for each system.sec-issue no-lock where AllRecords OR
    string(system.sec-issue.date, "99/99/9999") + " " + system.sec-issue.number matches "*" + searchstring + "*"
    by system.sec-issue.date:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.sec-issue.rid-sec-issue).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.sec-issue.date.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      "от " + string(system.sec-issue.date, "99/99/9999") + " св № " + system.sec-issue.name.
  end.
end.
if basetype = "SEC-OWNER" then
do:
  define variable sec-owtype as integer.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  sec-owtype = INTEGER (AppendParam) NO-ERROR.

  for each system.sec-owner no-lock where AllRecords OR
    system.sec-owner.sec-holder matches "*" + searchstring + "*"
    by system.sec-owner.sec-holder:

    if sec-owtype = 1 then
    do:
       if not (sec-owner.type = 1 or sec-owner.type = 3) then NEXT.
    end.
    if sec-owtype = 2 then
    do:
       if not (sec-owner.type = 2 or sec-owner.type = 3) then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.sec-owner.rid-sec-owner).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.sec-owner.sec-holder.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.sec-owner.sec-holder.
  end.
end.
if basetype = "SEC-REASON" then
do:
  for each system.sec-reason no-lock where AllRecords OR
    string(system.sec-reason.code) + " " + system.sec-reason.name matches "*" + searchstring + "*"
    by system.sec-reason.code:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.sec-reason.rid-sec-reason).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.sec-reason.code.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.sec-reason.code) + " " + system.sec-reason.name.
  end.
end.
if basetype = "SEC-TYPE" then
do:
  for each system.sec-type no-lock where AllRecords OR
    string(system.sec-type.code) + " " + system.sec-type.name matches "*" + searchstring + "*"
    by system.sec-type.code:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.sec-type.rid-sec-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.sec-type.code.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.sec-type.code) + " " + system.sec-type.name.
  end.
end.

if basetype = "SECTOR" then
do:
  for each system.sectors no-lock where AllRecords OR
    string(system.sectors.code-sector) + " " + system.sectors.name-sector matches "*" + searchstring + "*"
    by system.sectors.code-sector:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.sectors.rid-sector).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.sectors.code-sector.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.sectors.code-sector) + " " + system.sectors.name-sector.
  end.
end.


define temp-table serwh
  field count as character
  index i0 count asc.
if basetype = "SERIES" or basetype = "SERIESDT" or basetype = "SERIESWH" then

do:
  define variable ser as character.
  define variable ser-count as character.
  define variable ser-i as integer.
  define variable ser-ware as character.
  define variable ser-rest as decimal.
  define variable ser-date as date.
  define variable ser-ut as character.
  define variable ser-own as logical.

  if ContextParam <> "" then
    AppendParam = ContextParam.

  ser-ut = ?.
  ser-own = ?.
  if basetype= "SERIES" or basetype = "SERIESDT" then
  do:
    if num-entries (AppendParam) >= 3 then
    do:
      ser-count    = entry(1, AppendParam).
      ser-ware     = entry(2, AppendParam).
      ser-date     = date(entry(3, AppendParam)) no-error.
      if ser-count BEGINS "Площадка" then
      do:
        ser-count = SUBSTRING( ser-count, 9 ).
        for each ext-acc where ext-acc.count begins ser-count:
          create serwh.
          serwh.count = ext-acc.count.
        end.
      end.
      else do:
        create serwh.
        serwh.count = ser-count.
      end.

      if num-entries (AppendParam) >= 4 then
        ser-ut = entry(4, AppendParam).
      if ser-ut = "" then ser-ut = ?.
      if num-entries (AppendParam) >= 5 then
      do:
        case entry(5, AppendParam):
          when "yes" then ser-own = yes.
          when "no" then ser-own = no.
        end.
      end.
    end.
  end.
  if basetype = "SERIESWH" then
  do:
    if num-entries (AppendParam, "|") >= 3 then
    do:
      ser-count    = entry(1, AppendParam, "|").
      ser-ware     = entry(2, AppendParam, "|").
      ser-date     = date(entry(3, AppendParam, "|")) no-error.
      do ser-i = 1 to num-entries (ser-count):
        create serwh.
        serwh.count = entry (ser-i, ser-count).
      end.
    end.
  end.

  for each system.wares no-lock where system.wares.alfa-cod = ser-ware,
      each serwh no-lock,
      each wh-object no-lock where
        wh-object.rid-anobject = system.wares.rid-anobject and
        wh-object.count = serwh.count and
        wh-object.rid-ent = rid-ent and
        (AllRecords or wh-object.object-param matches "*" + searchstring + "*")
      break by wh-object.count 
            by wh-object.rid-anobject
            by wh-object.object-param:

    if first-of (wh-object.object-param ) then
    do:
      run src/kernel/gwh_rcqe2.p ( rid-ent, wares.alfa-cod, ?,
          ser-date - 1, ser-own, wh-object.count, ser-ut,
          wh-object.object-param, OUTPUT ser-rest).

      if ser-rest <= 0 then NEXT.

      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.

      ser = wh-object.object-param.
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = ser.
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  ser.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = ser.
    end.
  end.
end.

if basetype = "SIGNATURE" then
do:
  if AllRecords or searchstring <> "" then
  do:
    find first system.cathg where system.cathg.rid-cathg = currid-cathg no-lock no-error.
    if not available system.cathg then RETURN.
    find first system.users where system.users.sys-name = uid no-lock no-error.
    if not available system.users then RETURN.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string ( currid-cathg ) + "/" + uid.
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  currid-cathg.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.users.name + " (" + system.cathg.name + ")".
  end.
end.

if basetype = "STT" then
do:
  for each system.short-time-type no-lock where AllRecords OR
    string(system.short-time-type.id-short-time-type) + " " + system.short-time-type.name-short-time-type matches "*" + searchstring + "*"
    by system.short-time-type.id-short-time-type:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.short-time-type.rid-short-time-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.short-time-type.id-short-time-type.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.short-time-type.id-short-time-type) + " " + system.short-time-type.name-short-time-type
      + " (" + TRIM ( system.short-time-type.stt-scr-value) + ")".
  end.
end.

define buffer wares2 for system.wares.

if basetype = "WARE" or basetype = "WARE2" or basetype = "WARE3" or basetype = "SUB-WARES" or
   basetype = "UPWARE" or basetype = "WARENODE" or basetype = "WAREPLUS" or basetype = "WARELIST" then
do:
  define variable rid-upwares as integer.
  define variable w-type as integer.
  define variable wr-in as logical.
  define variable is-leaf as logical.
  define variable wr-root as character.
  define variable rid-bom as integer.
  define variable wr-date as date.
  define variable wr-count as character.
  define variable wr-i as integer.
  define variable wr-rest as decimal.

  is-leaf = ?.
  rid-upwares = ?.
  w-type = ?.
  if ContextParam <> "" then
    AppendParam = ContextParam.

  if basetype = "SUB-WARES" or basetype = "WARE" or basetype = "WAREPLUS" or
     basetype = "WARE2" or basetype = "WARE3" or basetype = "WARELIST"
  then is-leaf = true.
  if basetype = "UPWARE" then is-leaf = false.

  if basetype = "SUB-WARES" or basetype = "UPWARE" or basetype = "WARENODE" then
    rid-upwares = INTEGER (AppendParam) no-error.
  if basetype = "WAREPLUS" or basetype = "WARE2" then
    w-type = INTEGER (AppendParam) no-error.
  if basetype = "WARE" then
  do:
    if AppendParam begins "wares:" then
    do:
      rid-upwares = INTEGER(ENTRY (2, AppendParam, ":")) NO-ERROR.
      find first wares2 where wares2.rid-upwares = rid-upwares NO-LOCK NO-ERROR.
      if available wares then RETURN.
      else
      do:
        find first wares2 where wares2.rid-wares = rid-upwares NO-LOCK NO-ERROR.
        if available wares then 
        do:
          hBuffer:BUFFER-CREATE().
          hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(wares2.rid-wares).
          hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  wares2.alfa-cod.
          hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = string(wares2.alfa-cod) + " " + wares2.wares-name.
        end.
        RETURN.
      end.
    end.
    if AppendParam begins "bom-item:" then
    do:
      rid-bom = INTEGER(ENTRY( 2, AppendParam, ":" )) NO-ERROR.
      for each bom-wares NO-LOCK where bom-wares.rid-bom-item = rid-bom,
          first wares2 of bom-wares where AllRecords OR
          string(wares2.alfa-cod) + " " + wares2.wares-name matches "*" + searchstring + "*" NO-LOCK:

        itemcount = itemcount - 1.
        if itemcount < 0 and not AllRecords then leave.

        hBuffer:BUFFER-CREATE().
        hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(wares2.rid-wares).
        hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  wares2.alfa-cod.
        hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = string(wares2.alfa-cod) + " " + wares2.wares-name.
      end.
      RETURN.
    end.
  end.
  if basetype = "WARE3" then
  do:
    if NUM-ENTRIES (AppendParam) < 2 then RETURN.
    wr-date = DATE(ENTRY(1, AppendParam,";")) NO-ERROR.
    wr-count = ENTRY(2, AppendParam,";").

    FOR EACH system.wh-object WHERE
      system.wh-object.count = wr-count AND
      system.wh-object.rid-ent = rid-ent AND
      system.wh-object.object-param = "" NO-LOCK,
      each system.wares WHERE system.wares.rid-anobject = system.wh-object.rid-anobject NO-LOCK :
  
      if not AllRecords then
      do:
        if not (string(system.wares.alfa-cod) + " " + system.wares.wares-name matches "*" + searchstring + "*") then NEXT.
      end.
 
      run src/kernel/gwh_rq.p ( wr-count, system.wh-object.rid-anobject, "", wr-date, OUTPUT wr-rest ).
      if wr-rest <= 0 then NEXT. /* Товары которых нет на складе - пропускаются */

      itemcount = itemcount - 1.
      if itemcount < 0 /* and not AllRecords */ then leave.

      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.wares.rid-wares).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.wares.alfa-cod.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(system.wares.alfa-cod) + " " + system.wares.wares-name.
    end.
    if itemcount < 0 then AllRecords = false.
    RETURN.
  end.
  if basetype = "WARELIST" then
  do:
    if AppendParam <> "" then
    do:
      do wr-i = 1 to num-entries ( AppendParam ):
        find first system.wares where system.wares.alfa-cod = entry ( wr-i, AppendParam ) no-lock no-error.
        if not available system.wares then NEXT.

        if not AllRecords then
        do:
          if not (string(system.wares.alfa-cod) + " " + system.wares.wares-name matches "*" + searchstring + "*") then NEXT.
        end.
    
        itemcount = itemcount - 1.
        if itemcount < 0 and not AllRecords then leave.

        hBuffer:BUFFER-CREATE().
        hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.wares.rid-wares).
        hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.wares.alfa-cod.
        hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
          string(system.wares.alfa-cod) + " " + system.wares.wares-name.
      end.
    end.
  end.

  find first system.cathg where system.cathg.rid-cathg = currid-cathg no-lock no-error.
  if not available system.cathg then return.
  find first system.ctg-options of system.cathg no-lock no-error.
  if not available system.ctg-options then return.

  for each system.wares no-lock where AllRecords OR
    string(system.wares.alfa-cod) + " " + system.wares.wares-name matches "*" + searchstring + "*"
    by system.wares.alfa-cod:

    if system.wares.hidden then NEXT.
    if not system.ctg-options.is-allware then
    do:
      run src/kernel/wr_root.p (system.wares.alfa-cod, output wr-root).
      find first wares2 where wares2.alfa-cod = wr-root no-lock no-error.
      if available wares2 and not can-find(system.ctg-ware of wares2 where
        system.ctg-ware.rid-cathg = currid-cathg no-lock) then NEXT.
    end.
    if w-type <> ? and w-type <> 0 then 
    do:
      run src/custom/sach_c.p (w-type, system.wares.w-type, output wr-in).
      if not wr-in then NEXT.
    end.

    if is-leaf <> ? then
    do:
      find first wares2 where wares2.rid-upwares = system.wares.rid-wares no-lock no-error.
      if available wares2 and is-leaf = true or not available wares2 and is-leaf = false then NEXT.
    end.

    if rid-upwares <> ? then
    do:
      run CheckWrGroup ( rid-upwares, system.wares.rid-wares).
      if return-value = "NO" then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 /* and not AllRecords */ then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.wares.rid-wares).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.wares.alfa-cod.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.wares.alfa-cod) + " " + system.wares.wares-name.
  end.
  if itemcount < 0 then AllRecords = false.
end.

if basetype = "TASGTYPE" then
do:
  for each system.tr-assign-type no-lock where AllRecords OR
    string(system.tr-assign-type.id-assign-type) + " " + system.tr-assign-type.name-assign-type matches "*" + searchstring + "*"
    by system.tr-assign-type.id-assign-type:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.tr-assign-type.rid-assign-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.tr-assign-type.id-assign-type.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.tr-assign-type.id-assign-type) + " " + system.tr-assign-type.name-assign-type.
  end.
end.

if basetype = "TIMETYPE" then
do:
  define variable t-hours as integer.

  t-hours = INTEGER(searchstring) NO-ERROR.
  IF NOT ERROR-STATUS:ERROR and searchstring <> "" THEN
  DO:
    Find First system.ttime WHERE
               system.ttime.flag-def = yes NO-LOCK NO-ERROR.
    IF AVAILABLE system.ttime then
    do:
      if t-hours > 24 then t-hours = 0. 

      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = system.ttime.id-ttime + STRING ( t-hours ).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.ttime.id-ttime + STRING ( t-hours ).
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.ttime.id-ttime + STRING ( t-hours ).
      RETURN.
    end.
  end.
 
  for each system.ttime no-lock where AllRecords OR
    string(system.ttime.id-ttime) matches "*" + searchstring + "*"
    by system.ttime.id-ttime:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = system.ttime.id-ttime.
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.ttime.id-ttime.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.ttime.id-ttime.
  end.
end.
if basetype = "TIMETYPE2" then
do:
  for each system.ttime no-lock where AllRecords OR
    string(system.ttime.id-ttime) + " " + system.ttime.name-ttime matches "*" + searchstring + "*"
    by system.ttime.id-ttime:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.ttime.rid-ttime).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.ttime.id-ttime.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.ttime.id-ttime) + " " + system.ttime.name-ttime.
  end.
end.

if basetype = "TRADEMARK" then
do:
  for each system.trademarks no-lock where AllRecords OR
    string(system.trademarks.id-trademark) + " " + system.trademarks.name-trademark matches "*" + searchstring + "*"
    by system.trademarks.id-trademark:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.trademarks.rid-trademark).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.trademarks.id-trademark.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.trademarks.id-trademark) + " " + system.trademarks.name-trademark.
  end.
end.

if basetype = "TRANSORDER" then
do:
  if ContextParam <> "" then
    AppendParam = ContextParam.
  run SelectTraspCars ( AppendParam, searchstring ).
end.

if basetype = "TREATMENT" then
do:
  for each system.treatment no-lock where AllRecords OR
    string(system.treatment.id-treatment) + " " + system.treatment.name-treatment matches "*" + searchstring + "*"
    by system.treatment.id-treatment:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.treatment.rid-treatment).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.treatment.id-treatment.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.treatment.id-treatment) + " " + system.treatment.name-treatment.
  end.
end.

if basetype = "TSRVTYPE" then
do:
  for each system.tr-service-type no-lock where AllRecords OR
    string(system.tr-service-type.id-service-type) + " " + system.tr-service-type.name-service-type matches "*" + searchstring + "*"
    by system.tr-service-type.id-service-type:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.tr-service-type.rid-service-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.tr-service-type.id-service-type.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.tr-service-type.id-service-type) + " " + system.tr-service-type.name-service-type.
  end.
end.
if basetype = "TWKSCHED" then
do:
  for each system.tr-work-schedule no-lock where AllRecords OR
    string(system.tr-work-schedule.id-work-schedule) + " " + system.tr-work-schedule.name-work-schedule matches "*" + searchstring + "*"
    by system.tr-work-schedule.id-work-schedule:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.tr-work-schedule.rid-work-schedule).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.tr-work-schedule.id-work-schedule.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.tr-work-schedule.id-work-schedule) + " " + system.tr-work-schedule.name-work-schedule.
  end.
end.
if basetype = "TWORK" then
do:
  define variable tr-worktype as integer.
  define variable up-work as integer initial ?.

  if AppendParam <> "" then
    tr-worktype = INTEGER (AppendParam) NO-ERROR.
  
  if ContextParam <> "" then 
  do:
    find first system.tr-work where system.tr-work.work-code = entry(1, ContextParam) NO-LOCK NO-ERROR.
    if available system.tr-work then
      up-work = system.tr-work.rid-work.
    if num-entries(ContextParam) > 1 then tr-worktype = integer(entry(2, ContextParam)) NO-ERROR.
  end.
  if tr-worktype = 0 then tr-worktype = ?.

  for each system.tr-work no-lock where 
    (system.tr-work.rid-work-rectype = tr-worktype OR  tr-worktype = ?) and
    (AllRecords OR
    string(system.tr-work.work-code) + " " + system.tr-work.work-name matches "*" + searchstring + "*")
    by system.tr-work.work-code:

    if up-work <> ? then
    do:
      run CheckWork ( up-work, system.tr-work.rid-upwork).
      if return-value = "NO" then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.tr-work.rid-work).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.tr-work.work-code.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.tr-work.work-code) + " " + system.tr-work.work-name.
  end.
end.

if basetype = "TT-TYPE" then
do:
  for each system.point-type no-lock where AllRecords OR
    string(system.point-type.id-type) + " " + system.point-type.name-type matches "*" + searchstring + "*"
    by system.point-type.id-type:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.point-type.rid-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.point-type.id-type.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.point-type.id-type) + " " + system.point-type.name-type.
  end.
end.

if basetype = "TYPEDOC" then
do:
  for each system.typedoc no-lock where AllRecords OR
    string(system.typedoc.id-typedoc) + " " + system.typedoc.name-typedoc matches "*" + searchstring + "*"
    by system.typedoc.id-typedoc:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.typedoc.rid-typedoc).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.typedoc.id-typedoc.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.typedoc.id-typedoc) + " " + system.typedoc.name-typedoc.
  end.
end.

if basetype = "TYPERATE" then
do:
  for each system.typerate no-lock where AllRecords OR
    string(system.typerate.id-typerate) + " " + system.typerate.name-typerate matches "*" + searchstring + "*"
    by system.typerate.id-typerate:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.typerate.rid-typerate).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.typerate.id-typerate.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.typerate.id-typerate) + " " + system.typerate.name-typerate.
  end.
end.

if basetype = "USERS" then
do:
  define variable id-wc as integer initial ?.
  define variable rid-workcenter as integer initial ?.

  if ContextParam <> "" then 
    AppendParam = ContextParam.
  if AppendParam <> "" then
    id-wc = INTEGER (AppendParam) NO-ERROR.
  FIND FIRST workcenter WHERE workcenter.id-workcenter = id-wc NO-LOCK NO-ERROR.
  IF AVAILABLE workcenter THEN
    rid-workcenter = workcenter.rid-workcenter.

  for each system.users no-lock where AllRecords OR
    string(system.users.sys-name) + " " + system.users.name matches "*" + searchstring + "*"
    by system.users.sys-name:

    if rid-workcenter <> ? then
    do:
      find first user-wc-set where user-wc-set.rid-user = users.rid-user AND
           user-wc-set.rid-workcenter = rid-workcenter NO-LOCK NO-ERROR.
      if not available user-wc-set then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.users.rid-user).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.users.sys-name.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.users.sys-name) + " " + system.users.name.
  end.
end.

define new shared temp-table cnst-table  /* Для статей по ЦБ*/
    field val as character format "x(20)"
    field name as character format "x(20)".

define buffer vcalc2 for system.vcalc-item.
if basetype = "VCALCITEM" or basetype = "VCALCITEM1" then
do:
  define variable id-vcalc as integer.

  if AppendParam = "1" and basetype = "VCALCITEM" then
  do:
    run src/sec/consttable.p.

    for each cnst-table,
        each system.vcalc-item no-lock where 
        INTEGER(cnst-table.val) = system.vcalc-item.id-vcalc-item and
        (AllRecords OR
         string(system.vcalc-item.id-user-item) + " " + system.vcalc-item.name-vcalc-item matches "*" + searchstring + "*")
       by system.vcalc-item.id-user-item:

      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.

      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.vcalc-item.rid-vcalc-item).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.vcalc-item.id-user-item.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(system.vcalc-item.id-user-item) + " " + system.vcalc-item.name-vcalc-item.
    end.
    RETURN.
  end.
  if basetype = "VCALCITEM1" then
  do:
    id-vcalc = INTEGER( AppendParam ) NO-ERROR.
    for first vcalc2 NO-LOCK where
              vcalc2.id-user-item = id-vcalc,
        each  rel-item NO-LOCK where
              rel-item.rid-vcalc-item = vcalc2.rid-vcalc-item,
        first system.vcalc-item NO-LOCK where
              system.vcalc-item.rid-vcalc-item = rel-item.rid-rel-item
              by system.vcalc-item.id-user-item:

      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.

      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.vcalc-item.rid-vcalc-item).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.vcalc-item.id-user-item.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(system.vcalc-item.id-user-item) + " " + system.vcalc-item.name-vcalc-item.
    end.
  end.

  for each system.vcalc-item no-lock where AllRecords OR
    string(system.vcalc-item.id-user-item) + " " + system.vcalc-item.name-vcalc-item matches "*" + searchstring + "*"
    by system.vcalc-item.id-user-item:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.vcalc-item.rid-vcalc-item).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.vcalc-item.id-user-item.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.vcalc-item.id-user-item) + " " + system.vcalc-item.name-vcalc-item.
  end.
end.
if basetype = "VPAYMENT" then
do:
  for each system.vpayment no-lock where AllRecords OR
    string(system.vpayment.id-vpayment) + " " + system.vpayment.name-vpayment matches "*" + searchstring + "*"
    by system.vpayment.id-vpayment:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.vpayment.id-vpayment).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.vpayment.id-vpayment.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.vpayment.id-vpayment) + " " + system.vpayment.name-vpayment.
  end.
end.
if basetype = "VPOS-DIV" then
do:
  define variable vpos-name as character.

  for each system.division NO-LOCK,
      each system.vposition NO-LOCK
    by system.division.code-division:

    FIND FIRST system.vpos-div WHERE
               system.vpos-div.rid-division  = system.division.rid-division AND
               system.vpos-div.rid-vposition = system.vposition.rid-vposition AND
               system.vpos-div.bdate <= TODAY USE-INDEX i-primary NO-LOCK NO-ERROR.

    vpos-name = STRING(system.vpos-div.bdate, "99/99/99").
    vpos-name = vpos-name + " " + system.division.code-division.
    vpos-name = vpos-name + " " + system.vposition.name-vposition + " " + vpos-div.descr-vpos-div.
    if not Allrecords then
    do:
      if not (vpos-name matches "*" + searchstring + "*") then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.vpos-div.rid-vpos-div).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.division.code-division + " " + system.vposition.name-vposition.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = vpos-name.
  end.
end.
if basetype = "VPOSITION" then
do:
  for each system.vposition no-lock where AllRecords OR
    string(system.vposition.id-vposition) + " " + system.vposition.name-vposition matches "*" + searchstring + "*"
    by system.vposition.id-vposition:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.vposition.rid-vposition).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.vposition.id-vposition.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.vposition.id-vposition) + " " + system.vposition.name-vposition.
  end.
end.
if basetype = "VPOSITCLS" then
do:
  for each system.vposition no-lock where AllRecords OR
    STRING ( system.vposition.id-vposition ) + " " + string(system.vposition.id-classificator) + " " + 
      system.vposition.name-vposition matches "*" + searchstring + "*"
    by system.vposition.id-vposition:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.vposition.rid-vposition).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.vposition.id-classificator.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = STRING ( system.vposition.id-vposition ) + " (" +
      string(system.vposition.id-classificator) + ") " + system.vposition.name-vposition.
  end.
end.

if basetype = "WAREHOUSE" or basetype = "WAREHOUSE2" or basetype = "WH_LIST" or basetype = "WR_H_SEL" then
do:
  define variable wh-type as integer.
  define variable wh-found as logical.
  define variable wh-i as integer.

  wh-type = ?.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  if AppendParam <> "" AND basetype = "WAREHOUSE2" then
    wh-type = INTEGER(AppendParam).

  Find First system.ctg-options WHERE system.ctg-options.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.ctg-options then RETURN.

  if AppendParam <> "" and basetype = "WH_LIST" then
  do:
    do wh-i = 1 to NUM-ENTRIES(AppendParam):
      find first system.warehouse where 
        system.warehouse.id-wh = INTEGER(ENTRY (wh-i, AppendParam)) and
        (AllRecords OR
         string(system.warehouse.id-wh) + " " + system.warehouse.name-wh matches "*" + searchstring + "*")
        NO-LOCK NO-ERROR.
      if not available system.warehouse then NEXT.

      if system.ctg-options.is-allextacc = false then 
      do:
        wh-found = false.
        for each system.ext-acc OF system.warehouse NO-LOCK,
            each system.ctg-extacc OF system.ext-acc WHERE
            system.ctg-extacc.rid-cathg = currid-cathg NO-LOCK :
          wh-found = true.
        end.
        if wh-found = false then NEXT.
      end.
  
      itemcount = itemcount - 1.
      if itemcount < 0 and not AllRecords then leave.
  
      hBuffer:BUFFER-CREATE().
      hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.warehouse.rid-wh).
      hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.warehouse.id-wh.
      hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
        string(system.warehouse.id-wh) + " " + system.warehouse.name-wh.
    end.
    RETURN.
  end.

  for each system.warehouse no-lock where AllRecords OR
    string(system.warehouse.id-wh) + " " + system.warehouse.name-wh matches "*" + searchstring + "*"
    by system.warehouse.id-wh:

    if system.ctg-options.is-allextacc = false then 
    do:
      wh-found = false.
      for each system.ext-acc OF system.warehouse NO-LOCK,
          each system.ctg-extacc OF system.ext-acc WHERE
          system.ctg-extacc.rid-cathg = currid-cathg NO-LOCK :
        wh-found = true.
      end.
      if wh-found = false then NEXT.
    end.
    if wh-type <> ? then
    do:
      run src/custom/sach_c.p (wh-type, system.warehouse.w-type, output wh-found).
      if not wh-found then NEXT.
    end.

    if basetype = "WR_H_SEL" and AppendParam <> "" then
    do:
      if not (substring (system.warehouse.count, length ( system.warehouse.count ) - 
          length ( AppendParam ) + 1, length ( AppendParam ) ) = AppendParam) then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.warehouse.rid-wh).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.warehouse.id-wh.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.warehouse.id-wh) + " " + system.warehouse.name-wh.
  end.
end.
if basetype = "WARETYPE" then
do:
  define variable wt-restrict as integer.
  wt-restrict = ?.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  if AppendParam <> "" then
    wt-restrict = INTEGER(AppendParam).

  for each system.wares-types no-lock where AllRecords OR
    system.wares-types.w-name matches "*" + searchstring + "*"
    by system.wares-types.w-name:

    if wt-restrict <> ? then
    do:
      RUN src/custom/sach_isd.p (system.wares-types.w-type, wt-restrict).
      if return-value <> "OK" then NEXT.
    end.

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.wares-types.w-type).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE = system.wares-types.w-name.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.wares-types.w-name.
  end.
end.

if basetype = "WRKSCHED" then
do:
  for each system.work-schedule no-lock where AllRecords OR
    string(system.work-schedule.id-work-schedule) + " " + system.work-schedule.name-work-schedule matches "*" + searchstring + "*"
    by system.work-schedule.id-work-schedule:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.work-schedule.rid-work-schedule).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.work-schedule.id-work-schedule.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.work-schedule.id-work-schedule) + " " + system.work-schedule.name-work-schedule.
  end.
end.
if basetype = "WORKCLDR" then /* Составной базовый тип, заменяется множеством простых, при помощи спец диалога */
do:
end.

if basetype = "WORKCENTER" then
do:
  for each system.workcenter no-lock where AllRecords OR
    string(system.workcenter.id-workcenter) + " " + system.workcenter.name-workcenter matches "*" + searchstring + "*"
    by system.workcenter.id-workcenter:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.workcenter.rid-workcenter).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.workcenter.id-workcenter.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.workcenter.id-workcenter) + " " + system.workcenter.name-workcenter.
  end.
end.

if basetype = "WORKSHOP" then
do:
  for each system.workshop no-lock where AllRecords OR
    string(system.workshop.id-workshop) + " " + system.workshop.name-workshop matches "*" + searchstring + "*"
    by system.workshop.id-workshop:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.workshop.rid-workshop).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.workshop.id-workshop.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.workshop.id-workshop) + " " + system.workshop.name-workshop.
  end.
end.

if basetype = "WR-PARAM" then
do:
  for each system.wares-param no-lock where AllRecords OR
    string(system.wares-param.id-param) + " " + system.wares-param.name-param matches "*" + searchstring + "*"
    by system.wares-param.id-param:

    itemcount = itemcount - 1.
    if itemcount < 0 and not AllRecords then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = string(system.wares-param.rid-param).
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.wares-param.id-param.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = 
      string(system.wares-param.id-param) + " " + system.wares-param.name-param.
  end.
end.
if basetype = "WRPARVAL" then
do:
  define variable rid-wrparam as integer.

  if ContextParam <> "" then
    AppendParam = ContextParam.
  if AppendParam <> "" then
    rid-wrparam = INTEGER(AppendParam).

  for each system.param-value no-lock where system.param-value.rid-param = rid-wrparam and
    (AllRecords OR system.param-value.val matches "*" + searchstring + "*")
    by system.param-value.val-date desc:

    itemcount = itemcount - 1.
    if itemcount < 0 /* and not AllRecords */ then leave.

    hBuffer:BUFFER-CREATE().
    hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = system.param-value.val.
    hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  system.param-value.val.
    hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = system.param-value.val.
  end.
  if itemcount < 0 then AllRecords = false.
end.



PROCEDURE AccountFilter:
  define input parameter anal-filter-list as character.

  define variable i as integer.

  Find First system.ctg-options
    WHERE system.ctg-options.rid-cathg = currid-cathg NO-LOCK NO-ERROR.
  IF NOT AVAILABLE system.ctg-options then RETURN.
  if system.ctg-options.is-allaccplan = true then 
  do:
    for each system.acc-plan NO-LOCK :
      create AvailPlans.
      AvailPlans.plan = system.acc-plan.plan.
    end.
  end.
  else do:
    FOR EACH system.ctg-accplan  
       WHERE system.ctg-accplan.rid-cathg = currid-cathg NO-LOCK :
      create AvailPlans.
      AvailPlans.plan = system.ctg-accplan.plan.
    end.   
  end. 
  IF anal-filter-list = "" then 
  do:
    for each system.anobject 
      WHERE system.anobject.rid-upobject = RootOfAnobject NO-LOCK :
      CREATE anal-filter.
      anal-filter.rid-anobject = system.anobject.rid-anobject.
    end.
  end.
  else do:
    do i = 1 TO NUM-ENTRIES ( anal-filter-list ).
      find First system.anobject 
       WHERE system.anobject.rid-upobject = RootOfAnobject AND
         system.anobject.id-anobject = INTEGER ( ENTRY ( i, anal-filter-list ) ) 
           NO-LOCK NO-ERROR.
      IF AVAILABLE system.anobject then 
      do:
        CREATE anal-filter.
        anal-filter.rid-anobject = system.anobject.rid-anobject.
      end.        
    end.
  end.
end.

PROCEDURE CheckDiv:
  define input parameter rid-tree as integer.
  define input parameter rid-div as integer.

  repeat:
    if rid-tree = rid-div then RETURN "YES".
    find first system.division where system.division.rid-division = rid-div NO-LOCK NO-ERROR.
    if not available system.division then RETURN "NO".
    if system.division.rid-division = system.division.rid-divisionup then RETURN "NO".
    rid-div = system.division.rid-divisionup.
  end.
  return "YES".
END.

define buffer wares3 for system.wares.
PROCEDURE CheckWrGroup:
  define input parameter rid-tree as integer.
  define input parameter rid-wares as integer.

  repeat:
    if rid-tree = rid-wares then RETURN "YES".
    find first wares3 where wares3.rid-wares = rid-wares NO-LOCK NO-ERROR.
    if not available wares3 then RETURN "NO".
    if wares3.rid-upwares = ? then RETURN "NO".
    rid-wares = wares3.rid-upwares.
  end.
  return "YES".
END.

PROCEDURE CheckWork:
  define input parameter rid-tree as integer.
  define input parameter rid-work as integer.

  repeat:
    if rid-tree = rid-work then RETURN "YES".
    find first system.tr-work where system.tr-work.rid-work = rid-work NO-LOCK NO-ERROR.
    if not available system.tr-work then RETURN "NO".
    if system.tr-work.rid-upwork = ? then RETURN "NO".
    rid-work = system.tr-work.rid-upwork.
  end.
  return "YES".
END.


define buffer geo-territ2 for system.geo-territ.
PROCEDURE CalcGeo:
  define input parameter rid-territ as integer.
  define output parameter geo-code as character initial "".
  define output parameter geo-name as character initial "".

  define variable geo-code2 as character.
  define variable geo-name2 as character.

  FIND FIRST geo-territ2 WHERE geo-territ2.rid-territ = rid-territ NO-LOCK NO-ERROR.
  IF NOT AVAILABLE geo-territ2 THEN RETURN.

  geo-code = string(geo-territ2.id-territ).
  geo-name = geo-territ2.name-territ.

  RUN CalcGeo (geo-territ2.rid-territup, output geo-code2, output geo-name2).

  if geo-code2 <> "" then
  do:
    geo-code = geo-code2 + " -> " + geo-code.
    geo-name = geo-name2 + " -> " + geo-name.
  end.
END PROCEDURE.


&Scoped-define order-td 12008 /* Тип документа заказ автотранспорта */
define temp-table temp-cars
  field   car-num              as   char          
  field   car-mark             as   char  
  field   driver-name          as   char   
  field   exped-name           as   char  
  field   car-whgt             as   decimal  
  field   car-volume           as   decimal  
  field   rid-d                as   int
  field   rid-emp              as   int
  field   row                  as   int
  field   num                  as   int
  field   time-in              as   character
  field   date-in              as   date
  index   i0 date-in time-in car-num.

PROCEDURE SelectTraspCars:
  define input parameter str as character.
  define input parameter searchstring as character.

  define variable result    as character no-undo.
  define var type-doc       as integer initial ? no-undo.
  define var rid-doc        as int       no-undo.
  define var flds           as character no-undo.
  define var i              as integer   no-undo.
  define var fld-list       as character no-undo.
  define var value-list     as character no-undo.
  define var app-param      as character no-undo.
  define var int-temp       as int       no-undo.
  define var choose-str     as character no-undo.
  define var val-str        as character no-undo.
  define var tmp-str        as character no-undo.
                           
  define var tmp-str2       as character no-undo.
  define var car-num        as character no-undo.
  define var car-mark       as character no-undo.

  define var driver-name    as character no-undo.
  define var exped-name     as character no-undo.
  define var car-whgt       as decimal  no-undo.
  define var car-volume     as decimal  no-undo.
                           
  define var rows           as int       no-undo.
  define var num            as int       no-undo.
  define var rid-emp        as int       no-undo.
  define var time-in        as character no-undo.
  define var date-in        as date format "99/99/99" no-undo.
  define var d-time         as integer no-undo.


  define var order-date as date no-undo LABEL "Введите дату заезда транспорта" FORMAT "99/99/9999"
   view-as fill-in size 16 by 1.
  define var rc   as int no-undo.
    
  order-date = DATE (ENTRY( 1, str) ) NO-ERROR.
  if order-date = ? then
  do:
    order-date = DATE (ENTRY( 1, searchstring, " ") ) NO-ERROR.
    if order-date = ? then RETURN.
    else do:
      if index (searchstring, " ") > 0 then
        searchstring = substring (searchstring, index (searchstring, " ") + 1).
      else 
        searchstring = "".
    end.
  end.

  run src/kernel/getfrddc.p ( {&order-td} , order-date - 1, order-date + 1,
                             "", "", "", OUTPUT int-temp ).
  EMPTY TEMP-TABLE temp-cars.

  DO WHILE int-temp <> ?:
    find first document where document.rid-document = int-temp NO-LOCK NO-ERROR.
    if not available document then
    do:
      RUN src/kernel/getnxdoc.p (OUTPUT int-temp). 
      next.
    end.
    if document.put-off = true then
    do:
      RUN src/kernel/getnxdoc.p (OUTPUT int-temp). 
      next.
    end.
    date-in = document.date-doc.

    run src/kernel/get_tr.p ( 2 , int-temp , OUTPUT rows ). 
    DO i = 1 TO rows :
      run src/kernel/get_ftv.p ( "2:2", int-temp, i ).
      car-num  = TRIM(RETURN-VALUE).
      IF car-num = "" THEN NEXT.

      if not AllRecords then
      do:
        if not (car-num matches "*" + searchstring + "*") then NEXT.
      end.

      run src/kernel/get_ftv.p ( "2:3", int-temp, i ).
      car-mark    = RETURN-VALUE.
      run src/kernel/get_ftv.p ( "2:4", int-temp, i ).
      driver-name = RETURN-VALUE. 
      run src/kernel/get_ftv.p ( "2:5", int-temp, i ).
      exped-name  = RETURN-VALUE. 
      run src/kernel/get_ftv.p ( "2:6", int-temp, i ).
      car-whgt    = DECIMAL ( RETURN-VALUE). 
      run src/kernel/get_ftv.p ( "2:7", int-temp, i ).
      car-volume  = DECIMAL ( RETURN-VALUE).
      run src/kernel/get_ftp.p ( "2:8", "rid-emp", int-temp, i ).
      rid-emp = INTEGER(RETURN-VALUE) .
  
      RUN src/kernel/get_ftv.p ( "Время", int-temp, i ).
      time-in = RETURN-VALUE NO-ERROR.
  
      if num-entries(time-in, ":") > 1 then
        d-time = 60 * integer(entry(1, time-in, ":")) + integer(entry(2, time-in, ":")) NO-ERROR.
      else
        d-time = 60 * integer(time-in) NO-ERROR.
      time-in = string(truncate (d-time / 60,0), "99") + ":" + string(d-time modulo 60, "99") NO-ERROR.
    
      tmp-str  = "№ " + car-num + " " + car-mark + " (" + string(date-in,"99/99/99") + " " + time-in + ")". 
  
      find first temp-cars where temp-cars.car-num = car-num and temp-cars.time-in = time-in and
         temp-cars.date-in = date-in NO-LOCK NO-ERROR.
      if not available temp-cars then
      do:
        create temp-cars.
        ASSIGN                          
             temp-cars.car-num        =  car-num     
             temp-cars.car-mark       =  car-mark    
             temp-cars.driver-name    =  driver-name 
             temp-cars.exped-name     =  exped-name
             temp-cars.car-whgt       =  car-whgt 
             temp-cars.car-volume     =  car-volume
             temp-cars.row            =  i  
             temp-cars.num            =  num
             temp-cars.rid-d          =  int-temp
             temp-cars.rid-emp        =  rid-emp
             temp-cars.time-in        =  time-in
             temp-cars.date-in        =  date-in.

        result = 
             REPLACE(STRING(temp-cars.row)       ,"|","")      + "|" +   
             REPLACE(STRING(temp-cars.rid-d)     ,"|","")      + "|" +       
             REPLACE(temp-cars.car-num           ,"|","")      + "|" +    
             REPLACE(temp-cars.car-mark          ,"|","")      + "|" +       
             REPLACE(temp-cars.driver-name       ,"|","")      + "|" +   
             REPLACE(temp-cars.exped-name        ,"|","")      + "|" +   
             REPLACE(STRING(temp-cars.car-whgt)  ,"|","")      + "|" +   
             REPLACE(STRING(temp-cars.car-volume),"|","")      + "|" +     
             REPLACE(STRING(temp-cars.rid-emp),   "|","").

        itemcount = itemcount - 1.
        if itemcount < 0 /* and not AllRecords */ then leave.

        hBuffer:BUFFER-CREATE().
        hBuffer:BUFFER-FIELD("IntValue"):BUFFER-VALUE = result.
        hBuffer:BUFFER-FIELD("IdValue"):BUFFER-VALUE =  tmp-str.
        hBuffer:BUFFER-FIELD("FormValue"):BUFFER-VALUE = tmp-str.
  
      end.
    END.
    if itemcount < 0 /* and not AllRecords */ then leave.
                       
    RUN src/kernel/getnxdoc.p (OUTPUT int-temp). 
  END.
  AllRecords = false.
END.
