/****************************************************************************************
Study #:                        
Program Name:                 maxlen.sas  
Purpose:                      Macro to get maximum lengths to merge datsets with variable with varying lengths
Original Author:              Vineet Jain  
Date Initiated:               01-JAN-2014
Responsibility Taken Over by:   
Date Last Modified:           15-APR-2014  
Reason for Modification:      Added Header  
Input data:                     
Output data:                  macro variable maxvlen with the new new lengths
External macro referenced:    
Program Version #:            1.0  
****************************************************************************************/


%macro maxlen(in1,in2,in3,in4,in5);
 ** Macro to get maximum lengths to merge datsets with variable with varying lengths **;


   %let check=%symexist(maxvlen);

   %if &check = 0 %then %do;
      %global maxvlen;
   %end;

   data allcont;
      asdf = 3; if asdf = .;
   run; 

   %do maxi = 1 %to 5;
      %if "&&in&maxi" ne "" %then %do;
         proc contents data=&&in&maxi out=cont noprint;

         data allcont;
            set allcont cont;
            name = upcase(name);
         run;

      %end;
   %end;
 
   proc sort data=allcont;
      by name length;
   run;

   %let maxvlen=;
   data allcont2;
      set allcont;
      by name length;
      retain _len .;
      format maxvlen $1000.;
      retain maxvlen '';
      if first.name then _len = length;
      if last.name and length ne _len;
      if type = 1 then maxvlen = catx(' ',maxvlen,name,compress(length) || '.'); 
      else if type = 2 then maxvlen = catx(' ',maxvlen,name,'$' || compress(length) || '.');
      call symputx ('maxvlen','length ' || trim(left(maxvlen)) || ';' || 'format ' || trim(left(maxvlen)) || ';' ); 
   run;

   options NOQUOTELENMAX;
   %put "&maxvlen";
   options QUOTELENMAX;

%mend maxlen;

*%maxlen(p__6_1_1(drop=eg:),,,,); 
*;


