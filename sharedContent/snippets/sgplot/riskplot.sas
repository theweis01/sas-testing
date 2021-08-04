/* KNOWLEDGE BASE / SAMPLES & SAS NOTES    */
/* http://support.sas.com/kb/31/509.html   */
/* Create a risk map */

/* This sample uses the BAND statement in PROC SGPLOT to create a risk map. */

/* Create sample data */
data work.bp;
   infile datalines;
   input dias losys hisys grp $ 13-33 refx refy;
datalines;
75  110 190 Severe Hypertension   75 140
115 110 190 Severe Hypertension   90 140
75  110 180 Moderate Hypertension 90 190
110 110 180 Moderate Hypertension . .
75  110 160 Mild Hypertension     . .
100 110 160 Mild Hypertension     . .
75  110 140 High/Normal           . .
90  110 140 High/Normal           . . 
75  110 130 Normal                . .
85  110 130 Normal                . .
75  110 120 Optimal               . . 
80  110 120 Optimal               . .
;
run;

/* Use PROC TEMPLATE to define the gradient colors to be
   used for the bands in the graph */
proc template;
   define style styles.bp;
   parent=styles.listing;
   style graphcolors from graphcolors /
     'gdata6'=CXFFFFFF
     'gdata5'=CXF5D9D8
     'gdata4'=CXEBB3B1
     'gdata3'=CXE18D8A
     'gdata2'=CXD76763
     'gdata1'=CXBF1810;
   end;
run;

/* Use the STYLE created in PROC TEMPLATE */
ods html5(id=web) style=bp;
title 'Stages of Hypertension';

/* Use the BAND statement to create the bands
   in the plot with an overlaid line from the 
   SERIES statement */
proc sgplot data=bp;
   band x=dias lower=losys upper=hisys / 
        group=grp name="bp";
   series x=refx y=refy / lineattrs=(thickness=2);
   xaxis values=(75 to 115 by 5) label='Diastolic Pressure (mmHg)';
   yaxis values=(110 to 190 by 10) label='Systolic Pressure (mmHg)';
   keylegend "bp" / position=right across=1 title='Stage';
   inset "Isolated" "Systolic" "Hypertension" / position=left textattrs=graphlabeltext;
run;