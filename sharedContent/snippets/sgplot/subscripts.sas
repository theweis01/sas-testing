/* KNOWLEDGE BASE / SAMPLES & SAS NOTES    */
/* http://support.sas.com/kb/39/267.html  */
/* Create subscripts and superscripts in PROC SGPLOT output */


data sample;
   do x=1 to 10; 
      y=int(ranuni(0)*100);
      output;
   end;
run;

proc template;                                                                                                                          
   define style unifonts;                                                                                                                
   parent=Styles.Default;   
   style Graphfonts from GraphFonts /                                                                                                                   
      'GraphValueFont' = ("Monotype Sans WT J",12pt)                                                                                             
      'GraphLabelFont' = ("Monotype Sans WT J",14pt)
      'GraphDataFont' = ("Monotype Sans WT J",12pt)
      'GraphTitleFont' = ("Monotype Sans WT J",12pt);                                                                                            
   end;                    
run;  

ods escapechar='^';
ods html5(id=web) style=unifonts;

title 'Using Subscripts and Superscripts';

proc sgplot data=sample;
   scatter x=x y=y / markerattrs=(symbol=circlefilled color=blue);
   xaxis label="H^{unicode '2082'x}O^{unicode '00b2'x}";
   yaxis label="N^{unicode '00b2'x}H^{unicode '2082'x}";
run;
