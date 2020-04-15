/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR DELETE OF webdb.Context.
  for each webdb.ContextData of webdb.Context:
    delete webdb.ContextData.
  end.  
