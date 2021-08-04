/* KNOWLEDGE BASE / SAMPLES & SAS NOTES    */
/* http://support.sas.com/kb/31/507.html   */
/* Creating a needle plot with PROC SGPLOT */

/* This sample creates a needle plot with overlaid lines
   using the SAS 9.2 SGPLOT procedure. */

/* Define a format to order the horizontal axis and
   the format for the values on the vertical axis. */
proc format;
  value matfmt
    1='1 mo'
    2='3 mo'
    3='6 mo'
    6='1 yr' 
    7='2 yr'
    8='3 yr'
    9='5 yr' 
    11='10 yr ' 
    14='30 yr';
  picture yldfmt 
    low-high='9%';
run;

/* Create sample data. */
data yield;
  input matcur yldcur mat1mo yld1mo mat1yr yld1yr;
  label yldcur='January 2008' yld1mo = 'December 2007' yld1yr = 'January 2007';
  format mat1yr matfmt. mat1mo matfmt. matcur matfmt.
         yldcur yldfmt. yld1mo yldfmt. yld1yr yldfmt.;
datalines;
1   2.63    1   2.76    1   4.97
2   2.86    2   3.04    2   5.12
3   2.86    3   3.37    3   5.16
6   2.69    6   3.31    6   5.07
7   2.36    7   3.19    7   4.89
8   2.39    8   3.2     8   4.8
9   2.86    9   3.53    9   4.75
11  4.3     11  4.6     11  4.94
14  4.28    14  4.55    14  4.85
;
run;

title 'Government Bond Yield Curve';
title2 ' ';


/* Create the graph with the SGPLOT procedure.  Each SERIES statement
   produces a line and the NEEDLE statement produces the needle in the graph. */
proc sgplot data=yield cycleattrs;
  series x=mat1yr y=yld1yr / markers 
    markerattrs=(symbol=circlefilled size=10px) 
    lineattrs=(pattern=solid) name='n1'; 
  series x=mat1mo y=yld1mo / markers 
    markerattrs=(symbol=circlefilled size=10px) 
    lineattrs=(pattern=solid) name='n2';  
  series x=matcur y=yldcur / markers 
    markerattrs=(symbol=circlefilled size=10px) 
    lineattrs=(pattern=solid) name='n3'; 
  needle x=matcur y=yldcur / lineattrs=graphreferenence;
  yaxis grid label='Bond Yield';
  xaxis type=linear values=(1 2 3 6 7 8 9 11 14)  label='Bond Maturity';
  keylegend 'n1' 'n2' 'n3' / position=top noborder;
run;
title;