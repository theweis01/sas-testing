/* Import CSV Example */
/* https://support.sas.com/documentation/cdl/en/proc/67916/HTML/default/viewer.htm#n02nz0e7cykqhun14hcppfmd0558.htm */

filename url url "{baseURL}/sample.csv" TERMSTR=LF;

proc import datafile=url
     out=shoes
     dbms=csv
     replace;
     getnames=no;
run;

proc print;
run;
