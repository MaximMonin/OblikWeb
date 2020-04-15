/* Copyright (C) Maxim A. Monin 2009-2010 */

define output parameter db_name as character initial "".
Find First config NO-LOCK NO-ERROR.
IF AVAILABLE config then 
  db_name = config.client-name.
