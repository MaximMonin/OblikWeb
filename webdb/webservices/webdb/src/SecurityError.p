/* Copyright (C) Maxim A. Monin 2009-2010 */

define input parameter ContextId as character.

/* ����������� �᫮ �訡�� �஫��� ��⥬� ������᭮�� �� �ᮡ� 
   ����� ������ */

find first webdb.Context where webdb.Context.ContextKey = ContextId NO-ERROR.
if not available webdb.Context then RETURN "".

webdb.Context.SecurityErrors = webdb.Context.SecurityErrors + 1.
