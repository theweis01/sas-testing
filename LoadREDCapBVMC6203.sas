
	**************************************************************************
	* Date: 2020-10-07, 2021-2-15
	* Author: Ting Sa, modified by Kelly Olano for BVMC6203
	* Study: BVMC6203
	* Investigator: 
	* Program Name: LoadREDCapBVMC6203.sas
	* Program Location:/sasdata/user_home/ting.sa.cchmc/rdcrn-sas-dmcc/BVMC/6203/DMProg/DataLoading/Programs
	* Purpose:  
    *          1. Using the REDCap API to download the labeled values for the access group and REDCap events.
	*          2. Using the REDCap API to download the REDCap data dictionary, use the data dictionary to find the labeled values for the checkbox, dropdownlist and radio button.
	*		   3. Using the REDCap API to download the REDCap raw data either with labels or without labels in JSON format and import the JSON data to a SAS data set and output the whole data to a CSV file
	* Data Sources: 1. REDCap data
	*               2. An excel file that contains your REDCap token. The file is called "REDCapAPIToken.xlsx"
	*                  saved in the folder: /sasdata/user_home/ting.sa.cchmc/REDCapAPIToken
	* Output Created: The following output files are saved in the folder:
	*                 /sasdata/user_home/ting.sa.cchmc/rdcrn-sas-dmcc/BBD/7701/Data/REDCapExport
	*                 1.The "redcapgrpevt_&cnsrt._&prtcl..sas7bdat" file that contains the access group label and redcap event label
	*          		  2.The "redcaprawdata_&cnsrt_&prtcl_.sas7bdat" file which contains all the REDCap data,
	*                    the REDCap data could be either the data with data labels or the data without data
    *                    labels. However, for the data without data labels, all the data will be saved as 
	*                    character format, but you could use input statement in SAS to transform those variables
	*                    back to numeric format;
    *                 3. The "redcaprawdata_&cnsrt._&prtcl..csv" file that contains all the REDCap raw data in CSV format 
	*                 4. The "redcapdicdata_&cnsrt_&prtcl.sas7bdat" file that contains the data dictionary info 
	*				  5. The "redcapcheckbox_&cnsrt_&prtcl.sas7bdat" file that contains the checkbox label value info
	*                 6. The "redcapradiodropdown_&cnsrt._&prtcl.sas7bdat" file that contains the radio button and dropdownlist label value info
	*                 7. The log output file "REDCapAPIExport_&cnsrt_&prtcl..log"
	*                 8. The "REDCapAPIExport_&cnsrt_&prtcl..pdf" contains:
	*                    (1) the summary of the log file, if there are issues in the log,
    *                        it will extract that info and let you know in which batch process
    *                        the issue happens                        
	*                    (2) info about whether each batch data download is successful or not. 
	*                        Check the "batch_status" part, if the "status" column value is "okay",
    *                        it means the download process is successful
	*                    (3) also provides the information about how long it takes to download each
    *                        batch file and parse each batch file
	*************************************************************************;
	* Revision History (For revisions made post-production)
	*
	* Revision 1
	* Who: 
	* Date: 
	* Change Description: 
	*************************************************************************;

	***************************************************************************
	*Setup the running environment;
	**************************************************************************;
	*delete all user defined macro variables;
/* 	%macro delvars; */
/* 	  data vars; */
/* 	    set sashelp.vmacro; */
/* 	  run; */
/*  */
/* 	  data _null_; */
/* 	    set vars; */
/* 	    temp=lag(name); */
/* 	    if scope='GLOBAL' and substr(name,1,3) ne 'SYS' and temp ne name then */
/* 	      call execute('%symdel '||trim(left(name))||';'); */
/* 	  run; */
/* 	%mend; */
/* 	%delvars; */

	options noquotelenmax dlcreatedir /* noxwait noxwait noxsync */ mprint; 
	proc datasets library=work kill nolist;run;quit;
	dm 'log;clear;output;clear;';

	%let staron=;*with '*' on will not print the log to a file;
	%let slashon=;*with '/' on will not print the log to a file;
	options source source2 dlcreatedir;

	***************************************************************************
	Global macro variables
	**************************************************************************;
	*Consortia - put in consorita acronym;
	%let cnsrt = BVMC;
	*Protocol - put in protocol number;
	%let prtcl = 6203;	
	*REDCap database type, if it is a validation database, pass val to the macro,
	if it is production database, pass prod to it;
	%let rcdbtyp=prod;
	*REDCap id variable name;
	%let idvar=recordid;
	*How many number of participant ids to be downloaded in each batch;
	%let recordbatch=50;
	*Download the data values with data labels or not, if with labels, let the value be 1,
	 otherwise set the value be 0.
	 If you put values other than 0 or 1, you will get running errors for the program;
	%let labeldata=0;
	*The SAS studio user name;
	%let username=%scan(%sysfunc(getoption(sasuser)),-1,"/");;
	*Define the study directory;
	%let studydir=/sasdata/user_home/&username.;
	*Create the output directory;
	%let outpath=&studydir./rdcrn-sas-dmcc/&cnsrt./&prtcl./Data/REDCapExport;
	*Create the output library;
	libname outlib "&outpath.";
	*Delete all the files in the output directory;
/* 	x "del /S/Q &outpath./*"; */
	
	options mprint;
	libname dd xlsx "&studydir./REDCapAPIToken/REDCapAPIToken.xlsx";
		data tokeninfo;
			set dd.sheet1;
			where cnsrt="&cnsrt." and prtcl=&prtcl. /*and rcdbtyp="&rcdbtyp."*/;
		run;
	libname dd clear;
	
	*Get the REDCap API token;
	proc sql noprint;
		select token into: mytoken
		from tokeninfo;
	quit;
	

	%macro deleteFile(file);
		/*delete an external file in a folder, the macro is copied from the following link:
	     https://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=9.4_3.5&docsetId=mcrolref&docsetTarget=n108rtvqj4uf7tn13tact6ggb6uf.htm&locale=en */
		%if %sysfunc(fileexist(&file)) ge 1 %then %do;
		   %let rc=%sysfunc(filename(temp,&file));
		   %let rc=%sysfunc(fdelete(&temp));
		%end; 
		%else %put ERROR:The file &file does not exist;
	%mend; 

	%macro downloadREDCap();	
		/*The downloadRecordsByID macro is used to download the REDCap data by REDCap IDs, 
	      batchno will be an automatically number, idno will be the combined REDCap ID numbers*/
		%macro downloadRecordsByID(batchno=,idno=);
			%put "Calling Redcap API to get the data for batch &batchno.";
			/*Collecting the time info so that in case sth. takes longer we could use this time
			  info to identify which process takes longer time*/
			data time1;
				start_time=datetime();
				format start_time datetime21.;
				length comments $200.;			
				comments="start to download the JSON file for batch &batchno.";
			run;
			
			filename para_&batchno. "&outpath./parameters_&batchno..txt";
			filename json_&batchno.  "&outpath./data_&batchno..json";
			filename stat_&batchno. "&outpath./status_&batchno..txt";
			
			%if &labeldata.=1 %then %do;
				data _null_ ;
					file para_&batchno.;
					put %nrbquote(')%NRStr(token=)&mytoken%NRStr(&content=record&rawOrLabel=label&exportDataAccessGroups=true&type=flat&format=json&records=)&idno.%NRStr(&)%nrbquote(');
				run;
			%end;	
			%else %if &labeldata.=0 %then %do;
				data _null_ ;
					file para_&batchno.;
					put %nrbquote(')%NRStr(token=)&mytoken%NRStr(&content=record&exportDataAccessGroups=true&type=flat&format=json&records=)&idno.%NRStr(&)%nrbquote(');
				run;
			%end;

			proc http
				in=para_&batchno. out=json_&batchno. headerout=stat_&batchno.
				url ="https://rc.rarediseasesnetwork.org/api/"
				method="post";
			run;	
			
			/*Import the status file to make sure the download process is successful if the status file 
			 contains 200 OK message*/
			PROC IMPORT OUT=idstat_&batchno. DATAFILE= "&outpath./status_&batchno..txt" DBMS=TAB REPLACE;
		    	GETNAMES=NO;
		     	DATAROW=1; 
				GUESSINGROWS=50000;
			RUN;

			data idstat_&batchno.;
				batchno=&batchno.;
				length &idvar. $500.;
				&idvar.="&idno.";
				set idstat_&batchno.;
				status="not okay";
				if index(VAR1,"HTTP/1.1 200 OK")>0 then status="okay";
				keep batchno &idvar. status;
			run;
			proc sort data=idstat_&batchno.;by batchno &idvar. descending status;run;

			data idstat_&batchno.;
				set idstat_&batchno.;
				if _n_=1;
			run;

			/*Time data set contains all the parsing time info*/
			%if &batchno.=1 %then %do;
				data time;set time1;run;
			%end;
			%else %do;
				data time;set time time1;run;
			%end;	
			proc sql noprint;drop table time1;quit;			
			
		%mend;


		/********************************
		 Get the unique REDCap ID values
		********************************/
		filename id_para "&outpath./id_parameters.txt";
		filename id_json "&outpath./id_data.json";
		filename id_stat "&outpath./id_status.txt";
		
		data _null_ ;
			file id_para;
			put "%NRStr(token=)&mytoken%NRStr(&content=record&rawOrLabel=label&exportDataAccessGroups=true&type=flat&format=json&fields=)&idvar.&";
		run;

		/*First get all the REDCap ID values, the ID values will be saved in the file id_data.csv*/
		proc http
			in=id_para out=id_json headerout=id_stat
			url ="https://rc.rarediseasesnetwork.org/api/"
			method="post";
		run;
		
			
		filename jid "&outpath./id_data.json";
		libname in JSON fileref=jid;
		data ids(compress=yes);set in.root;run;	
		libname in clear;

		/*Import the id_data.csv to the SAS data set ids*/
/* 		PROC IMPORT OUT=WORK.ids DATAFILE= "&outpath./id_data.csv" DBMS=CSV REPLACE; */
/* 		     GETNAMES=YES; */
/* 		     DATAROW=2;  */
/* 			 GUESSINGROWS=50000; */
/* 		RUN; */
		
/* 		data WORK.IDS    ; */
/* 			%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
/* 			infile "&outpath./id_data.csv" delimiter = ',' */
/* 			MISSOVER DSD lrecl=32767 firstobs=2 ; */
/* 			informat recordid $100. ; */
/* 			informat redcap_event_name $200. ; */
/* 			informat redcap_repeat_instrument $200. ; */
/* 			informat redcap_repeat_instance best32. ; */
/* 			informat redcap_data_access_group $200. ; */
/* 			format recordid $100. ; */
/* 			format redcap_event_name $200. ; */
/* 			format redcap_repeat_instrument $200. ; */
/* 			format redcap_repeat_instance best12. ; */
/* 			format redcap_data_access_group $200. ; */
/* 			input */
/* 			   recordid */
/* 			   redcap_event_name  $ */
/* 			   redcap_repeat_instrument  $ */
/* 			   redcap_repeat_instance */
/* 			   redcap_data_access_group  $ */
/* 			; */
/* 			if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
/* 		run; */


		proc sql;
			create table outlib.redcapgrpevt_&cnsrt._&prtcl as
			select distinct &idvar.,redcap_event_name,redcap_data_access_group
			from ids
			order by &idvar.;
		quit; 

		/*Get the distinct REDCap ID values*/
		proc sort data=ids(keep=&idvar.) nodupkey;by &idvar.;run;

		/*Check the status file, the status info is saved in the id_status.txt file*/
		PROC IMPORT OUT= WORK.id_status DATAFILE= "&outpath./id_status.txt" DBMS=TAB REPLACE;
		     GETNAMES=NO;
		     DATAROW=1; 
		RUN;

		/*Make sure we get the 200 OK message which means the API calling is successful*/
		proc sql noprint;
			select count(*) into:sqlcount from id_status
			where index(VAR1,"HTTP/1.1 200 OK")>0;
		quit;
		
		%if &sqlcount. ^=0 %then %do;
			/*Idall data set contains all the unique REDCap IDs*/
			data idall;
				set ids;
			run;

			/*Do the following codings to assign REDCap IDs to a batch*/ 
			data ids;
				set ids;
				batchno=ceil(_n_/(&recordbatch.));
			run;
			proc transpose data=ids out=ids(drop=_name_) prefix=id;by batchno;var &idvar.;run;

			data ids;
				length sascodes $1500.;			
				set ids;
				length all_ids $1000.;
				all_ids=catx(",",of id:);
				all_ids=tranwrd(all_ids,".,","");			
				all_ids=strip(tranwrd(all_ids,".",""));
				if substr(all_ids,length(all_ids),1)="," then all_ids=substr(all_ids,1,length(all_ids)-1);	
				sascodes=cats('%downloadRecordsByID(batchno=',batchno,',idno=%str(',all_ids,'));');
			run;
			
			/*Run the SAS codes to download the REDCap data in batches in JSON format,
	          for each batch, you will get:
			  (1) a JSON file which contains the REDCap data, 
			  (2) a parameter text file to show you how to call the REDCap API 
			  (3) a status text file to show you the status of calling REDCap API*/
			data _null_;
				set ids;
				call execute(sascodes);
			run;

			/*Combine the batch status file together to create a summary status info,
			  the info is saved in the SAS data set batch_status and this data set
			  will be saved in the output libary. Also the SAS data set is exported
			  to an excel file batch_status_&cnsrt._&prtcl..xlsx as well*/
			data all_status;set idstat_:;run;
			proc sort data=all_status;by batchno;run;

			data batch_status;
				merge ids(keep=batchno) all_status;
				by batchno;
			run;

			data chk_downloadstat;
				set batch_status;
				if status ^="okay";
				PUT "ERROR: Not all the Redcap API calls are successful!";
			run;	

			data outlib.batch_status;set batch_status;run;	
			
/* 			Delete the parameter text file */
			%deleteFile(&outpath./id_parameters.txt);
/* 			Delete the json file that contains the ids info */
			%deleteFile(&outpath./id_data.json);
/* 			Delete the id status file */
			%deleteFile(&outpath./id_status.txt);
		%end;
	%mend;

	%macro getREDCapSASData();
		/*The parseJson macro is used to parse the JSON file to the SAS data set*/
		%macro parseJson(batchno=);
			/*Collecting the parsing time info so that in case sth. takes longer we could use this time
			  info to identify which process takes longer time*/
			%put "Parse JSON data and save to the SAS data set for batch &batchno.";
			data time1Parse;
				start_time=datetime();
				format start_time datetime21.;
				length comments $200.;			
				comments="Parse JSON data and save to the SAS data set for batch &batchno.";
			run;
			filename jdata "&outpath./data_&batchno..json";
			libname in JSON fileref=jdata;
			data outlib.data&batchno.(compress=yes);set in.root;run;	
			libname in clear;
			/*TimeParse contains all the parsing time info*/
			%if &batchno.=1 %then %do;
				data timeParse;set time1Parse;run;
			%end;
			%else %do;
				data timeParse;set timeParse time1Parse;run;
			%end;	
			proc sql noprint;drop table time1Parse;quit;
			
			/*Delete the json data file*/
			%deleteFile(&outpath./data_&batchno..json);
			/*Delete the parameter text file*/
			%deleteFile(&outpath./parameters_&batchno..txt);
			/*Delete the status text file*/
			%deleteFile(&outpath./status_&batchno..txt);
		%mend;

		/*parse each JSON file that contains the REDCap data to a SAS data set*/
		data batch_status;
			set outlib.batch_status;
			length sascodes $500.;
			sascodes=cats('%nrstr(%parseJson(batchno=',batchno,'));');
		run;

		data _null_;
			set batch_status;
			call execute(sascodes);
		run;
		
		proc sql;
			/*for each SAS data set that contains the REDCap data, get their variable length*/
			create table allvars as
			select libname,name,type,length,memname,varnum
			from dictionary.columns
			where libname=upcase("outlib") and memtype="DATA" and upcase(memname) like 'DATA%' and lowcase(name) ^="ordinal_root";

			/*find the max length of each REDCap variable*/
			create table allvarlen as
			select name,varnum,max(length) as len
			from allvars
			group by name,varnum
			order by varnum,name;
		quit;

		/*Create the SAS codes to reassign the REDCap variable length,
		  check the sascodes column in the data set allvarlen to see
		  how it works*/
		data allvarlen;
			set allvarlen end=last;
			length sascodes $85.;
			sascodes=catx(" ","length",name,"$",len,";",name,"='';");
			rowno=_N_;
		run;

		%let lengthcodes1="";
		%let lengthcodes2="";
		%let lengthcodes3="";
		%let lengthcodes4="";
		%let lengthcodes5="";
		%let lengthcodes6="";
		%let lengthcodes7="";
		%let lengthcodes8="";
		%let lengthcodes9="";
		%let lengthcodes10="";
		%let lengthcodes11="";
		%let lengthcodes12="";
		%let lengthcodes13="";
		%let lengthcodes14="";
		%let lengthcodes15="";

		/*Save the sascodes to the following four sas macros lengthcodes1,lengthcodes2,lengthcodes3,lengthcodes4*/
		proc sql noprint;
			select cats(sascodes) into :lengthcodes1 separated by " " from allvarlen where rowno<=500;
			select cats(sascodes) into :lengthcodes2 separated by " " from allvarlen where 500<rowno<=1000;
			select cats(sascodes) into :lengthcodes3 separated by " " from allvarlen where 1000<rowno<=1500;
			select cats(sascodes) into :lengthcodes4 separated by " " from allvarlen where 1500<rowno<=2000;
			select cats(sascodes) into :lengthcodes5 separated by " " from allvarlen where 2000<rowno<=2500;
			select cats(sascodes) into :lengthcodes6 separated by " " from allvarlen where 2500<rowno<=3000;
			select cats(sascodes) into :lengthcodes7 separated by " " from allvarlen where 3000<rowno<=3500;
			select cats(sascodes) into :lengthcodes8 separated by " " from allvarlen where 3500<rowno<=4000;
			select cats(sascodes) into :lengthcodes9 separated by " " from allvarlen where 4000<rowno<=4500;
			select cats(sascodes) into :lengthcodes10 separated by " " from allvarlen where 4500<rowno<=5000;
			select cats(sascodes) into :lengthcodes11 separated by " " from allvarlen where 5000<rowno<=5500;
			select cats(sascodes) into :lengthcodes12 separated by " " from allvarlen where 5500<rowno<=6000;
			select cats(sascodes) into :lengthcodes13 separated by " " from allvarlen where 6000<rowno<=6500;
			select cats(sascodes) into :lengthcodes14 separated by " " from allvarlen where 6500<rowno<=7000;
			select cats(sascodes) into :lengthcodes15 separated by " " from allvarlen where 7000<rowno;
		quit;

		%put Combine all the sas data together;
		/*Empdata will be an empty data set that contains the whole structure of the REDCap data,
		  each of its variable will be the maximum variable length among all the batch file*/
		
		data empdata;
			%if %length(&lengthcodes1.) >2 %then %do;
				&lengthcodes1.;
			%end;	
			%if %length(&lengthcodes2.) >2 %then %do;	
				&lengthcodes2.;
			%end;	
			%if %length(&lengthcodes3.) >2 %then %do;	
				&lengthcodes3.;
			%end;	
			%if %length(&lengthcodes4.) >2 %then %do;	
				&lengthcodes4.;
			%end;
			%if %length(&lengthcodes5.) >2 %then %do;
				&lengthcodes5.;
			%end;	
			%if %length(&lengthcodes6.) >2 %then %do;	
				&lengthcodes6.;
			%end;	
			%if %length(&lengthcodes7.) >2 %then %do;	
				&lengthcodes7.;
			%end;	
			%if %length(&lengthcodes8.) >2 %then %do;	
				&lengthcodes8.;
			%end;
			%if %length(&lengthcodes9.) >2 %then %do;	
				&lengthcodes9.;
			%end;	
			%if %length(&lengthcodes10.) >2 %then %do;	
				&lengthcodes10.;
			%end;
			
			%if %length(&lengthcodes11.) >2 %then %do;	
				&lengthcodes11.;
			%end;	
			%if %length(&lengthcodes12.) >2 %then %do;	
				&lengthcodes12.;
			%end;	
			%if %length(&lengthcodes13.) >2 %then %do;	
				&lengthcodes13.;
			%end;
			%if %length(&lengthcodes14.) >2 %then %do;	
				&lengthcodes14.;
			%end;	
			%if %length(&lengthcodes15.) >2 %then %do;	
				&lengthcodes15.;
			%end;
		run;

		/*Combine all the batched SAS data together into the final output SAS data set
		 REDCapData_&cnsrt._&prtcl.*/
		data outlib.redcaprawdata_&cnsrt._&prtcl.(compress=yes);
			set empdata outlib.data:;
			if &idvar.="" then delete;
		run;
	%mend;

	%macro downloadDictionary();
		%put "Download the data dictionary info";
			
		*download the data dictionary info;
		filename para_dic "&outpath./parameters_dic.txt";
		filename json_dic  "&outpath./data_dic.json";
		filename stat_dic "&outpath./status_dic.txt";
		
		data _null_ ;
			file para_dic;
			put "%NRStr(token=)&mytoken%NRStr(&content=metadata&format=json&returnFormat=json)&";
		run;		

		proc http
			in=para_dic out=json_dic headerout=stat_dic
			url ="https://rc.rarediseasesnetwork.org/api/"
			method="post";
		run;	
		
		filename jdata "&outpath./data_dic.json";
		libname in JSON fileref=jdata;
		data outlib.redcapdicdata_&cnsrt._&prtcl.(compress=yes);set in.root;run;	
		libname in clear;
		
				
		/*Delete the parameter text file*/
		%deleteFile(&outpath./parameters_dic.txt);
		/*Delete the json file that contains the dictionary*/
		%deleteFile(&outpath./data_dic.json);
		/*Delete the dictionary download status file*/
		%deleteFile(&outpath./status_dic.txt);
	%mend;

	%macro getCheckboxRadioDropdownLabel();
		%put "Get checkbox, radiobuttion and dropdownlist info";
		
		*get the checkbox coded values and label values;
		data checkboxval;
			set outlib.redcapdicdata_&cnsrt._&prtcl.(keep=field_name select_choices_or_calculations Field_Type);
			if Field_Type="checkbox";
			length var $32. varlabel $500.;
			if index(select_choices_or_calculations,"|")>0  then do;
				do i=1 to countw(select_choices_or_calculations,'|');	
					var=cats(field_name,'___',scan(scan(select_choices_or_calculations,i,"|"),1,","));
					optionval=scan(select_choices_or_calculations,i,"|");			
					varlabel=substr(optionval,index(optionval,",")+1);	
					output;
				end;
			end;
		run;

		*create the SAS codes that could be used by the macros to assign the label values to the coded values;
		data checkboxval;
			length lencodes sascodes $500.;
			set checkboxval;
			lencodes=catx(" ","length",var,"$500.;");
			sascodes=catx(" ","if",var,"='0' then do;",var,"='';end;else if",cats(var,"='1' then do;",var,"='",varlabel,"';end;"));
			drop i optionval;
		run;

		*save the info to a SAS data set, the related SAS codes are saved in the variables lencodes and sascodes;
		data outlib.redcapcheckbox_&cnsrt._&prtcl.(compress=yes);
			set checkboxval;
		run;	

		*get the dropdown/radio coded values and label values; 
		data radiodropdownval;
			set outlib.redcapdicdata_&cnsrt._&prtcl.(keep=field_name select_choices_or_calculations Field_Type);
			if Field_Type in ("radio","dropdown");			
			length var value $32. varlabel $500.;
			if index(select_choices_or_calculations,"|")>0  then do;
				do i=1 to countw(select_choices_or_calculations,'|');	
					var=field_name;
					value=scan(scan(select_choices_or_calculations,i,"|"),1,",");
					optionval=scan(select_choices_or_calculations,i,"|");			
					varlabel=substr(optionval,index(optionval,",")+1);
					output;
				end;
			end;
		run;

		*create the SAS codes that could be used by the macros to assign the label values to the coded values;
		proc sort data=radiodropdownval;by var value;run;

		data radiodropdownval;
			set radiodropdownval;
			by var;
			retain valno 0;
			if first.var then valno=1;
			else valno=valno+1;
		run;

		data radiodropdownval;
			length lencodes sascodes $500.;
			set radiodropdownval;
			lencodes=catx(" ","length",var,"$500.;");
			if valno=1 then do;
				sascodes=catx(" ","if",var,cats("=compress('",value,"')"), "then do;",cats(var,"='",varlabel,"';end;"));
			end;
			else do; 
				sascodes=catx(" ","else if",var,cats("=compress('",value,"')"), "then do;",cats(var,"='",varlabel,"';end;"));
			end;
			drop i optionval;
		run;
		*save the info to a SAS data set, the related SAS codes are saved in the variables lencodes and sascodes;
		data outlib.redcapradiodropdown_&cnsrt._&prtcl.(compress=yes);
			set radiodropdownval;
		run;	
		
		%put "Export the whole REDCap data to an CSV file.";
		
		proc export data=outlib.redcaprawdata_&cnsrt._&prtcl.
			outfile="&outpath./redcaprawdata_&cnsrt._&prtcl..csv"
			dbms=csv
			replace;
		run; 
	%mend;

	&slashon.&staron.
	ods noresults;
	Proc Printto log="&outpath./REDCapAPIExport_&cnsrt._&prtcl..log" new;run; 
	&staron.&slashon.	

	/*Download the REDCap data dictionary and save the info into the SAS data set redcapdicdata_&cnsrt._&prtcl.*/
	%downloadDictionary();

	/*Download the REDCap data in batches and save them into JSON format files
	  Also download the access group and REDCap event label values, this info
	  is saved in the SAS data set redcapgrpevt_&cnsrt._&prtcl*/
	%downloadREDCap();

	/*Parse the dowloaded JSON file to SAS data set and combine those SAS data sets into one final
	  SAS data set that contains all the REDCap data*/
	%getREDCapSASData();

	
	/*create two SAS data sets, one is redcapcheckbox_&cnsrt._&prtcl. that saves the checkbox label info and
	  the other one is the redcapradiodropdown_&cnsrt._&prtcl.. But SAS data sets
	  saves the SAS codes that could be used by the macros to assign the label values*/
	%getCheckboxRadioDropdownLabel();
	
	
	&slashon.&staron.
	Proc Printto;run;
	options source source2;
	ods results;

	*Check the log file and create the summary report 
	  REDCapAPIExport_&cnsrt._&prtcl..pdf;
	filename logfile "&outpath./REDCapAPIExport_&cnsrt._&prtcl..log";
	Data logfile (keep=type message where=(message ne ' '));
		retain noerr 0;
		length line message $200. type $50.;
		infile logfile pad length=len missover end=eof;
		input @1 line $varying200. len;
		if index(line,'Calling Redcap API to get the data for batch')>0 and index(line,"MPRINT")=0 then do;
			message=strip(line);
		end;

		else if index(line,'Parse JSON data and save to the SAS data set for batch')>0 and index(line,"MPRINT")=0 then do;
			message=strip(line);
		end;
		else if index(line,'Combine all the sas data together')>0 and index(line,'%put')=0 then do;
			message=strip(line);
		end;
		else if index(line,'Download the data dictionary info')>0 and index(line,'%put')=0 then do;
			message=strip(line);
		end;
		else if index(line,'Get checkbox, radiobuttion and dropdownlist info')>0 and index(line,"MPRINT")=0 then do;
			message=strip(line);
		end;
		else if index(line,'Export the whole REDCap data to an CSV file')>0 and index(line,"MPRINT")=0 then do;
			message=strip(line);
		end;

		else if index(line,'ERROR')>0 and index(lowcase(line),'set the error detection')=0 and index(upcase(line),upcase('if _ERROR_ then call'))=0 then do;                                         
			type='ERROR';
			noerr+1;
		end;
		else if index(line,'WARNING')>0 then do;
			message=strip(line);
			type='WARNING';
			noerr+1;
		end;
		else if index(lowcase(line),'uninitialized')>0 then do;
			message=strip(line);
			type='UNINITIALIZED';
			noerr+1;
		end;
		else if index(lowcase(line),'invalid') then do;
			message=strip(line);
			type='INVALID';
			noerr+1;
		end;
		else if index(lowcase(line),'repeats of') then do;
			message=strip(line);
			type='MERGE STATEMENT WITH REPEATS OF BY VARIABLES';
			noerr+1;
		end;
		else if index(lowcase(line),'not found or could not be loaded') then do;
			message=strip(line);
			type='FORMAT NOT FOUND';
			noerr+1;
		end;
		if eof then do;
			if noerr=0 then do;
				message='NO MESSAGES OF CONCERN IN LOG';
				type='NONE';
			end;
		end;
	run;

	data logfile;
		length sasprogram $100.;
		sasprogram="LoadREDCap&cnsrt.&prtcl..sas";				
		set logfile;		
	run;
	
	ods listing close;
	ods pdf file="&outpath./REDCapAPIExport_&cnsrt._&prtcl..pdf" contents=yes;
	  	proc print data=logfile noobs;run;
		proc print data=batch_status(drop=sascodes) noobs;run;
		proc print data=time noobs;run;
		proc print data=timeParse noobs;run;
	ods pdf close;
	ods listing;
	ods results;
	
	* Save the log info;
	data outlib.log&cnsrt.&prtcl.LoadREDcap;
		length descrption $100.;
		descrption="&cnsrt.&prtcl. load REDCap program";
		set logfile;
		sortno=1;
		rowno=_n_;
	run;	

	
	proc datasets lib=outlib nolist;delete data:;run;quit;
	proc datasets lib=outlib nolist;delete batch_status;run;quit;


 	&staron.&slashon. ;
	
	/*compare the API downloaded raw data with the manual downloaded validation data
	  to make sure the API works correctly*/
/* 	libname vlib "&studydir./rdcrn-sas-dmcc/&cnsrt./&prtcl./DMProg/DataLoading/Programs"; */
/* 	data compare; */
/* 		set vlib.dsc7904redcapdata; */
/* 		if _n_=1 then delete; */
/* 	run; */
/* 	 */
/* 	proc sort data=compare; */
/* 		by recordid redcap_event_name redcap_repeat_instrument redcap_repeat_instance; */
/* 	run; */
/* 	 */
/* 	data base; */
/* 		set outlib.redcaprawdata_&cnsrt._&prtcl.; */
/* 	run; */
/* 	proc sort data=base; */
/* 		by recordid redcap_event_name redcap_repeat_instrument redcap_repeat_instance; */
/* 	run; */
/* 	 */
/* 	proc compare base=base compare=compare listall error criterion = 0.00001; */
/* 		id recordid redcap_event_name redcap_repeat_instrument redcap_repeat_instance; */
/* 		attrib _all_ label=' '; */
/* 		informat _all_; */
/* 	run; */
/*  */
/* 	 */
