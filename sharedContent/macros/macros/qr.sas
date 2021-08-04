filename url url "{baseURL}/qr_macros.sas";
%include url;

filename code temp;
data _null_;
	file code;
	put "proc print data=sashelp.fish;run;";
	output;
run;

%generate_qr_code(code,_dataout);

%let _DATAOUT_MIME_TYPE=image/png;
%let _DATAOUT_NAME=qrcode.png;



