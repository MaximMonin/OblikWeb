/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR DELETE OF webdb.Service.
  if can-find (webdb.UserService where 
     webdb.UserService.RidService = webdb.Service.RidService) then
    RETURN ERROR "—ервис уже используетс€ пользовател€ми".
