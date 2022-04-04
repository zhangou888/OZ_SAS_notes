/* Example of nested IFN */
data tmp;
	input id response $ ;
cards;
1 A 
2 B
3 C
4 D
5 99
6 A
;
run;

data tmp;
		set tmp;
		CHOSE_A = ifn(response = "A",1,ifn(response = "99",.,0,.),.);
		CHOSE_B = ifn(response = "B",1,ifn(response = "99",.,0,.),.);
		CHOSE_C = ifn(response = "C",1,ifn(response = "99",.,0,.),.);
		CHOSE_D = ifn(response = "D",1,ifn(response = "99",.,0,.),.);
run;

/*****************************/
/****         EOF         ****/
/*****************************/





