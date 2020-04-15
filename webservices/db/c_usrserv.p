/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR CREATE OF webdb.UserService.
  webdb.UserService.RidUserService = NEXT-VALUE(web-seq).
  
