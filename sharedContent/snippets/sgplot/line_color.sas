/* KNOWLEDGE BASE / SAMPLES & SAS NOTES    */
/* http://support.sas.com/kb/35/864.html */
/* Change line colors and styles for PROC SGPLOT output */

/*
This sample illustrates how to use styles and options to change the line color and style 
in output created by PROC SGPLOT. 
*/

proc template;
  define style styles.mystyle;
  parent=styles.default;
    style GraphData1 from GraphData1 /
          contrastcolor=orange linestyle=1;
    style GraphData2 from GraphData2 /
          contrastcolor=purple linestyle=1;
  end;
run;

ods html5(id=web) style=styles.mystyle;

proc sgplot data=sashelp.class;
  reg x=weight y=height / group=sex degree=3;
  reg x=weight y=height / lineattrs=(color=blue pattern=dash) 
                          markerattrs=(color=black symbol=circlefilled);
run;