/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR DELETE OF webdb.UserSession.
  for each webdb.Context of webdb.UserSession:
    delete webdb.Context.
  end.  
