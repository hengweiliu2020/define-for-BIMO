** read analysis datasets and create metadata; 

%include "C:\BIMO\admacro.sas";

%macro meta(inlib=);
libname inlib "&inlib";

%list_files(path=&inlib);

data _null_; 
set f1 end=eof;
i+1;
call symput(compress('ds'||i), trim(left(names)));
call symput(compress('das'||i), trim(left(scan(names,1,'.'))));
if eof then call symput('tot', trim(left(_n_)));
run;

%do k=1 %to &tot;
ods listing close;
ods output variables=variables&k attributes=attributes&k sortedby=sortedby&k;
proc contents data=inlib.&&das&k;
run;
ods listing;

data variables&k; set variables&k;
dataset=scan(member,2,'.');
rename len=length;

data attributes&k; set attributes&k;
where label1='Label';
label=cvalue1;
dataset=scan(member,2,'.');

data sortedby&k; set sortedby&k;
where label1='Sortedby';
seq=cvalue1;
dataset=scan(member,2,'.');


 data content(keep=dataset label variable type length);
set %if &k=1 %then variables1; %else content variables&k;;

 data attributes(keep=label dataset);
set %if &k=1 %then attributes1; %else attributes attributes&k;;

 data sortedby(keep=seq dataset); length seq $30.;
set %if &k=1 %then sortedby1; %else sortedby sortedby&k;;


run;
%end;

*** assign format variable to categorical variables ***;
*** only do this for variables with <=10 values;

data _null_; 
set content(where=(type='Char')) end=eof;
i+1;
call symput(compress("mem"||i), trim(left(dataset)));
call symput(compress("nam"||i), trim(left(variable)));
call symput(compress("fmt"||i), trim(left(compress(dataset||'_'||variable||'_FMT'))));
if eof then call symput("charvar", trim(left(_n_)));
run;

%do i=1 %to &charvar;
proc sql noprint;
create table count&i as 
select count(distinct &&nam&i) as n 
from inlib.&&mem&i where &&nam&i ne ' ';

data count&i; 
length fmtname $30. dataset variable $8.;
set count&i;
dataset=compress("&&mem&i");
variable=compress("&&nam&i");
fmtname="&&fmt&i";

data count(keep=dataset variable fmtname n);
set %if &i=1 %then %do; count1 %end; %else %do; count count&i %end;;
if 1<n<=10;
run;
%end;


** get the significant digits and dispfmt *** ;

data _null_; 
set content(where=(type='Num')) end=eof;
i+1;
call symput(compress("dataset"||i), trim(left(dataset)));
call symput(compress("variable"||i), trim(left(variable)));
if eof then call symput("numvar", trim(left(_n_)));
run;

%do j=1 %to &numvar;
data temp; 
set inlib.&&dataset&j;
if  int(&&variable&j) ne &&variable&j then do;
%do s=1 %to 5;
r&s=round(&&variable&j, 1/%eval(10**&s));
%end;
end;

proc sql;
create table diff as 
select %do s=1 %to 5; max(abs(&&variable&j-r&s)) as d&s, %end; max(abs(&&variable&j)) as maxval,
"&&dataset&j" as dataset, "&&variable&j" as variable
from temp; 

data _null_; 
set diff;
maxvalc=put(maxval, best.);
w=length(strip(scan(maxvalc,1,'.')))+1;
call symput("w", trim(left(w)));
run;

data a&j;
length dispfmt $10.;
set diff;
if .z<d1<10E-5 then do; sigdigit=1; %let totw=%eval(&w+2); dispfmt="&totw..1"; end;
%do p=2 %to 5;
else if .z<d&p<10E-5 then do; sigdigit=%eval(&p); %let totw=%eval(&w+1+&p); dispfmt="&totw..&p"; end;
%end;

data addit(keep=dataset variable sigdigit dispfmt); 
length dataset variable  $8.;
set %if &j=1 %then a1; %else addit a&j;;
%end;

*** get the key sequence number *** ; 

data keys(keep=dataset variable keyseq); set sortedby;
count_period=countw(seq,' ');
do k=1 to count_period;
variable=scan(seq, k,' ');
keyseq=k;
output;
end;

***Merge the content with addit**;

proc sort data=keys; by dataset variable;
proc sort data=addit; by dataset variable;
proc sort data=content;by dataset variable;
proc sort data=count nodupkey; by dataset variable;

data content chk1 chk2 chk3;
merge content(in=a) addit(in=b)  count(in=d) keys;
by dataset variable;
if a then output content;
if b and not a then output chk1;
if d and not a then output chk3;
run;


*** create DEFDS *** ;
proc sql;
create table defds as
select distinct dataset, label  from attributes;

data defds; set defds;
domain=dataset;
if dataset='ADSL' then repeating='No';
else repeating='Yes';
isref='No';
purpose='Analysis';
struct='ADAM OTHER';
class='One record per siteid, per arm, per cohort';
label=label;
if dataset='ADSL' then order=1;
else order=100+_n_;
comment=' ';
docref1=' ';
run;

proc sort data=defds; by dataset;

data defds; 
retain dataset struct class;
set defds;
keep dataset domain repeating isref purpose struct class label order comment docref1;
run;

*** create defvar *** ;

data defvar; 
length datatype $8.  dispfmt $20.;
set content;

if type='Char' then datatype='text';
else if type='Num' and sigdigit>0 then datatype='float';
else if type='Num' then datatype='integer';

origin='Assigned';
if variable in ('SAFPOP','SCREEN','DISCSTUD','DISCTRT','TRTEFFR','TRTEFFS','NSAE','SAE','DEATH','IMPDEV','NOIMPDEV') then do;
origin='Derived';
methtyp='Computation';
end;

orgdetl=' ';
mandatory='Yes';
role=' ';
order=.;
docref1=' ';
run;


** read the data specifications ** ; 
proc import datafile="C:\BIMO\data_spec" out=dataspec dbms=xlsx replace; 

** merge data spec with defvar ** ; 
proc sort data=defvar; by variable;
proc sort data=dataspec; by variable;

data defvar;
merge defvar dataspec;
by variable;
run;

proc sort data=defvar; by dataset variable;

data defvar; 
retain dataset variable origin orgdetl comment;

set defvar;
keep dataset variable label fmtname datatype length sigdigit dispfmt origin orgdetl keyseq 
     mandatory role order comment methtyp docref1;


*** create defvl *** ;

data chk1(keep=dataset); set defvar; where variable='PARAMCD';
data chk2; set defvar; where variable in ('AVAL','AVALC');

proc sql noprint;
select count(*) into :anyparm from chk1;

%if &anyparm=0 %then %do;
data defvl;
set defvar;
if _n_>=1 then delete;
where1=' ';
run;

%end;

%else %do;

data _null_; 
set chk1 end=eof;
i+1;
call symput(compress('datparm'||i), trim(left(dataset)));
if eof then call symput('totparm',trim(left(_n_)));
run;

%do i=1 %to &totparm;
proc sql;
create table parm&i as 
select distinct paramcd from inlib.&&datparm&i;

data parm&i; set parm&i; 
dataset="&&datparm&i";

data parm(keep=dataset where1); 
length where1 $30.;
set %if &i=1 %then %do; parm1 %end; %else %do; parm parm&i %end;;
where1=compbl("PARAMCD EQ '"||strip(paramcd)||"'");
run;
%end;

proc sort data=chk2; by dataset;
proc sort data=parm; by dataset;

proc sql;
create table defvl as 
select * from chk2 full join parm
on chk2.dataset=parm.dataset;

proc sort data=defvl; by dataset variable where1;
%end;

data defvl;
retain dataset variable comment where1;
set defvl;
keep dataset variable label fmtname datatype length sigdigit dispfmt origin orgdetl order comment methtyp docref1 where1;
run;


*** create deffmt *** ;
proc sql;
create table deffmt as
select dataset, variable, fmtname, datatype from defvar where fmtname>' ';

data _null_; 
set deffmt end=eof;
i+1;
call symput(compress("datfmt"||i), trim(left(dataset)));
call symput(compress("varfmt"||i), trim(left(variable)));
if eof then call symput("fmtvar", trim(left(_n_)));
run;

%do i=1 %to &fmtvar;
proc sql;
create table val&i as 
select distinct &&varfmt&i as value from inlib.&&datfmt&i where &&varfmt&i > ' ';

data val&i; 
length dataset variable $8.;
set val&i;
dataset=compress("&&datfmt&i");
variable=compress("&&varfmt&i");

data val; 
length value $200.;
set %if &i=1 %then %do; val1 %end; %else %do; val val&i %end;;
%end;

proc sort data=deffmt; by dataset variable;
proc sort data=val; by dataset variable;

data deffmt;
length fmttype $6. dictnm $20.;
merge deffmt val;
by dataset variable;
fmtlab=fmtname;
fmttype='CT';
decode=' ';
order=.;
rank=.;
ncifmt=.;
nciitem=.;
dictnm=' ';
dictver=' ';
run;

data deffmt; set deffmt;
keep fmtname fmtlab fmttype datatype value decode order rank ncifmt nciitem dictnm dictver;
run;

proc sort data=deffmt nodupkey; by fmtname value;


** output the meta data ** ;
data metalib.defds; set defds; 
data metalib.defvar; set defvar;
data metalib.defvl; set defvl;
data metalib.deffmt; set deffmt;
run;


%mend;

%meta(inlib=&ads);

