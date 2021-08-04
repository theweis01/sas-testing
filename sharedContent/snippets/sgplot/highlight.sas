/* KNOWLEDGE BASE / SAMPLES & SAS NOTES    */
/* http://support.sas.com/kb/42/855.html */
/* Highlight a value on a graph */

/*
  This sample illustrates how to highlight a value on a graph generated with the SGPLOT procedure.
*/

data one;
   input X Y Type $;
   datalines;
1 3 A
2 4 A
3 5 A
5 8 A
6 9 B
7 10 A
8 1 A
;
run;

/* Define the symbol markers and the colors of the symbol markers */
proc template;
   define style styles.symbols;
   parent=styles.statistical;
      style graphdata1 /
          markersymbol='circlefilled'
          contrastcolor=green;
      style graphdata2 /
          markersymbol='circlefilled'
          contrastcolor=red;
   end;
run;

/* Point to the new style using the STYLE= option on the ODS HTML statement */
ods html5(id=web) style=styles.symbols;

proc sgplot data=one;
   title 'Highlight a Value on a Graph';
   series x=X y=Y;
   scatter x=X y=Y / group=Type;
run;

