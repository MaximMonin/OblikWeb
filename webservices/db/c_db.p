/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR CREATE OF webdb.Db.
  webdb.Db.RidDb = NEXT-VALUE (web-seq).
