/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR CREATE OF webdb.Service.
  webdb.Service.RidService = NEXT-VALUE (web-seq).
