/* KNOWLEDGE BASE / SAMPLES & SAS NOTES    */
/* http://support.sas.com/kb/49/301.html   */
/* Annotate a logarithmic axis with PROC SGPLOT */

/*
The sample code below uses SG Annotation with the SGPLOT procedure to output a logarithmic axis with exponents.
*/
data concentr;
   input ph conc;
   datalines;
1  1E-1
2  1E-2
3  1E-3
4  1E-4
5  1E-5
6  1E-6
7  1E-7
8  1E-8
9  1E-9
10 1E-10
11 1E-11
12 1E-12
13 1E-13
14 1E-14
;
run;

data sganno;
   length label $20 x1space y1space $11 anchor $8;
   retain y1space 'datavalue' x1space 'wallpercent' textcolor 'black'
   width 25;
   set concentr end=last;
   x1=-3;
   y1=conc;
   function='text';
   label=strip('10');
   textsize=12; 
   anchor='right'; 
   output;
   x1=-4;
   label=strip(log10(conc));
   textsize=8;
   anchor='left';
   output;
   if last then do;
      x1=-10;
      y1space='wallpercent';
      y1=50;
      label='Concentration';
      rotate=90;
      textsize=14;
      anchor='center';
      output;
   end;
run;

title 'Annotate Axis Values with Base and Exponent';

proc sgplot data=concentr pad=(left=15%) sganno=sganno;
   scatter y=conc x=ph / markerattrs=(symbol=diamondfilled color=cx800080);
   xaxis type=discrete;
   yaxis type=log logbase=10 logstyle=logexpand display=(novalues nolabel noticks); 
run;
