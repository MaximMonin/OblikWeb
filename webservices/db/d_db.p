/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR DELETE OF webdb.Db.
  if can-find(webdb.Service of webdb.Db) then 
    RETURN ERROR "Уже есть сервисы по этой БД".
