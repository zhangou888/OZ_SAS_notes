			   
data test;                                                
input id $ b c $ d e $ f;                                 
datalines;                                                
AAA 50 11 1 222 22                                        
BBB 35 12 2 250 25                                        
CCC 75 13 3 990 99                                        
;                                                         
/*PROC CONTENTS is used to create an output data set called VARS to list all */
/*variable names and their type from the TEST data set.                      */                                                          

proc contents data=test out=vars(keep=name type) noprint; 
 
/*A DATA step is used to subset the VARS data set to keep only the character */
/*variables and exclude the one ID character variable.  A new list of numeric*/ 
/*variable names is created from the character variable name with a "_n"     */
/*appended to the end of each name.                                          */                                                        

data vars;                                                
	set vars;                                                 
	if type=2 and name ne 'id';                               
	newname=trim(left(name))||"_n";  
run;                                                                             

/*The macro system option SYMBOLGEN is set to be able to see what the macro*/
/*variables resolved to in the SAS log.                                    */                                                       

options symbolgen;                                        

/*PROC SQL is used to create three macro variables with the INTO clause.  One  */
/*macro variable named c_list will contain a list of each character variable   */
/*separated by a blank space.  The next macro variable named n_list will       */
/*contain a list of each new numeric variable separated by a blank space.  The */
/*last macro variable named renam_list will contain a list of each new numeric */
/*variable and each character variable separated by an equal sign to be used on*/ 
/*the RENAME statement.                                                        */                                                        

proc sql noprint;                                         
	select trim(left(name)), 
           trim(left(newname)),             
	       trim(left(newname))||'='||trim(left(name))         
	into :c_list separated by ' ', 
         :n_list separated by ' ',  
	     :rename_list separated by ' '                         
	from vars;                                                
quit;    

%put &c_list &n_list &rename_list; 
 
/*The DATA step is used to convert the numeric values to character.  An ARRAY  */
/*statement is used for the list of character variables and another ARRAY for  */
/*the list of numeric variables.  A DO loop is used to process each variable   */
/*to convert the value from character to numeric with the INPUT function.  The */
/*DROP statement is used to prevent the character variables from being written */
/*to the output data set, and the RENAME statement is used to rename the new   */
/*numeric variable names back to the original character variable names.        */                                                        

data test2;                                               
	set test;                                                 
	array ch(*) $ &c_list;                                    
	array nu(*) &n_list;                                      
	do i = 1 to dim(ch);                                      
  	nu(i)=input(ch(i),8.);                                  
end;                                                      
drop i &c_list;                                           
rename &renam_list;                                                                                      
run;        