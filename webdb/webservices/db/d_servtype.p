/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR DELETE OF webdb.ServiceType.
  if can-find(webdb.Service of webdb.ServiceType) then 
    RETURN ERROR "Уже есть сервисы этого типа".
