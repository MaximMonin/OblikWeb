/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table ContextMenu NO-UNDO
  field ItemId as integer
  field ItemKey as character
  field ItemName as character
  field UpItem as integer
  field AppParam as character
  index i0 ItemId asc.

define input-output parameter ContextId as character.
define input parameter RidDoc as integer.
define input parameter ViewOnly as logical.
define output parameter table for ContextMenu.

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

define variable docright as integer.
define variable maxright as integer.
define variable i as integer.
define variable l as integer.

if lang begins "ru" then
  l = 1.
else
  l = 2.

find first system.document where system.document.rid-document = RidDoc NO-LOCK NO-ERROR.
if not available system.document then RETURN.

run src/kernel/docright.p ( RidDoc ).
docright = INTEGER(RETURN-VALUE).
RUN src/kernel/gmaxrigh.p ( system.document.rid-typedoc ).
maxright = INTEGER(RETURN-VALUE).

i = 0.
if docright >= 1 then
do:
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "DocView"
    ContextMenu.ItemName = ENTRY(l, "Просмотр документа,View document").
end.
if docright >= 2 and not ViewOnly then
do:
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "DocEdit"
    ContextMenu.ItemName = Entry(l, "Редактировать,Edit").
end.
if maxright >= 2 and not ViewOnly then
do:
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "NewDoc"
    ContextMenu.ItemName = Entry (l, "Создать новый,Create new").
end.
if maxright >= 2 and docright >= 1 and not ViewOnly then
do:
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "CopyDoc"
    ContextMenu.ItemName = ENTRY(l, "Копировать и редактировать,Copy and edit").
end.

define variable rid-maintype as integer.
define variable found as logical.
define variable found2 as logical.
define variable upitem as integer.
define variable upitem2 as integer.

rid-maintype = system.document.rid-typedoc.
found = false.
if not ViewOnly and docright >= 1 then
do:
  for each system.type_link where system.type_link.rid-main = rid-maintype NO-LOCK, 
      each system.typedoc where
           system.typedoc.rid-typedoc = system.type_link.rid-typedoc and
           system.typedoc.hidden = false NO-LOCK
    by system.typedoc.id-typedoc :

    RUN src/kernel/gmaxrigh.p ( system.typedoc.rid-typedoc ).
    if INTEGER(RETURN-VALUE) < 2 then NEXT.

    if not found then
    do:
      found = yes.

      i = i + 1.
      create ContextMenu.
      assign
        ContextMenu.ItemId = i
        ContextMenu.ItemKey = ""
        ContextMenu.ItemName = Entry (l, "Создать новый связанный...,Create new related...").
      upitem = i.
    end.

    i = i + 1.
    create ContextMenu.
    assign
      ContextMenu.ItemId = i
      ContextMenu.ItemKey = "NewRelDoc".
      ContextMenu.ItemName = STRING( system.typedoc.id-typedoc ) + " " + system.typedoc.name-typedoc.
      ContextMenu.UpItem = upitem.
      ContextMenu.AppParam = STRING(system.typedoc.rid-typedoc).
  end.
end.

if docright = 0 then return.

i = i + 1.
create ContextMenu.
assign
  ContextMenu.ItemId = i
  ContextMenu.ItemKey = ""
  ContextMenu.ItemName = ENTRY(l, "Учетная информация...,Accounting information").
  upitem = i.
found = false.
if can-find (first system.operat where system.operat.rid-document = RidDoc) then
do:
  if not found then found = yes.
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewOperat"
    ContextMenu.ItemName = ENTRY(l, "Бухгалтерские проводки,Accounting records")
    ContextMenu.UpItem = upitem.
end.
if can-find (first system.wh-operat where system.wh-operat.rid-document = RidDoc) then
do:
  if not found then found = yes.
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewWhOperat"
    ContextMenu.ItemName = ENTRY(l,"Складские проводки,Warehouse records")
    ContextMenu.UpItem = upitem.
end.
if can-find (first system.plan-wh-operat where system.plan-wh-operat.rid-document = RidDoc) then
do:
  if not found then found = yes.
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewPlanWhOperat"
    ContextMenu.ItemName = ENTRY(l, "Плановые складские проводки,Warehouse plan records")
    ContextMenu.UpItem = upitem.
end.
if can-find (first system.mr-operat where system.mr-operat.rid-document = RidDoc) then
do:
  if not found then found = yes.
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewMrOperat"
    ContextMenu.ItemName = ENTRY(l, "Управленческие проводки,Management records")
    ContextMenu.UpItem = upitem.
end.
if can-find (first system.doc-relation where system.doc-relation.rid-document = RidDoc) then
do:
  if not found then found = yes.
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewRelation"
    ContextMenu.ItemName = ENTRY(l, "Связи между документами,Document relation records")
    ContextMenu.UpItem = upitem.
end.
else do:
  if can-find (first system.doc-relation where system.doc-relation.ref-document = RidDoc) then
  do:
    if not found then found = yes.
    i = i + 1.
    create ContextMenu.
    assign
      ContextMenu.ItemId = i
      ContextMenu.ItemKey = "ViewRelation"
      ContextMenu.ItemName = ENTRY(l, "Связи между документами,Document relation records")
      ContextMenu.UpItem = upitem.
  end.
end.
if can-find (first system.wage where system.wage.rid-document = RidDoc) then
do:
  if not found then found = yes.
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewWage"
    ContextMenu.ItemName = ENTRY(l, "Начисления/удержания зарплаты,Wage records")
    ContextMenu.UpItem = upitem.
end.
if can-find (first system.reserv where system.reserv.rid-document = RidDoc) then
do:
  if not found then found = yes.
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewReserv"
    ContextMenu.ItemName = ENTRY(l, "Резерв товара,Reserve records")
    ContextMenu.UpItem = upitem.
end.
if can-find (first system.doc-param-val where system.doc-param-val.rid-document = RidDoc) then
do:
  if not found then found = yes.
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewParam"
    ContextMenu.ItemName = ENTRY(l,"Дополнительные параметры,Document parameters")
    ContextMenu.UpItem = upitem.
end.

if found = false then delete ContextMenu.

found = false.
found2 = false.
for each system.document where system.document.rid-document = RidDoc NO-LOCK,
    each system.file-list of system.document NO-LOCK,
    each system.doc-files of system.file-list NO-LOCK
    by system.doc-files.number:

  found2 = true.
  if not found then
  do:
    found = yes.

    i = i + 1.
    create ContextMenu.
    assign
      ContextMenu.ItemId = i
      ContextMenu.ItemKey = ""
      ContextMenu.ItemName = ENTRY(l, "Прикрепленные файлы...,Attached files...").
    upitem = i.
  end.
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewFile".
    ContextMenu.ItemName = system.doc-files.filename.
    ContextMenu.UpItem = upitem.
    ContextMenu.AppParam = STRING(system.doc-files.rid-doc-files).
end.
if docright >= 2 and not ViewOnly and found = false then
do:
  found = yes.

  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = ""
    ContextMenu.ItemName = ENTRY(l, "Прикрепленные файлы...,Attached files...").
  upitem = i.
end.
if docright >= 2 and not ViewOnly then
do:
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "AddFile".
    ContextMenu.ItemName = ENTRY(l, "Прикрепить новый файл..., Attach new file...").
    ContextMenu.UpItem = upitem.
  if found2 = true and docright >= 3 then
  do:
    i = i + 1.
    create ContextMenu.
    assign
      ContextMenu.ItemId = i
      ContextMenu.ItemKey = ""
      ContextMenu.ItemName = ENTRY(l, "Удалить прикрепленный файл...,Delete file...")
      ContextMenu.UpItem = upitem.
    upitem2 = i.
    for each system.document where system.document.rid-document = RidDoc NO-LOCK,
        each system.file-list of system.document NO-LOCK,
        each system.doc-files of system.file-list NO-LOCK
        by system.doc-files.number:

      i = i + 1.
      create ContextMenu.
      assign
        ContextMenu.ItemId = i
        ContextMenu.ItemKey = "DeleteFile".
        ContextMenu.ItemName = system.doc-files.filename.
        ContextMenu.UpItem = upitem2.
        ContextMenu.AppParam = STRING(system.doc-files.rid-doc-files).
    end.
  end.
end.

i = i + 1.
create ContextMenu.
assign
  ContextMenu.ItemId = i
  ContextMenu.ItemKey = ""
  ContextMenu.ItemName = ENTRY(l, "Другое...,Other").
upitem = i.
found = false.

i = i + 1.
create ContextMenu.
assign
  ContextMenu.ItemId = i
  ContextMenu.ItemKey = "DocHeader"
  ContextMenu.ItemName = ENTRY(l,"Заголовок документа,Document header")
  ContextMenu.UpItem = upitem.
i = i + 1.
create ContextMenu.
assign
  ContextMenu.ItemId = i
  ContextMenu.ItemKey = "DocHistory"
  ContextMenu.ItemName = ENTRY(l, "История работы с документом,Document history")
  ContextMenu.UpItem = upitem.

run src/system/auditright.p (uid, "read").
if RETURN-VALUE = "YES" then
do:
  i = i + 1.
  create ContextMenu.
  assign
    ContextMenu.ItemId = i
    ContextMenu.ItemKey = "ViewAudit"
    ContextMenu.ItemName = ENTRY(l, "История изменения,Document changes")
    ContextMenu.UpItem = upitem.
end.
