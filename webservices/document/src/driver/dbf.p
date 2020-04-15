/* Copyright (C) Maxim A. Monin 2009-2010 */

/* Dbf driver. based on usrc/drivers/dbf.p */
/*********************************************************************

  Формат входного файла

  Входной файл состоит из двух секций: описания структуры и данных


  Секция 1. Описание структуры записи

  Описание структуры записи задается в форме последовательности строк
  следующего вида:

  name type width decimals

  где
    name        - имя поля (до 8-ми символов)
    type        - тип поля (C, N, L, D)
    width       - ширина поля
    decimals    - кол-во знаков после точки для типа N

  Секция завершается одной пустой строкой

  Секция 2. Данные

  Данные передаются в форме последовательности строк, где каждая строка
  соответствует одной записи в файле DBF.
  Значения полей в строке записываются подряд, без разделителей. Каждое
  значение должно иметь столько символов, сколько указано в описании
  данного поля в Секции 1.
  Строка должна заканчиваться символом "#".

  Признаком конца секции является одна пустая строка или конец файла

*********************************************************************/

define input parameter in-file as character.
define output parameter dbf-file as character.
define output parameter local-file as character.
define output parameter OutMessage as character.

define shared variable uid as character.

define variable dbf-struct as character.
define variable ok-flag    as logical.

define variable outdir     as character.
define variable outfile    as character.
define variable runfile    as character.

run src/system/gtprpar.p("OUTFILE").
outfile = return-value.

if outfile = "" or outfile = "?" or outfile = ? then 
  outfile = in-file.

local-file = substr(outfile, r-index(outfile, "/" ) + 1).                    
if not (local-file matches "*.dbf") then
  local-file = local-file + ".dbf".

run src/system/gtprpar.p("HANDLER").
runfile = RETURN-VALUE.
if runfile = "?" or runfile = ? then runfile = "".

define variable ln as character.

input from value(in-file).

/* Секция 1 */
repeat:
    import unformatted ln.
    ln = trim(ln).
    if ln = "" then leave.

    if dbf-struct <> "" then dbf-struct = dbf-struct + ",".
    dbf-struct = dbf-struct + ln.
end.

/* Секция 2 */
repeat:
    import unformatted ln.
    if ln = "" then leave.

    run DbfAddRecord(ln).
end.

input close.

os-delete value (in-file).

define variable tempfile as character.
tempfile = "temp/" + local-file.

run DbfWriteFile (tempfile, today, dbf-struct).
if search (tempfile) = ? then
do:
  dbf-file = "".
  local-file = "".
  return.
end.
dbf-file = tempfile.
return "OK".

/*****************************************************************************/

define temp-table dbf-table no-undo
    field rec-id as integer
    field rec-val as character
    index i-pr is primary unique rec-id.

define stream dbf.

PROCEDURE DbfAddRecord:
    define input parameter rec-val as character.

    define variable rec-id as integer.

    find last dbf-table use-index i-pr no-error.
    if available dbf-table then rec-id = dbf-table.rec-id + 1.
    else rec-id = 1.

    create dbf-table.
    dbf-table.rec-id = rec-id.
    dbf-table.rec-val = " " + codepage-convert (rec-val,"ibm866").
END.

PROCEDURE DbfWriteFile:
    define input parameter file as character.
    define input parameter date-update as date.
    define input parameter struct as character.

    output stream dbf to value(file) binary no-convert.

    define variable n-fields as integer.
    define variable hdr-len as integer.
    define variable rec-len as integer.
    define variable rec-count as integer.
    define variable f as integer.

    /***********************************************************************/
    /* Calculate number of fields, header length, record length and number */
    /***********************************************************************/

    n-fields = num-entries(struct).
    hdr-len = (n-fields + 1) * 32 + 1.
    rec-len = 1.

    do f = 1 to n-fields:
        rec-len = rec-len + int(entry(3, entry(f, struct), " ")).
    end.

    for each dbf-table no-lock:
        rec-count = rec-count + 1.
    end.

    /*********************/
    /* Write file header */
    /*********************/

    define variable nraw# as raw no-undo.

    /* byte 0: 0x03 identifies this file as a dBASE file */

    put stream dbf control "~003". 

    /* bytes 1-3: Date of last update */

    run makebinary(year(date-update) - 1900, 1, output nraw#).
    put stream dbf control nraw#.
    run makebinary(month(date-update), 1, output nraw#).
    put stream dbf control nraw#.
    run makebinary(day(date-update), 1, output nraw#).
    put stream dbf control nraw#.

    /* Put no of records (bytes 4-7) as a 4-byte binary number: */

    run makebinary(rec-count, 4, output nraw#).
    put stream dbf control nraw#.

    /* no of bytes in the header (bytes 8-9) */

    run makebinary(hdr-len, 2, output nraw#).
    put stream dbf control nraw#.
                                         
    /* bytes 10-11: record length */
   
    run makebinary(rec-len, 2, output nraw#).
    put stream dbf control nraw#.

    /* bytes 12-31: null */

    put stream dbf control null(20).

    /******************************/
    /* Write structure definition */
    /******************************/

    define variable i as integer.
    define variable fstr as character.
    define variable rec as raw.

    length(rec) = 32.

    do f = 1 to n-fields:
        fstr = entry(f, struct).

        do i = 1 to 32: put-byte(rec, i) = 0. end.

        put-string(rec, 1) = entry(1, fstr, " ").
        put-string(rec, 12) = entry(2, fstr, " ").
        put-byte(rec, 17) = int(entry(3, fstr, " ")).
        put-byte(rec, 18) = int(entry(4, fstr, " ")).

        put stream dbf control rec.
    end.

    put stream dbf control chr(13).

    /***********************/
    /* Write table records */
    /***********************/

    for each dbf-table no-lock by dbf-table.rec-id:
        put stream dbf unformatted substr(dbf-table.rec-val, 1, rec-len).
    end.

    put stream dbf unformatted chr(26). /* EOF marker */

    output stream dbf close.
END.

PROCEDURE makebinary:
  def input parameter anumm# as integer no-undo. /* number */
  def input parameter abyte# as integer no-undo. /* no of desired bytes */
  def output parameter nraw# as raw no-undo. /* result of conversion */
  
  def var acoun# as int no-undo. 
  
  assign length(nraw#) = abyte#.
                                                                            
  if anumm# <0 then do: message program-name(1) + ": This routine works for positive integers only." "Received value of" anumm# "is invalid." view-as alert-box error title "Conversion to binary". return error. end. if anumm#> 0 and anumm# modulo anumm# / EXP(anumm#,abyte#) > 256 then do:
    message program-name(1) + ": received number" anumm# 
           "does not fit in" abyte# "bytes."
           view-as alert-box error title "Conversion to binary".
    return error.
  end.
  
  
  do acoun# = abyte# to 1 by -1:
                                      
    put-byte(nraw#,acoun#) = int(truncate(anumm# / EXP(256,acoun# - 1),0)).
     
    if anumm# ne 0 then
      assign anumm# = anumm# modulo EXP(256,acoun# - 1).
 
  end.
  
END PROCEDURE. /* makebinary */

