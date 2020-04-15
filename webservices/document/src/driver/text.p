/* Copyright (C) Maxim A. Monin 2009-2010 */

/* Dbf driver. based on usrc/drivers/winprint.p */

define input parameter in-file as character.
define output parameter text-file as character.
define output parameter local-file as character.
define output parameter OutMessage as character.

def var cols as integer.
def var rows as integer.
def var Orr  as integer.
def var colpar as character.
def var rowpar as character.
def var res as decimal.
def var linecontents as character.
def var margin as integer.
def var orientation as character.
def var bypass as character.

def var compact as character.

DEFINE TEMP-TABLE printtable NO-UNDO
 FIELD f1 as character.

run src/system/gtprpar.p ( "MARGIN" ).
margin = INTEGER (RETURN-VALUE).                

res = round( 13 / 22,4).
res = 0.61.

run src/system/gtprpar.p ( "WIDTH" ).                                         
colpar = RETURN-VALUE.
if colpar <> "AUTO"
then do:
  cols = INTEGER ( RETURN-VALUE ) NO-ERROR.                                    
  if cols < 0 or cols = ? then cols = 0.
end.

run src/system/gtprpar.p ( "ROWS" ).
rowpar = RETURN-VALUE.
if rowpar <> "AUTO"
then do:
  rows = INTEGER ( RETURN-VALUE ) NO-ERROR.
  if rows < 0 or rows = ? then rows = 0. 
end.

run src/system/gtprpar.p ( "ORIENTATION" ).
orientation = RETURN-VALUE.
if orientation = "?" or orientation = "" then
  orientation = "��".

run src/system/gtprpar.p ( "BYPASS-WINDRV" ).                                      
bypass = RETURN-VALUE.      

if bypass = "?" or bypass = ""
then do:
  bypass = "".
end.
else do:
  if bypass <> "��" then bypass = "false".
  else bypass = "true".
end.

def var marg-field as character init "". /*  ����� ���� �஡��� �� ࠧ���� ����㯠 */
def var Page-width as decimal.          /*  ���� �� ��ਧ��⠫� � � */ 
def var Point1 as integer.              /* ������ ���� �।����   */
def var Point as integer.               /* ������ ���� ��筥���  */
def var N-pages as integer init 0.      /* ��᫮ ��࠭��  */

def var Fontt as integer. 
def var N-str as integer.               /*  N  ��ப� � ��࠭�� */
def var N-str-all as integer.               /*  N  ��ப� � ��࠭�� */
def var N-page as integer.

run src/system/hexgraphtowin.p (in-file, 2).

INPUT FROM VALUE ( in-file ). /* ������ ��ப� 䠩�� �� �६����� ⠡���� */
REPEAT :
   IMPORT UNFORMATTED linecontents.
   CREATE printtable.
   printtable.f1 = linecontents.
END.
INPUT CLOSE.

repeat : /* ���� ������ ����� ��ப� */
 FIND LAST printtable NO-ERROR.
 if NOT AVAILABLE printtable then LEAVE.

 if printtable.f1 = "" then delete printtable.
 else leave. 
end.

for LAST printtable :
   if substr(printtable.f1,1,1) = '' then  printtable.f1 = "".        
END.

                       
if cols = 0 then  
for each printtable :
   If length(printtable.f1) > Cols Then Cols = length(printtable.f1).
END.

if margin > 0 then do:
  cols = cols + margin.
  marg-field = fill(" ",margin).
END.

if colpar = "AUTO"
then do:
  if cols < 80 then cols = 80.
end.
if rowpar = "AUTO"
then do:
   if orientation = "��" then rows = cols / 1.25.
   else rows = cols / 2.5.
end.

OUTPUT TO VALUE (in-file).
for each printtable :
  if substr(printtable.f1,1,1) = '' then  N-pages = N-pages + 1.        
  PUT unform marg-field + printtable.f1 chr(13) chr(10).
END.
N-pages = if ( N-pages > 0 )  then N-pages + 1 else N-pages.
OUTPUT close.

DEFINE VARIABLE p_Printed      AS LOGICAL NO-UNDO.

page-width  =  if orientation = '��' then 20.0 else  28.5 .

Point1 = integer(substr(string(( Page-width / 2.54 ) / Cols / res * 72,"99.99"),1,2)).                            
Point = Point1.

if Point1 < 4 then DO:
   if orientation = '��' then Point = 4.
     else do:
       orientation = '��'.
       Page-width  =  if orientation = '��' then 20.0 else  28.5 .
       Point = integer(substr(string(( Page-width / 2.54 ) / Cols / res * 72,"99.99"),1,2)).
       if Point < 4 then Point = 4.
       run src/system/stprpar.p ("ORIENTATION=��" ).
     end.
end.
if Point > 12 then Point = 12.

Fontt = Point + 17. 
/*message  1 " " Cols ">"   Point1 ">"  Point ">"   Fontt  view-as  alert-box.  */

Orr = if (ORIENTATION = '��') Then 0 Else 2.
N-pages = if N-pages =  1 then 0 else  N-pages.

text-file = in-file.
if R-INDEX (in-file, "/") > 0 then
  local-file = SUBSTRING(in-file, R-INDEX (in-file, "/") + 1 ). 
local-file = replace (local-file, ".tmp", ".txt").

return.

