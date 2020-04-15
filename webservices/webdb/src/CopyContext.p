/* Copyright (C) Maxim A. Monin 2009-2010 */

define input parameter ContextIdFrom as character.
define input parameter ContextIdTo as character.

define variable RidContext as integer.
define variable RidContextTo as integer.
define variable var-name as character.
define variable var-value as character.

define buffer ContextData2 for webdb.ContextData.

find first webdb.Context where webdb.Context.ContextKey = ContextIdFrom NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.

RidContext = webdb.Context.RidContext.
find first webdb.Context where webdb.Context.ContextKey = ContextIdTo NO-LOCK NO-ERROR.
if not available webdb.Context then RETURN.
RidContextTo = webdb.Context.RidContext.

for each webdb.ContextData where webdb.ContextData.RidContext = RidContext NO-LOCK:
  var-name = webdb.ContextData.ParamName.
  var-value = webdb.ContextData.DataValue.

  find first ContextData2 where ContextData2.RidContext = RidContextTo and
    ContextData2.ParamName = var-name NO-ERROR.
  if not available ContextData2 then
  do:
    create ContextData2.
    assign
      ContextData2.RidContext = RidContextTo
      ContextData2.ParamName = var-name.
  end.
  ContextData2.DataValue = var-value.
end.
