/* KNOWLEDGE BASE / SAMPLES & SAS NOTES    */
/* http://support.sas.com/kb/49/302.html  */
/* Annotate a line of identity on PROC SGPLOT output */

/*
  The sample code on the Full Code tab uses SG Annotation with the SGPLOT procedure 
  to draw a line of identity on the graph.
*/

 data sample;
   do y=-1.0 to 1 by .25; 
      do x=-1 to 1.5 by .5;
         output;
      end;
   end;
run;

proc sql noprint;
   select min(x), min(y), max(x), max(y) into :minx, :miny, :maxx, :maxy
      from sample;
quit; 

data sganno;
   retain function 'line' drawspace 'datavalue' linecolor 'orange';
   startline=max(&minx, &miny);
   endline=min(&maxx, &maxy);
   x1=startline; y1=startline;
   x2=endline; y2=endline;
   output;
run; 

title 'Annotate Line of Identity';

proc sgplot data=sample sganno=sganno;
  scatter x=x y=y;
run;