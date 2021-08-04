/* Have whatever text you want in the first fileref,   
   and reference a PNG file in the second fileref.    
   Use this macro to produce a QR image of the text.    
   You can have up to 4K of text in the input file.
   For example:
        filename mypgm 'mypgm.sas';
        filename myqr 'qr.png';
        %to_qr ( mypgm , myqr );
 */

%macro generate_qr_code(in,out);

/*this data step generates a string of attributes required by the web service.*/
data; infile &in recfm=f lrecl=4096 length=l;
     length url_encoded $8192;
     keep url_encoded;
     input @1 all $varying4096. l;
     url_encoded = 'chs=500x500&cht=qr&chl=' ||
              urlencode(strip(all)) || '&chld=l';
     call symputx('qrtextl',length(url_encoded));
     output; stop;
     run;

filename qrtext temp recfm=f lrecl=&qrtextl; 

/* This data step writes to a text file the input that PROC HTTP will use to call the web service.  */
data _null_; 
    set;
    file qrtext;
     put url_encoded;
     run;

proc delete; run;

/*call the web service*/
proc http in=qrtext out=&out method='post'
     url='https://chart.googleapis.com/chart?'
     ct='application/x-www-form-urlencoded';
     run;
filename qrtext clear;
%mend;