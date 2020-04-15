/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR DELETE OF webdb.UserService.
  for each webdb.UserServiceParam of webdb.UserService:
    delete webdb.UserServiceParam.
  end.  
