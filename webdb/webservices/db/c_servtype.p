/* Copyright (C) Maxim A. Monin 2009-2010 */

TRIGGER PROCEDURE FOR CREATE OF webdb.ServiceType.
  webdb.ServiceType.RidServiceType = NEXT-VALUE(web-seq).
