/* KNOWLEDGE BASE / SAMPLES & SAS NOTES    */
/* http://support.sas.com/kb/48/432.html  */
/* Use SG Annotation to rotate axis values in SGPLOT procedure output */

/*
  The sample code on the Full Code tab uses SG Annotation to rotate the 
  X-axis values in output produced by the SGPLOT procedure.
*/

/* Define a style to determine the color for each of the groups. */
proc template;
   define style colors;
   parent=styles.htmlblue;
      style GraphData1 from GraphData1 / ContrastColor=cx0000CC Color=cx0000cc;
      style GraphData2 from GraphData2 / ContrastColor=lip Color=lip;
   end;
run;

/* Reference the style in the ODS destination statement. */
ods html5(id=web) style=colors;

/* Create an annotate data set to place the axis values below 
     the axis with a rotation of 90 degrees. */
data sganno;
   retain function 'text' x1space 'datavalue' y1space 'datapercent' 
          rotate 90 anchor "right" width 30 textweight 'bold';
   length textcolor $20;
   set sashelp.class;
   label=name;
   xc1=name;
   y1=-5;
   /* Make the color for the text the same as the group value. 
      Since "M" is encountered first in the data, GraphData1 is used. */
   if sex="F" then textcolor='GraphData2:color';
   else textcolor='GraphData1:color';
run;

title 'Use Annotate to Rotate Axis Values';

proc sgplot data=sashelp.class sganno=sganno pad=(bottom=15%);
   scatter x=name y=weight / markerattrs=(symbol=squarefilled size=10px) 
                             group=sex;
   xaxis display=(nolabel novalues) offsetmin=0.02 offsetmax=0.02;
   yaxis labelattrs=(weight=bold) valueattrs=(weight=bold);
   keylegend / location=inside valueattrs=(weight=bold);
run;