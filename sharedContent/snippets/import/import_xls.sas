/* Import XLS Example */
/* http://www.ats.ucla.edu/stat/sas/faq/xls_files_read_write_proc_import.htm */

filename url url "{baseURL}/auto.xls";
filename xls temp;

data _null_; 
    infile url recfm=f lrecl=1; 
    file xls recfm=f lrecl=1; 
    input x $char1.; put x $char1.; 
run;

proc import out = WORK.auto1 datafile=xls
            dbms=xls replace;
            sheet="auto1"; 
            getnames=yes;
run;

proc print;
run;