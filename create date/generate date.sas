data date;
 date1 = intnx('year', date(), -2);
 date2 = intnx('month', today(),-2);
 date3 = intnx('day', today(),-2);
 date4 = intnx('year', today(), 0);
 date5 = intnx('month', date(),0);
 date6 = intnx('day', today(),0);
 date7 = intnx('year', date(), 1);
 date8 = intnx('month', date(),1);
 date9 = intnx('day', date(),1);
 format date1-date9 date9.;
run;
proc print;run;

data _null_;
	call symput('yrmth', 
         put intnx('month',today(),-1),yymmdd4.));run;

/* example 1 */
%let start_date=01Apr1998;
%let end_date=11feb2014;
data want_month;
date="&start_date"d;
do while (date<="&end_date"d);
    output;
    date=intnx('month', date, 1, 's');
end;
format date date9.;
run;

data want_day;
date="&start_date"d;
do while (date<="&end_date"d);
    output;
    date=intnx('day', date, 1, 's');
end;
format date date9.;
run;

/* example 2*/
%let start_date=01Apr1998;
%let end_date=11feb2014;
data want;
do date="&start_date"d to "&end_date"d;
output;
end;
format date date9.;
run;
