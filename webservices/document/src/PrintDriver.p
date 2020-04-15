/* Copyright (C) Maxim A. Monin 2009-2010 */

define input-output parameter ContextId as character.
define input parameter Module as character.
define input parameter ViewOnly as logical.
define input parameter FileName as character.
define input parameter FileType as character.
define input parameter PrintParams as character.
define output parameter HostFileName as character.
define output parameter LocalFileName as character.
define output parameter OutMessage as character initial "".

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
OutMessage = ENTRY(l,"Ошибка чтения файла,File reading error").

/* Подключаем драйверы печати */

DEFINE TEMP-TABLE accs-od
 FIELD rid-od AS INTEGER.

DEFINE TEMP-TABLE par-tab
 FIELD par-name as character
 FIELD par-val  as character
 INDEX  i0 par-name.

define variable curr-od as integer.

if Module = "ViewText" then
  PrintParams = "".

Find First users WHERE users.sys-name = uid NO-LOCK NO-ERROR.
IF AVAILABLE users then
DO:
  run Table-params ( "", PrintParams ).
  RUN GetAccessOutDev (FileType, users.rid-user, OUTPUT curr-od).

  IF curr-od <> ? then
    RUN src/system/gtuprpar.p ( curr-od, users.rid-user, PrintParams, no ).
end.

if FileType = "EXCEL" then
do:
  run webservices/document/src/driver/excel.p (FileName, OUTPUT HostFileName, OUTPUT LocalFileName, OUTPUT OutMessage ).
  RETURN.
end.

if FileType = "TEXT" then
do:
  run webservices/document/src/driver/text.p (FileName, OUTPUT HostFileName, OUTPUT LocalFileName, OUTPUT OutMessage ).
  RETURN.
end.

if FileType = "DBF" then
do:
  run webservices/document/src/driver/dbf.p (FileName, OUTPUT HostFileName, OUTPUT LocalFileName, OUTPUT OutMessage ).
  RETURN.
end.

/* Простая обработка - выходной файл = входной */
HostFileName = FileName.
if R-INDEX (FileName, "/") > 0 then
  FileName = SUBSTRING(FileName, R-INDEX (FileName, "/") + 1 ). 
LocalFileName = FileName.
OutMessage = "".


PROCEDURE GetAccessOutDev :
  define input parameter FileType as character.
  define input parameter rid-user as integer.
  define output parameter curr-od as integer.

  define variable device as character.
  define variable i as integer.
  
  FOR EACH user-outdev    where user-outdev.rid-user = rid-user NO-LOCK,
      EACH out-device     OF user-outdev NO-LOCK,
      EACH type-outdevice OF out-device  NO-LOCK
      where type-outdevice.type-infile = FileType
      :

    CREATE accs-od.
    accs-od.rid-od = out-device.rid-od.
    Find first def-outdev WHERE
               def-outdev.rid-od      = out-device.rid-od AND
               def-outdev.rid-user    = users.rid-user    AND 
               def-outdev.type-infile = type-outdevice.type-infile
    NO-LOCK NO-ERROR.
    if AVAILABLE def-outdev then
      curr-od = out-device.rid-od.
  END.

  for each par-tab:
    if par-tab.par-name = "DEVICE" then
      device  = par-tab.par-val.
  end.
  find first out-device where 
    out-device.name-device = device NO-LOCK NO-ERROR.
  if available out-device then
  do: 
    find first accs-od where accs-od.rid-od = out-device.rid-od NO-LOCK NO-ERROR.
    if available accs-od then
      curr-od = out-device.rid-od.
  end.

  if curr-od = 0 then
  do:
    Find First accs-od NO-ERROR.
    IF AVAILABLE accs-od then curr-od = accs-od.rid-od.
  end.
END PROCEDURE.



PROCEDURE Table-params :
  define input parameter p1 as character.
  define input parameter p2 as character.

  def var rc as character.
  def var i as integer.
  def var param1 as character.
  def var par-sysname as character.
  def var par-val as character.
 
  EMPTY TEMP-TABLE par-tab.

  do i = 1 to NUM-ENTRIES ( p1, ";" ) : 
    param1 = ENTRY ( i, p1, ";").
    CREATE par-tab.
    par-tab.par-name = SUBSTRING ( param1, 1, INDEX ( param1, "=" ) - 1 ).
    par-tab.par-val  = SUBSTRING ( param1, INDEX ( param1, "=" ) + 1 ).
  end.

  do i = 1 to NUM-ENTRIES ( p2, ";" ) : 
    param1 = ENTRY ( i, p2, ";").
    FIND FIRST par-tab WHERE
      par-tab.par-name = SUBSTRING ( param1, 1, INDEX ( param1, "=" ) - 1 )
    NO-ERROR.
    IF NOT AVAILABLE par-tab then
    do:   
      CREATE par-tab.
      par-tab.par-name = SUBSTRING ( param1, 1, INDEX ( param1, "=" ) - 1 ).
    end. 
    par-tab.par-val  = SUBSTRING ( param1, INDEX ( param1, "=" ) + 1 ).
  end.
END PROCEDURE.
