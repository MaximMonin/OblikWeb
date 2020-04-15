/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR CREATE OF webdb.WebModules.
  webdb.WebModules.RidModule = NEXT-VALUE(web-seq).
