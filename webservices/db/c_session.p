/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR CREATE OF webdb.UserSession.
  webdb.UserSession.RidSession = NEXT-VALUE (session-seq).
  webdb.UserSession.StartTime = NOW.
