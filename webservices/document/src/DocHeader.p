/* Copyright (C) Maxim A. Monin 2009-2010 */

define temp-table DocHeader NO-UNDO
  field Typedoc as character
  field GroupDoc as character
  field DateDoc as date
  field IdDoc as integer
  field RidDoc as integer
  field CreationTime as datetime-tz
  field CreatedBy as character
  field SavedBy as character
  field Ent as character
  field Divis as character
  field Application as character
  field Workcenter as character
  field Sum as decimal
  field Currency as character
  field DocCommitted as logical
  field RO as logical
  field NeedCalc as logical
  field Filled as logical
  field ExecFlag as logical
  field Error as logical
  field AuditEnabled as logical
  field DocStatus as character
  field Description as character
  field BlockedBy as character
  index i0 IdDoc asc.

define temp-table AttachedFiles NO-UNDO
  field FileNumber as integer
  field FileName as character
  field FileSize as integer
  field FileDate as date
  field AddedBy as character
  field FileDescr as character
  index i0 FileNumber asc.

define input-output parameter ContextId as character.
define input parameter RidDoc as integer.
define output parameter table for DocHeader.
define output parameter table for AttachedFiles.

FUNCTION RecordShareLockedBy RETURNS CHARACTER  
(INPUT ipRecID AS RECID, OUTPUT opLockType AS CHAR):

 DEF VAR iLoop  AS INTEGER NO-UNDO.  
 DEF VAR iRecID AS INTEGER NO-UNDO. 

 iRecID = INTEGER(ipRecID). 

 FOR EACH system._UserLock NO-LOCK WHERE _UserLock-Name <> ?:   
   DO iLoop = 1 TO 512:     
     IF _UserLock-Recid[iLoop] = iRecID AND _UserLock-Flags[iLoop] <> ? THEN 
     DO:   
       FIND FIRST system._Connect WHERE _Connect-Usr = _UserLock-Usr NO-LOCK. 
       opLockType = _UserLock-Flags[iLoop].
       RETURN _Connect-Name.       
     END.    
  END.  
 END.    
 RETURN ''.
END FUNCTION.

create DocHeader.  

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

run src/kernel/docright.p ( RidDoc ).
if INTEGER(RETURN-VALUE) < 1 then RETURN.

for first document where document.rid-document = RidDoc NO-LOCK,
    first typedoc of document NO-LOCK:
  
  assign
  DocHeader.Typedoc = STRING(typedoc.id-typedoc) + " " + typedoc.name-typedoc
  DocHeader.DateDoc = document.date-doc
  DocHeader.IdDoc = document.id-document
  DocHeader.RidDoc = document.rid-document
  DocHeader.CreationTime = document.CreationTime
  DocHeader.Sum = document.sum-doc
  DocHeader.DocCommitted = not document.put-off
  DocHeader.RO = document.keep-doc
  DocHeader.NeedCalc = document.NeedToCalc
  DocHeader.Filled = document.filled
  DocHeader.ExecFlag = document.exect
  DocHeader.Error = document.error
  DocHeader.AuditEnabled = document.AuditEnabled
  DocHeader.Description = document.descr-opr.

  find first groupdoc of typedoc NO-LOCK NO-ERROR.
  if available groupdoc then
    DocHeader.GroupDoc = groupdoc.name-groupdoc.

  FIND FIRST users WHERE users.rid-user = document.rid-user NO-LOCK NO-ERROR.
  IF available users then
    DocHeader.CreatedBy = users.name.
  FIND FIRST users WHERE users.rid-user = document.close-doc NO-LOCK NO-ERROR.
  IF available users then
  do:
    DocHeader.SavedBy = users.name.
    Find First cathg WHERE cathg.rid-cathg = document.rid-cathg NO-LOCK NO-ERROR.
    IF AVAILABLE cathg then 
      DocHeader.SavedBy + ", " + system.cathg.name.
  end.

  define variable lockname as character.
  define variable locktype as character.
  lockname = RecordshareLockedBy( RECID(document), OUTPUT locktype).

  FIND FIRST users WHERE users.sys-name = lockname NO-LOCK NO-ERROR.
  IF available users THEN 
  DO:
    FIND FIRST employeers OF users NO-LOCK NO-ERROR.
    IF AVAILABLE employeers THEN
       DocHeader.BlockedBy = employeers.name-emp + " " + locktype.
     ELSE
       DocHeader.BlockedBy = lockname + " " + locktype.
  END.
  else do:
    if locktype <> "" then
      DocHeader.BlockedBy = "Web".
  end.

  Find First ctg-division WHERE ctg-division.rid-division = document.rid-division NO-LOCK NO-ERROR.
  IF AVAILABLE ctg-division then
    DocHeader.Divis = ctg-division.code-division + " " + ctg-division.name-division.
  find first ent where ent.rid-ent = document.rid-ent NO-LOCK NO-ERROR.
  if available ent then
    DocHeader.Ent = ent.name-ent.

  FIND FIRST filials WHERE filials.rid-filials = document.rid-filials NO-LOCK NO-ERROR.
  IF available filials then
    DocHeader.WorkCenter = STRING(filials.id-filials) + " " + filials.name-filial.
  find first applicat OF document NO-LOCK NO-ERROR.
  if available applicat then
    DocHeader.Application = applicat.name.

  FIND FIRST currency WHERE currency.rid-currency = document.rid-currency NO-LOCK NO-ERROR.
  IF available currency then
    DocHeader.Currency = currency.name-currency.
  find FIRST doc-confirm-status of document NO-LOCK NO-ERROR.
  if available doc-confirm-status then
  do:
    run src/kernel/docstat.p (RidDoc, TODAY).
    DocHeader.DocStatus = RETURN-VALUE.
  end.
END.

for each system.document where system.document.rid-document = RidDoc NO-LOCK,
    each system.file-list of system.document NO-LOCK,
    each system.doc-files of system.file-list NO-LOCK
    by system.doc-files.number:

  create AttachedFiles.
  assign
    AttachedFiles.FileNumber = system.doc-files.number
    AttachedFiles.FileName = system.doc-files.filename
    AttachedFiles.FileSize = system.doc-files.filesize
    AttachedFiles.FileDate = system.doc-files.filedate
    AttachedFiles.FileDescr = system.doc-files.descr.

  find first system.users of system.doc-files NO-LOCK NO-ERROR.
  if available system.users then
    AttachedFiles.AddedBy = system.users.sys-name + " " + system.users.name.
end.
