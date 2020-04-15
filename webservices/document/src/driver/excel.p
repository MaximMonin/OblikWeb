/* Copyright (C) Maxim A. Monin 2009-2010 */

/* Excel driver. based on usrc/drivers/excel.p */

define input parameter in-file as character.
define output parameter xls-file as character.
define output parameter local-file as character.
define output parameter OutMessage as character.

/* Если переданный файл имеет расширение .xml, использовать
** драйвер переноса в Excel через XML
*/
define variable template as character.
define variable out-file as character.
define variable out-template as character.

run src/system/gtprpar.p ( "OUT-ONLY" ).
if not (RETURN-VALUE = "Да" or RETURN-VALUE = "Yes") then
do:
  if in-file matches "*~.xml" then
  do:

    run src/system/gtprpar.p ("TEMPLATE").
    template = return-value.

    out-file = substr(in-file, r-index(in-file, "/") + 1).
    if out-file matches "*~.xml" then
    do:
      out-file = substr (out-file, 1, length (out-file) - 4).
      if out-file matches "*~.xls" then
        out-file = substr (out-file, 1, length (out-file) - 4).
    end.
    out-template = out-file + ".xls".
    out-file = out-file + ".xls.xml".

    xls-file = template + "," + in-file.
    local-file = out-template + "," + out-file.

    return.
  end.
end.
/**/

run src/system/gtprpar.p ( "OUT-ONLY" ).
if RETURN-VALUE = "Да" or RETURN-VALUE = "Yes" then
do:
  if search(in-file) = ? then
  do:
    xls-file = "".
    local-file = "".
    RETURN.
  end.
  else do:
    xls-file = in-file.
    if R-INDEX (xls-file, "/") > 0 then
      local-file = SUBSTRING(xls-file, R-INDEX (xls-file, "/") + 1 ). 
    else
      local-file = xls-file.
    RETURN.
  end.
end.

def var rid-doc as integer.
def var file-version as integer.
def var nraw# as raw.

run src/system/gtprpar.p ( "TEMPLATE" ).
template = RETURN-VALUE.                
run src/system/gtprpar.p ( "DOC" ). 
rid-doc = INTEGER(RETURN-VALUE).
if template = "" then
do:
  find first system.document where system.document.rid-document = rid-doc 
    NO-LOCK NO-ERROR.
  if available system.document then
  do:
    find first system.typedoc of system.document NO-LOCK NO-ERROR.
    if available system.typedoc then
    do:
      if system.typedoc.id-typedoc <= 999 then
        template = "usrc/template/templ" + STRING(system.typedoc.id-typedoc, "999") + ".xls".
      else
        template = "usrc/template/templ" + TRIM(STRING(system.typedoc.id-typedoc, ">>>>>9")) + ".xls".
    end.
  end.
end.
IF template = "" THEN
  file-version = 9.
ELSE DO:
  INPUT FROM VALUE(template) BINARY NO-CONVERT.
  LENGTH(nraw#) = 2.
  import unformatted nraw#.
  file-version = GET-SHORT(nraw#,1).
  INPUT CLOSE.
END.

if in-file <> "" then
do:
  /* При наличии шаблона на сервере в формате Excel 2.1 
     используется другая технология формирования выходного файла */                                                       
  if template <> "" then
  do:
    /* Сформировать файл на основе инструкций и файла шаблона */
    IF file-version = 9 THEN
      run src/xls/convert.p (rid-doc, in-file, template, ?).
    else
      run src/xls95/convert2.p (0, in-file, template).
    xls-file = return-value.

    if R-INDEX (xls-file, "/") > 0 then
      local-file = SUBSTRING(xls-file, R-INDEX (xls-file, "/") + 1 ). 
    else
      local-file = xls-file.
    os-delete value(in-file).
    RETURN "OK".
  end.
  else do:
    /* попытка создать отчет по подготовленному файлу и шаблону в формате excel 95 */
    run src/xls95/convert2.p (0, in-file, "").
    if RETURN-VALUE <> "ERROR" THEN /* отчет создан */
    DO:
      xls-file = return-value.
      if R-INDEX (xls-file, "/") > 0 then
        local-file = SUBSTRING(xls-file, R-INDEX (xls-file, "/") + 1 ). 
      else
        local-file = xls-file.
      os-delete value(in-file).
      RETURN "OK".
    END.
    os-delete value(in-file).
  end.
end.
else do:
  /* Если входной файл инструкций не задан, то входные данные берутся непосредственно
     из документа, используя технологию описания шаблона с тегами где указаны алиасы
     полей документа или ссылки на константы                                           */
  IF file-version = 9 THEN
    run src/xls/toexcel.p (rid-doc, template).
  ELSE DO:
    run src/xls95/toexcel.p ( rid-doc, template).
  END.
  xls-file = return-value.
  if R-INDEX (xls-file, "/") > 0 then
    local-file = SUBSTRING(xls-file, R-INDEX (xls-file, "/") + 1 ). 
  else
    local-file = xls-file.
  RETURN "OK".
end.

xls-file = "".
local-file = "".
