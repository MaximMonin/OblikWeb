/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR CREATE OF webdb.Context.
  webdb.Context.RidContext = NEXT-VALUE (context-seq).
  webdb.Context.NumUsed = 0.
  webdb.Context.ContextKey = ENCODE (STRING(webdb.Context.RidContext) +
    "_" + STRING(webdb.Context.NumUsed)).
  webdb.Context.CreationTime = NOW.
  webdb.Context.UseTime = NOW.
