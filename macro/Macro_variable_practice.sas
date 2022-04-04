/*-------------- Macro variable practice ----------*/
/* Multiple Ampersand &&&& Challenge */
%put _automatic_;

%let x=a;
%let a=b;
%let b=c;
			  
%put &x;          * [&]x --> a;
%put &&x ;	      * [&&]x --> [&]x --> a;
%put &&&x;	      * [&&][&]x --> [&][a] --> b;
%put &&&&x;		  * [&&][&&]x --> [&][&]x --> [&]x --> a;
%put &&&&&x;	  * [&&][&&][&x] --> [&][&][a] --> [&][a] --> b;
%put &&&&&&x;	  * [&&][&&][&&]x --> [&][&][&]x --> [&&]a --> b;
%put &&&&&&&x;	  * [&&][&&][&&][&]x --> [&][&][&][a] --> [&]b --> c;


/* Example 2 */
options symbolgen;
%LET BOOK = STORY;  **(1)**; 
%LET STORY = FUNNY; **(2)**; 
%LET FUNNY = TWIST; **(3)**; 
%LET TWIST = CLIMAX; **(4)**;
%put &BOOK; 
%put &&&BOOK; 
%put &&&&&&&BOOK; 
%put &&&&&&&&&&&&&&&BOOK;

/*****************************/
/****         EOF         ****/
/*****************************/