/* Example from - http://support.sas.com/documentation/cdl/en/proc/65145/HTML/default/viewer.htm#n03ji3gyt52p10n1mma27gr6rdxg.htm */

/*** Specify the input file.***/
/*** Identify the output SAS data set.***/
    /*** Specify the input file is a delimited file.***/
/*** Replace the data set if it exists.***/
    /*** Specify delimiter as an & (ampersand).***/
/*** Generate variable names from first row of data.***/

options nodate ps=60 ls=80;

filename url url "{baseURL}/delimiter.txt" TERMSTR=LF;

proc import datafile=url
            dbms=dlm
            out=mydata
            replace;
            delimiter='&';
            getnames=yes;

run;
proc print data=mydata;
run;