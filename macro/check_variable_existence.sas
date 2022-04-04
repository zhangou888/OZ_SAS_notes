/** check data/variable existence example **/

* 1. use drop statement;
data test (drop=SEX gender Age height weight score);
  if 0 then set sashelp.class;
  stop;
run;

/* 2. Data step example */
data test;
 input fruit $ count;
 datalines;
apple 12
banana 4
coconut 5
date 7
eggs 9
fig 5
;
run;

data _null_;
 dsid=open('test');
 check=varnum(dsid,'count');
 if check=0 then put 'Variable does not exist';
 else put 'Variable is located in column ' check +(_1) '.';
run;

/* 3. Macro-based approach via SYSFUNC VARNUM*/
%let dsid = %sysfunc(open(work.dataset));
%if %sysfunc(varnum(&dsid, x)) > 0 %then %put NOTE: Variable x exists!; 
%* Close the dataset (important!);
%let rc = %sysfunc(close(&dsid));

/*4. Dictionary tables in PROC SQL */
proc sql;
    select name
    from dictionary.columns
    where libname = 'WORK' and
        memtype = 'DATA' and
        memname = 'SOMEDATASET' and
        upcase(name) = 'X';
quit;

/* 5.SASHELP.VCOLUMN */
data _null_;
    set sashelp.vcolumn;
    where libname = 'WORK' and memtype = 'DATA' and memname = 'SOMEDATASET';
    if upcase(name) = 'X' then put 'NOTE: Variable x exists!';
run;


/* 6.  SAS MACROS */
%macro varexist(ds,   /* Data set name */
                var); /* Variable name */

/*Usage Notes:

%if %varexist(&data,NAME)
  %then %put input data set contains variable NAME;
The macro calls resolves to 0 when either the data set does not exist
or the variable is not in the specified data set*/

%local dsid rc;

/* Use SYSFUNC to execute OPEN, VARNUM, and CLOSE functions. */

%let dsid = %sysfunc(open(&ds));

%if (&dsid) %then %do;
  %if %sysfunc(varnum(&dsid,&var)) %then 1;
  %else 0;
  %let rc = %sysfunc(close(&dsid));
%end;
%else 0;

%mend varexist;

/* 7. Ron's example 
   7a. use SQL to return a list of the variable in a data set into a macro variable:
http://www.sascommunity.org/wiki/Making_Lists*/
%let Libname = sashelp;
%let Memname = class;

proc sql;
   select Name
   into :Varlist separated by ' '
   from  Dictionary.Columns
   where  Libname eq "%upcase(&Libname.)"
     and  Memname eq "%upcase(&Memname.)"
     and  MemType eq 'DATA';
   quit;
%Put Varlist: &VarList.;

*7b. then use the index function to check for a name in the list;
%let indexSex = %index(&VarList,Sex);
%let existSex = %sysfunc(ifc(%index(&VarList,Sex)
     ,%nrstr(1)
     ,%nrstr(0)
     ));
%Let Var = Gender;
%let exist&Var = %sysfunc(ifc(%index(&VarList,&Var)
     ,%nrstr(1)
     ,%nrstr(0)
     ));
%put _user_;

/*NOTE: sashelp.class var names are in Propcase.==Initial Caps
to ensure that this trick works
be sure to standardize the case to either lowcase or upcase
Personally I prefer lowcase. */

/* 8. IFC function example */
%let dsn=sashelp.class;
%let var1=sex;
%let var2=abc;
data _null_;
   dsid=open("&dsn");
   n=ifc(varnum(dsid,"&var1"),"&var1",' ');
   m=ifc(varnum(dsid,"&var2"),"&var2",' ');
   call symputx('vv',n);
   call symputx('ww',m);
run;
%put &vv &ww;
proc print data=sashelp.class;
var age &vv &ww;
run;

/* 9. Ksharp example */
Data test1;
input id score1 score2 score3 score4 score5 score6;
cards;
24 100 97 99 100 85 85
28 98 87 98 100 44 90
run;

%macro check(libname= ,tname= ,vars=);
	data have;
	 list="&vars";
	 do i=1 to countw(list);
	  var=scan(list,i);output;
	 end;
	 keep var;
	run;

	proc sql noprint;
	create table a as
	 select upcase(var) as var from have
	 except
	 select upcase(name) from dictionary.columns where libname="%upcase(&libname)" and memname="%upcase(&tname)";

	create table b as
	 select upcase(name) as var from dictionary.columns where libname="%upcase(&libname)" and memname="%upcase(&tname)"
	 except
	 select upcase(var) from have ;

	select count(*) into : a from a;
	select count(*) into : b from b;

	select var into : alist separated by ' ' from a;
	select var into : blist separated by ' ' from b;

	quit;

	%if &a eq 0 %then %put WARNING: All the variable is included. ;
	 %else      %put WARNING: &alist variables are not included. ;

	%if &b eq 0 %then %put WARNING: there are not extra variables. ;
	 %else      %put WARNING: &blist variables are extra variables. ;
%mend check;

%check(libname=work ,tname=test1 ,vars= id score1 score2 score3 score4);

/* 10. Loko example */
%let var1 = Age;
%let var2 = Sex;
%let var3 = blabla;

/*determines variable of database*/
proc sql;
	create table varb as select name from sashelp.vcolumn
	where memname='CLASS';
quit;

/*write the variables to search for in a database*/
%macro a;
	%let k=1;
	data tosearch;
		length vartosearch $ 20;
		%do %while (%symexist(var&k));
			vartosearch="&&var&k";
			output;
			%let k=%eval(&k+1);
		%end;
	run;
%mend a;
%a
/*determines the 2 wanted databases*/
proc sql;
	create table check_var_problem2 as
	select name from varb
	except 
	select vartosearch from tosearch;
	create table check_var_problem1 as
	select vartosearch from tosearch
	except 
	select name from varb;
quit;

/* 11. Art example */
data test1;
  input id score1 x score3 y score5 score6;
  cards;
24 100 97 99 100 85 85
28 98 87 98 100 44 90
run;
%macro check(filenm,vars);
  data check (drop=&vars.);
    set &filenm. (obs=1);
    _error_=0;
  run;
  proc sql noprint;
    select name
      into :vnames separated by " "
         from dictionary.columns
           where libname="WORK" and
                 memname="CHECK"
     ;
  quit;
  %let nvar=&sqlobs.;
  %if nvar=0 %then %put "There were no extra variables";
  %else %then %put "Unexpected vars in file: &vnames.";
%mend check;
%check(test1,id score1 score2 score3 score4)


data check (drop=id score1 score2 score3 score4);
    set test1 (obs=1);
    _error_=0;
  run;
  proc sql noprint;
    select name
      into :vnames separated by " "
         from dictionary.columns
           where libname="WORK" and
                 memname="CHECK"
     ;
  quit;
  %put &vnames;

  %let nvar=&sqlobs.;

  %put &nvar;


  %let vars= id x y z;
	data have;
	 list="&vars";
	 do i=1 to countw(list);
	  var=scan(list,i);output;
	 end;drop i;
	 keep var;
	run;

	*in the variable list but not in the data ;
	proc sql noprint;
	create table a as
	 select upcase(var) as var from have
	 except
	 select upcase(name) from dictionary.columns where libname="%upcase(work)" and memname="%upcase(test1)";

	*in the data but not in variable list;
	create table b as
	 select upcase(name) as var from dictionary.columns where libname="%upcase(work)" and memname="%upcase(test1)"
	 except
	 select upcase(var) from have ;

	select count(*) into : a from a;
	select count(*) into : b from b;

	select var into : alist separated by ' ' from a;
	select var into : blist separated by ' ' from b;

	quit;

	%put &alist &blist;

	%if &a eq 0 %then %put WARNING: All the variable from the variable list is included.;
	 %else      %put WARNING: &alist variables are not included. ;

	%if &b eq 0 %then %put WARNING: there are not extra variables. ;
	 %else      %put WARNING: &blist variables are extra variables. ;

/* Check required variable existence */
%macro var_exist(libname= ,tname= ,vars=);
	data _var;
		list="&vars";
	 	do i=1 to countw(list);
	  		var=scan(list,i);output;
	 	end;drop i;
	 	keep var;
	run;

    /* variable not included in the data */
	proc sql noprint;
	create table a as
		select upcase(var) as var from _var
	 	except
		select upcase(name) from dictionary.columns where libname="%upcase(&libname)" and memname="%upcase(&tname)";

	/* data has some variables not included in the variable list*/
	create table b as
		select upcase(name) as var from dictionary.columns where libname="%upcase(&libname)" and memname="%upcase(&tname)"
	 	except
	 	select upcase(var) from _var ;

	select count(*) into : a from a;
	select count(*) into : b from b;

	select var into : alist separated by ' ' from a;
	select var into : blist separated by ' ' from b;

	quit;

	%if &a eq 0 %then %put NOTES: All the variable from the variable list is included. ;
	 	%else   %put WARNING: &alist variables from the variable list are not included in the data.;
		%goto exit;

	%if &b eq 0 %then %put NOTES: there are not extra variables. in the data;
	 	%else   %put WARNING: &blist variables are extra variables. from variable list;
%mend var_exist;

%var_exist(libname=work ,tname=test1 ,vars= id score1 score2 score3 score4);