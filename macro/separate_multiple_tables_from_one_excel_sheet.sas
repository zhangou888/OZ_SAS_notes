/* Macro 1: Convert character variable to numeric */
%macro char_nu_convert(dat,vlist);

    /* Add '' and , for the &vlist */
    %let vlst=%nrbquote(')%qsysfunc(prxchange(s/\s+/%nrbquote(',')/oi,-1,&vlist))%nrbquote(');

    /* Vlist list all variables keep character feature */
    proc contents data=&dat out=vars(keep=name type) noprint;run;                                                     
    data vars;                                                
       set vars;                                                 
       if type=2 and name not in (&vlst);                               
       newname=trim(left(name))||"_n"; 
    run;     

    proc sql noprint;                                         
       select trim(left(name)), trim(left(newname)),             
              trim(left(newname))||'='||trim(left(name))         
              into :c_list separated by ' ', :n_list separated by ' ',  
              :renam_list separated by ' '                         
              from vars;                                                
    quit;      

    data &dat;                                               
       set &dat;                                                 
       array ch(*) $ &c_list;                                    
       array nu(*) &n_list;                                      
       do i = 1 to dim(ch);                                      
          nu(i) = 1*ch(i);                                  
       end;                                                      
       drop i &c_list;                                           
       rename &renam_list;                                                                                      
    run;   
   
    proc datasets lib=work;delete vars;run;quit;
 
%mend char_nu_convert; 


/* Example */
data test;                                                
   input id $ b c $ d e $ f;                                 
   datalines;                                                
AAA 50 11 1 222 22                                        
BBB 35 12 2 250 25                                        
CCC 75 13 3 990 99                                        
; 
run;

%let v1 = id c;
%char_nu_convert(test,&v1)


/*** Macro 2: Output different table 
     This macro deal with multiple tables existing 
     in the same excel sheet. tables should share same header 
     and line-up in the same column patterns ****/
%macro sep_tbl(key1, firstobs, out, word, vlist);

    /* Key1-Excel sheet tab name
       firstobs-row number in excel as first obs
       Out - output data
       word - the first word shown in the table header 
       vlist - variable list for final output */

    %let dat = key1;

    /* Read-in data from excel */
    proc import out= &dat
        datafile = "&data_dir.\&filename..xlsx"
        dbms = xlsx replace;
        sheet = "&key1";
        getnames = no;
        datarow = &firstobs;  /* first */
    run;quit;

    /* remove blank row */
    data &dat; 
        set &dat;
        if missing(cats(of _all_)) then delete; 
    run;

    /** remove last row (last row is a text message) 
        For NBPTS - Always remove last row (text) **/
    proc sql noprint;
        select count(*) into: maxrow from &dat;
    quit;
    
    data &dat;set &dat;
        head = _n_;
        if head=%eval(&maxrow) then delete;
    run;
    /* End of remove last row */

    /* Add max row number to tail for later PROC SQL */
    proc sql noprint;
        select count(*) into: maxrow from &dat;
    quit;

    data last;;
        tail = %eval(&maxrow);
    run;

    data head(keep=head);set &dat;
        if A = "&word";   
    run;

    data tail(keep=tail);set head;
        tail=head-1;
        if tail > 1;
    run;

    /* Add last number into the tail data */
    data tail;set tail last;run;

    /* Obtain Total number of tables, start table and end table  */
    proc sql noprint;
        select count(*) into: Ntable from head;              /* Number of table */
        select head into: rowst separated by " " from head;  /* Starting row for each table */
        select tail into: rowed separated by " " from tail;  /* Ending row for each table */
    quit;

    proc datasets lib=work;delete last tail head;run;quit;
    /*---------------------------------------------------------*/
 
    /* Separate tables */
    data %do i=1 %to &Ntable; tbl&i %end;;
        set &dat;
        %do i=1 %to &Ntable;
            %let st = %scan(&rowst,&i,' ');
            %let ed = %scan(&rowed,&i,' ');
            %put &st &ed;
            if %eval(&st.) <= head <= %eval(&ed.) then do;
                output tbl&i;
            end;
        %end;
    run; 
    
    /* Set up output*/
    data &out;set _null_;run;

    %do j=1 %to &Ntable;

        data tbl&j;set tbl&j(drop=head);run;

        /* drop blank column for each table */
        ods select none;
        ods output nlevels=temp;
        proc freq data=tbl&j nlevels noprint;
            tables _all_;
        run;

        ods select all;
        proc sql noprint;
            select tablevar into : drop separated by ' '
            from temp 
            where NNonMissLevels=0;
        quit;

        data tbl&j;
            set tbl&j(drop=&drop);
        run;

        /*** column names only exist in one row ****/
        %if &key1 = item %then %do;  /* item is the excel tab name */

            /* Use first row value as variable names */
            proc transpose data=tbl&j(obs=1) out=names;
            	var _all_;
            run;

            data names;set names;
                if col1="n" then col1="ncount";
            run;

            data names;set names;
            	col1=tranwrd(trim(compbl(col1))," ","_");
            run;

            proc sql noprint ;
                select catx('=',_name_,col1) 
            	into :rename separated by ' '
            	from names;
            quit;

            /* remove 1st header row */
            data tbl&j(keep=&vlist);
                retain &vlist;
            	set tbl&j(firstobs=2 rename=(&rename));  
                table = &j;
            run;
        %end;

        /* column names only exist in two rows */
        %if &key1 = response %then %do; /* Response is the excel tab name */

            /* Response has 2 rows for colnames */
            proc transpose data=tbl&j(obs=2) out=names;
            	var _all_;
            run;

            data names;set names;
                if col2="n" then col2="ncount";
            run;

            /* replace blank cell with previous row no missing value */
            data names;
                set names;
                retain _col1;
                if not missing(col1) then _col1 = col1;
                else col1=_col1;
                drop _col1;
            run;

            data names;set names;
                /* Row 1 name  */
                if _NAME_ in ("A","B","C","D") then col3 = col1;
                else col3 = cats(col1,"_",col2); /* Row 2 name2 */
            run;

            data names;set names;
            	col3=tranwrd(trim(compbl(col3))," ","_");
            run;

            proc sql noprint ;
                select catx('=',_name_,col3) 
            	into :rename separated by ' '
            	from names
            	;
            quit;

            /* remove 1st-2nd header row */
            data tbl&j(keep=&vlist);
                retain &vlist;
            	set tbl&j(firstobs=3 rename=(&rename));  
                table = &j;
            run;
        %end;

        data &out;set &out tbl&j;run;
        proc datasets lib=work;delete tbl&j names temp;run;quit;
        /****  End rename ****/
    %end;

%mend sep_tbl;
