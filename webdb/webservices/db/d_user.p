/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR DELETE OF webdb.WebUsers.
  if can-find (webdb.UserSession where 
     webdb.UserSession.RidUser = webdb.WebUsers.RidUser) then
    RETURN ERROR "Есть сессии пользователя".
  for each webdb.UserService of webdb.WebUsers:
    delete webdb.UserService.
  end.  
