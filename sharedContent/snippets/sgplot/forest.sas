/* KNOWLEDGE BASE / SAMPLES & SAS NOTES    */
/* http://support.sas.com/kb/42/867.html   */
/* This sample illustrates how to create a forest plot with the SGPLOT procedure. */

data forest;                                                                                                                            
   input Study $1-16 grp OddsRatio LowerCL UpperCL Weight;                                                                              
   format weight percent5. Q1 Q3 4.2 oddsratio lowercl uppercl 5.3;                                                                     
   ObsId=_N_;                                                                                                                           
   OR='OR'; LCL='LCL'; UCL='UCL'; WT='Weight';                                                                                          
   if grp=1 then do;                                                                                                                    
      weight=weight*.05;                                                                                                                
      Q1=OddsRatio-OddsRatio*weight;                                                                                                    
      Q3=OddsRatio+OddsRatio*weight;                                                                                                    
        lcl2=lowercl;                                                                                                                   
      ucl2=uppercl;                                                                                                                     
   end;                                                                                                                                 
   else study2=study;                                                                                                                   
datalines;                                                                                                                              
Modano  (1967)    1  0.590 0.096 3.634  1                                                                                               
Borodan (1981)    1  0.464 0.201 1.074  3.5                                                                                             
Leighton (1972)   1  0.394 0.076 2.055  2                                                                                               
Novak   (1992)    1  0.490 0.088 2.737  2                                                                                               
Stawer  (1998)    1  1.250 0.479 3.261  3                                                                                               
Truark   (2002)   1  0.129 0.027 0.605  2.5                                                                                             
Fayney   (2005)   1  0.313 0.054 1.805  2                                                                                               
Modano  (1969)    1  0.429 0.070 2.620  2                                                                                               
Soloway (2000)    1  0.718 0.237 2.179  3                                                                                               
Adams   (1999)    1  0.143 0.082 0.250  4                                                                                               
Truark2  (2002)   1  0.129 0.027 0.605  2.5                                                                                             
Fayney2  (2005)   1  0.313 0.054 1.805  2                                                                                               
Modano2 (1969)    1  0.429 0.070 2.620  2                                                                                               
Soloway2(2000)    1  0.718 0.237 2.179  3                                                                                               
Adams2   (1999)   1  0.143 0.082 0.250  4                                                                                               
Overall           2  0.328 0.233 0.462  .                                                                                               
;                                                                                                                                       
run;
                                                                                                                                        
proc sort data=forest out=forest2;                                                                                                      
   by descending obsid;                                                                                                                 
run;                                                                                                                                    
                                                                                                                                        
/* Add sequence numbers to each observation */                                                                                       
data forest3;                                                                                                                           
   set forest2 end=last;                                                                                                                
   retain fmtname 'Study' type 'n';                                                                                                     
   studyvalue=_n_;                                                                                                                      
   if study2='Overall' then study2value=1;                                                                                              
   else study2value = .;                                                                                                                
                                                                                                                                        
/* Output values and formatted strings to data set */                                                                                   
   label=study;                                                                                                                         
   start=studyvalue;                                                                                                                    
   end=studyvalue;                                                                                                                      
   output;                                                                                                                              
   if last then do;                                                                                                                     
      hlo='O';                                                                                                                          
      label='Other';                                                                                                                    
   end;                                                                                                                                 
run;                                                                                                                                    
                                                                                                                                        
/* Create the format from the data set */                                                                                                                                                                                                                                      
proc format library=work cntlin=forest3;                                                                                                
run;                                                                                                                                    
                                                                                                                                        
/* Apply the format to the study values and remove Overall from Study column. */                                                        
/* Compute the width of the box proportional to weight in log scale. */                                                                 
data forest4;                                                                                                                           
   format studyvalue study2value study.;                                                                                                
   drop fmtname type label start end hlo pct;                                                                                           
   set forest3 (where=(studyvalue > 0)) nobs=nobs;                                                                                      
   if studyvalue=1 then studyvalue=.;                                                                                                   
   /* Compute marker width */                                                                                                           
   x1=oddsratio / (10 ** (weight/2));                                                                                                   
   x2=oddsratio * (10 ** (weight/2));
                                                                                                   
   /* Compute top and bottom offsets */                                                                                                    
   if _n_ = nobs then do;                                                                                                                  
      pct=0.75/nobs;                                                                                                                        
      call symputx("pct", pct);                                                                                                             
      call symputx("pct2", 2*pct);                                                                                                          
      call symputx("count", nobs);                                                                                                          
   end;                                                                                                                                    
run;                                                                                                                                    
                                                                                                                                                                                                                                                                           
title "Impact of Treatment on Mortality by Study";                                                                                      
title2 h=8pt 'Odds Ratio and 95% CL';                                                                                                   
                                                                                                                                        
proc sgplot data=forest4 noautolegend;                                                                                                  
   scatter y=study2value x=oddsratio / markerattrs=graphdata2(symbol=diamondfilled size=10);                                            
   scatter y=studyvalue x=oddsratio / xerrorupper=ucl2 xerrorlower=lcl2 markerattrs=graphdata1(symbol=squarefilled size=0);             
   vector x=x2 y=studyvalue / xorigin=x1 yorigin=studyvalue lineattrs=graphdata1(thickness=8) noarrowheads;                             
   scatter y=studyvalue x=or / markerchar=oddsratio x2axis;                                                                             
   scatter y=studyvalue x=lcl / markerchar=lowercl x2axis;                                                                              
   scatter y=studyvalue x=ucl / markerchar=uppercl x2axis;                                                                              
   scatter y=studyvalue x=wt / markerchar=weight x2axis;                                                                                
   refline 1 100  / axis=x;                                                                                                             
   refline 0.1 10 / axis=x lineattrs=(pattern=shortdash) transparency=0.5;                                                              
   inset '        Favors Treatment'  / position=bottomleft;                                                                             
   inset 'Favors Placebo'  / position=bottom;                                                                                           
   xaxis type=log offsetmin=0 offsetmax=0.35 min=0.01 max=100 minor display=(nolabel) ;                                                 
   x2axis offsetmin=0.7 display=(noticks nolabel);                                                                                      
   yaxis display=(noticks nolabel) offsetmin=0.1 offsetmax=0.05 values=(1 to &count by 1);                                              
run;                                                                                                                                    
                                                                                                                                        

																																		