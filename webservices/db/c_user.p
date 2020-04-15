/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR CREATE OF webdb.WebUsers.
  webdb.WebUsers.RidUser = NEXT-VALUE (web-seq).
