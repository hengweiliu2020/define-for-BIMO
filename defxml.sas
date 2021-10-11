
/****************************************************************************************
Program Name:                 defxml.sas  
Purpose:                      Create define.xml with use of datasets DEFDS, DEFVAR, DEFVL & DEFFMT
                              Current program is designed for SDTM & ADaM data, and it would work 
                              for SEND data with few modifications
                              
Parameters:                   AMETA/SMETA: Metadata library name where DEFxxx datasets are located
                              DEFPATH: Filename reference for the folder where define.xml would be located
                              CDISCVER: data standard name with IG version, E.g. SDTM 3.1.2, ADAM 1.0
                              PROTID: Protocol ID, e.g. XYZ003 
                              DESCRIP: Study description/title  
                              REVGUIYN (Y/N): Y if reviewers guide (pdf file) is part of define package?  
                              COMPALGO (Y/N): Y if complex Algorithms file (pdf file) is part of define package?  
                              BOOKCRF (Y/N): Y if aCRF is part of define package? 
                              RGNAME : Name of reviewers guide file (pdf), e.g. reviewersguide.pdf
                              RGLABEL: Display label for reviewers guide, e.g. Analysis Data Reviewers Guide
                              ARMYN (Y/N): Y if there is an analysis metadata section
                              
Original Author:              Vineet Jain  
Date Initiated:               01-JAN-2014 
Date Last Modified:           06-Sep-2014  
Reason for Modification:      Updated Documentation  
Input:                        Datasets DEFDS, DEFVAR, DEFVL & DEFFMT in metadata library  
Output:                       Define.xml  
External macro referenced:    MAXLEN 
Program Version #:            1.0  
****************************************************************************************/

%include "C:\BIMO\admacro.sas";

%macro defxml;
*/
   options missing='';


   * Generate parameters for the defxml macro, replace below code to populate the parameters(if needed) *;
   ******************************************************************************************************;
  /* data _null_;
      call symputx("metalib",substr("&cdisctyp",1,1) || 'meta');
   run;

   data _null_;
      set &&&metalib...options;
      if upcase(paramcd) in ('CDISCVER' 'PROTID' 'DESCRIP' 'REVGUIYN' 'BOOKCRF' 'COMPALGO' 'RGNAME' 'RGLABEL');
      call symputx(upcase(paramcd),value);
   run;*/
   ******************************************************************************************************;
   
   * Assign default values to option parameters (except defpath) if parameters do not already exist *;
   %if %symexist(CDISCVER) = 0 %then %do;
      %let deftype = ADAM;
      %let metaver=1.0;
   %end;
   %else %do;
      %let deftype = %scan(&CDISCVER,1 );
      %let metaver=%scan(&CDISCVER,2," ");
   %end;
   %if %symexist(protid) = 0 %then %do;
      %let protid = DUMMY;
   %end;
   %if %symexist(descrip) = 0 %then %do;
      %let descrip = DUMMY;
   %end;
   %if %symexist(BOOKCRF) = 0 %then %do;
      %let BOOKCRF = N;
   %end;   
   %if %symexist(REVGUIYN) = 0 %then %do;
      %let REVGUIYN = N;
   %end;  
   %if %symexist(RGNAME) = 0 %then %do;
      %let RGNAME = reviewersguide.pdf;
   %end;  
   %if %symexist(RGLABEL) = 0 %then %do;
      %let rglabel=Reviewers Guide;
      %if %upcase(&deftype)=ADAM %then %do;
         %let rglabel = Analysis Data Reviewers Guide;
      %end;
   %end;     
   %if %symexist(COMPALGO) = 0 %then %do;
      %let COMPALGO = N;
   %end;
   
   /*%if &deftype=ADAM %then %do;
      %let defpath=&adefinef;
   %end;
   %if &deftype=SDTM %then %do;
      %let defpath=&sdefinef;
   %end;*/
   
   %put &cdiscver &deftype &metaver;
   
   * Read metadata tables & clean up character not permitted in define.xml *;
   %let m1 = defds; 
   %let m2 = defvar;
   %let m3 = defvl;
   %let m4 = deffmt;

   %do i = 1 %to 4;
   
      data &&m&i;
         set metalib.&&m&i;
         array charvar_{*} _character_;
         do i = 1 to dim(charvar_);
            charvar_(i) = trim(left(charvar_(i)));
            charvar_(i) = tranwrd(charvar_(i),'&','&amp;');
            charvar_(i) = tranwrd(charvar_(i) ,'91'x, "'");
            charvar_(i) = tranwrd(charvar_(i) ,'92'x, "'");
            charvar_(i) = tranwrd(charvar_(i), '<',' &lt; ');
            charvar_(i) = tranwrd(charvar_(i), '>',' &gt; ');
            charvar_(i) = compress(charvar_(i),,'kw');
         end;
      run;
   %end;

   * Remove all formats & informats from metadata tables *;
   proc datasets lib=work memtype=data;
      modify defvar ;
        attrib _all_ format=;
        attrib _all_ informat=;
      modify defvl ;
        attrib _all_ format=;
        attrib _all_ informat=;   
      modify deffmt ;
        attrib _all_ format=;
        attrib _all_ informat=;   
   quit;;

   * If label for format is not assigned, assign it with format name *;
   data deffmt;
      set deffmt;
      if fmtlab = '' then fmtlab = fmtname;


   * Create the xml header *;
   %let datetime = %sysfunc(datetime(),IS8601DT.);

   data _null_;
      file defpath(define.xml) linesize=5000  encoding="utf-8";
      put @1"<?xml version='1.0' encoding='UTF-8'?>                                                         ";
      put @1"<?xml-stylesheet type='text/xsl' href='define2-0-0.xsl'?>                                      ";
      put @1"<!-- ********************************************************************************** -->    ";
      put @1"<!-- File: define.xml                                                                   -->    ";
      put @1"<!-- Description: This is the define.xml V2.0.0 document based on the adam define.xml   -->    ";
      put @1"<!--    V2.0 example by CDISC                                                           -->    ";
      put @1"<!-- ********************************************************************************** -->    ";
      put @1"<ODM                                                                                           ";
      put @1"   xmlns='http://www.cdisc.org/ns/odm/v1.3'                                                    ";
      put @1"   xmlns:xlink='http://www.w3.org/1999/xlink'                                                  ";
      put @1"   xmlns:def='http://www.cdisc.org/ns/def/v2.0'                                                ";
	  put @1"   xmlns:arm='http://www.cdisc.org/ns/arm/v1.0'                                                ";
      put @1"   ODMVersion='1.3.2'                                                                          ";
      put @1"   FileOID='Study-&protid-&deftype-data'                                                       ";
      put @1"   FileType='Snapshot'                                                                         ";
      put @1"   CreationDateTime='&datetime'>                                                               ";
      put @1"                                                                                               ";
      put @1"   <!-- ******************************************  -->                                        ";
      put @1"   <!-- OID conventions used in this file:          -->                                        ";
      put @1"   <!--    def:leaf, leafID        = LF.            -->                                        ";
      put @1"   <!--    def:ValueListDef        = VL.            -->                                        ";
      put @1"   <!--    def:WhereClauseDef      = WC.            -->                                        ";
      put @1"   <!--    ItemGroupDef            = IG.            -->                                        ";
      put @1"   <!--    ItemDef                 = IT.            -->                                        ";
      put @1"   <!--    CodeList                = CL.            -->                                        ";
      put @1"   <!--    MethodDef               = MT.            -->                                        ";
      put @1"   <!--    def:CommentDef          = COM.           -->                                        ";
      put @1"   <!-- ******************************************  -->                                        ";
      put @1"                                                                                               ";
      put @1"   <Study OID='&protid'>                                                                       ";
      put @1"      <GlobalVariables>                                                                        ";
      put @1"         <StudyName>&protid</StudyName>                                                        ";
      put @1"         <StudyDescription>&descrip</StudyDescription>                                         ";
      put @1"         <ProtocolName>&protid</ProtocolName>                                                  ";
      put @1"      </GlobalVariables>                                                                       ";
      if "&deftype" = "SDTM" then do;
         put @1"      <MetaDataVersion OID='CDISC.SDTMIG'                                                   ";
         put @1"         def:StandardName='SDTM-IG'                                                         ";
         put @1"         def:StandardVersion='&metaver'                                                     ";
      end;
      else if "&deftype" = "ADAM" then do;
         put @1"      <MetaDataVersion OID='CDISC.ADaMIG'                                                   ";
         put @1"         def:StandardName='ADaM-IG'                                                         ";
         put @1"         def:StandardVersion='&metaver'                                                     ";
      end;
      put @1"         Name='Study &protid, Data Definitions'                                                ";
      put @1"         Description='Study &protid, Data Definitions'                                         ";
      put @1"         def:DefineVersion='2.0.0'>                                                            ";
      put @1"                                                                                               ";
      put @1"      <!-- ******************** -->                                                            ";
      put @1"      <!-- Supporting Documents -->                                                            ";
      put @1"      <!-- ******************** -->                                                            ";
      if "&BOOKCRF" = "Y" then do;
         put @1"      <def:AnnotatedCRF>";
         put @1"         <def:DocumentRef leafID='LF.acrf'/>";
         put @1"      </def:AnnotatedCRF>";
      end;
      if "&REVGUIYN" = "Y" or "&COMPALGO" = "Y" then do;
         put @7"<def:SupplementalDoc>";
         if "&REVGUIYN" = "Y" then put @10"<def:DocumentRef leafID='LF.&rg_name'/>";
         if "&COMPALGO" = "Y" then put @10"<def:DocumentRef leafID='LF.ComplexAlgorithms'/>";
         put @7"</def:SupplementalDoc>";
      end;
   run;

   ***Insert the ARM Section***;
   %if "&armyn"="Y" %then %do;
   data _null_; 
   file defpath(define.xml) mod  encoding="utf-8";
 
   set metalib.defarm(where=(cat='ARMTEXT')); 
   x = length(xmlcode)- length(left(xmlcode)); 
   put @x xmlcode ; 
   %end;
   run;



   *** Value level Definitions (ValueListDef) ***;
   proc sql;
      create table defvl2 as
         select vl.*, var.mandatory
         from defvl as vl left join defvar as var
         on vl.dataset = var.dataset and vl.variable = var.variable
         order by vl.dataset, vl.variable, vl.order;
   quit;

   data defvl2;
      set defvl2;
      by dataset variable order;
      retain vlorder;
      if first.variable then vlorder = 1;
      else vlorder = vlorder + 1;
   run;

   data _null_;
      set defvl2;
      by dataset variable vlorder;
      file defpath(define.xml) mod  encoding="utf-8";
      if _n_ = 1 then do;
         put @1 ;
         put @7"<!-- ********************************************** -->";
         put @7"<!-- Value Level Metadata Section ***************** -->";
         put @7"<!-- ********************************************** -->";
      end;
      if first.variable then put @7 '<def:ValueListDef OID="VL.' dataset +(-1) '.' variable +(-1) '">';
      put @10 '<ItemRef ItemOID="IT.' dataset +(-1) '.' variable +(-1) '.item' vlorder  +(-1)
              '" OrderNumber="' vlorder 
              '" Mandatory="No">';
      put @13 '<def:WhereClauseRef WhereClauseOID="WC.' dataset +(-1) '.' variable +(-1) '.item' vlorder  +(-1) '"/>';
      put @10 '</ItemRef>';
      if last.variable then put @7 '</def:ValueListDef>';
   run;

   data defvl3(drop=_:);
      set defvl2;
      format checkvar $100. checkval $200. _end _txt $500. ;
      array wherest(*) where:;
      do var_ = 1 to dim(wherest);
         _txt = wherest(var_);
         checkvar = scan(_txt,1);
         comparator = upcase(scan(_txt,2));
         _end = substr(_txt,index(_txt,scan(_txt,3)));
         if _end ne '' and comparator in ('LT' 'LE' 'GT' 'GE' 'EQ' 'NE' 'IN' 'NOTIN') and nvalid(checkvar) then do;
            checkvar= catx('.','IT',dataset,checkvar);
            do val_ = 1 to 200;
               checkval = dequote(trim(left(scan(_end,val_,', ','q'))));
               if anyalnum(checkval) then output;
               else leave;
            end;
         end;
      end;
   run;

   * WhereClauseDef for valuelevel metatdata *;
   data _null_;
      set defvl3;
      by dataset variable vlorder var_ val_;
      file defpath(define.xml) mod  encoding="utf-8"; 
      format itemoid  $400.;
      itemoid = catx('.','WC',dataset,variable,'item' || compress(vlorder));
      if first.vlorder then put @7 '<def:WhereClauseDef OID="' itemoid +(-1) '">';
      if first.var_ then put @10 '<RangeCheck SoftHard="Soft" def:ItemOID="' checkvar +(-1) '" Comparator="' Comparator +(-1) '">';
      put @13 '<CheckValue>' checkval +(-1) '</CheckValue>';
      if last.var_ then put @10 '</RangeCheck>';
      if last.vlorder then put @7 '</def:WhereClauseDef>';
      if last.vlorder then put @1;  
   run;

   *** List the datatsets(ItemGroupDef) & variable list(itemref) ***;
   proc sql;
      create table defds2 as
         select ds.*, var.variable, var.order as varord, var.mandatory, var.keyseq, var.comment as varcom, var.origin, var.docref1 as varref1 
         from defds as ds inner join defvar as var
         on ds.dataset = var.dataset
         order by ds.order, ds.dataset, var.order;
   quit;

   data _null_;
      set defds2;
      by order dataset varord;
      file defpath(define.xml) mod  encoding="utf-8";
      format condtext $500.;
      if _n_=1 then do;
         put @1 ;
         put @7 '<!-- ************************************************************** -->';
         put @7 '<!-- Lists Datasets (ItemGroupDef)                                  -->';
         put @7 '<!-- ************************************************************** -->';
      end;

      if first.dataset then do;
         put @1;
         if (comment ne '' or docref1 ne '') then condtext = 'def:CommentOID="COM.' || compress(dataset) || '"';
         if domain ne '' then condtext = left(trim(condtext) || ' Domain="' || compress(domain) || '"'); 
         if isref ne '' then condtext = left(trim(condtext) || ' IsReferenceData="' || compress(isref) || '"'); 
         put @7 '<ItemGroupDef OID="IG.' dataset +(-1) 
                '" Name="' dataset +(-1) 
                '" SASDatasetName="' dataset +(-1) 
                '" Repeating="' repeating +(-1) 
                '" Purpose="' purpose +(-1) 
                '" def:Class="' class +(-1) 
                '" def:ArchiveLocationID="LF.' dataset +(-1) '" def:Structure="' struct +(-1) '" ' condtext '>';
         put @10 '<Description><TranslatedText xml:lang="en">' label +(-1) '</TranslatedText></Description>';
      end;

      * Var list (Itemref)*;
      condtext = '';
      if keyseq ne . then condtext = ' KeySequence="' || compress(keyseq) || '"';
      if upcase(origin) = 'DERIVED' and (varcom ne '' or varref1 ne '') then condtext = trim(condtext) || ' MethodOID="MT.' || compress(dataset) || '.' || compress(variable) || '"';
      put @10 '<ItemRef ItemOID="IT.' dataset +(-1) '.' variable +(-1) 
             '" OrderNumber="' varord +(-1) 
             '" Mandatory="' mandatory +(-1) '" ' condtext '/>';
      
      * Hyper Link to dataset*;
      if last.dataset then do;
      	put @10 '<def:leaf ID="LF.' dataset +(-1) '" xlink:href="' dataset +(-1)  '.xpt"> <def:title>' dataset +(-1)  '.xpt</def:title> </def:leaf>';
         put @7 '</ItemGroupDef>';
      end;
   run;

   *** Variable & VLMD Definitions (ItemDef)***;
   proc sql;
      create table defvar2 as
      select var.*, vl.variable as resvar, 0 as vlorder
      from defvar as var left join (select distinct dataset, variable from defvl ) as vl
      on var.dataset=vl.dataset and var.variable=vl.variable
      order by var.dataset, var.variable;
   quit;
   
   %maxlen(defvar2,defvl2,,,);

   data _null_;
      &maxvlen;
      length itemoid condtext $1000. temp_1 temp_2 $200.;
      set defvar2(in=a) defvl2(in=b);
      by dataset variable vlorder;
      file defpath(define.xml) lrecl=2000 mod  encoding="utf-8";
      if _n_=1 then do;
         put @1 ;
         put @7 '<!-- *************************************************************** -->';
         put @7 '<!-- Variable/Value Level Itemdefs                                   -->';
         put @7 '<!-- *************************************************************** -->';
      end;
      itemoid = catx('.',dataset,variable);
      if b then itemoid = compress(itemoid) || '.item' || compress(vlorder);
      if datatype='float' then condtext = 'SignificantDigits="' || compress(sigdigit) || '"';
      if datatype in ('text' 'integer' 'float') then condtext = trim(condtext) || ' Length="' || compress(length) || '"';
      if dispfmt ne '' then condtext = trim(condtext) || ' def:DisplayFormat="' || compress(dispfmt) || '"';
      if (comment ne '' or docref1 ne '') and (origin not in ('Derived' 'Predecessor') or b) then condtext = trim(condtext) || ' def:CommentOID="COM.' || compress(itemoid) || '"';
      condtext = left(trim(condtext));
      put @7 '<ItemDef OID="IT.' itemoid +(-1)
             '" Name="' variable +(-1)
             '" SASFieldName="' variable +(-1)
             '" DataType="' datatype +(-1) '" ' condtext '>';
      if a or (b and label ne '') then put @10 '<Description><TranslatedText xml:lang="en">' label +(-1) '</TranslatedText></Description>';
      if fmtname ne '' then put @10 '<CodeListRef CodeListOID="CL.' fmtname +(-1) '"/>';
      if origin = 'CRF' then do;
         put @10 '<def:Origin Type="' origin +(-1) '"><def:DocumentRef leafID="LF.acrf">';
         if index(ORGDETL,'-') = 0 then put @13 '<def:PDFPageRef PageRefs="' ORGDETL +(-1) '" Type="PhysicalRef"/>';
         else do;
            temp_1 = scan(ORGDETL,1,'-'); 
            temp_2 = scan(ORGDETL,2,'-');
            put @13 '<def:PDFPageRef FirstPage="' temp_1 +(-1) '" LastPage="' temp_2 +(-1) '" Type="PhysicalRef"/>';
         end;
         put @10 '</def:DocumentRef></def:Origin>';
      end;
      else if origin = 'Predecessor' then do;
         put @10 '<def:Origin Type="Predecessor"><Description>';
         put @13 '<TranslatedText xml:lang="en">' ORGDETL +(-1) '</TranslatedText>';
         put @10 '</Description></def:Origin>';
      end;
      else if origin ne '' then do;
         if index(origin,'CRF') > 0 then origin = trim(left(tranwrd(origin,'CRF',''))) || ' CRF Page';
         if countw(orgdetl,' ') > 1 then origin = trim(origin) || 's';
         if orgdetl ne '' then origin = catx(' ',origin,orgdetl);
         put @10 '<def:Origin Type="' origin +(-1) '"/>';
      end;
      if resvar ne '' then put @10 '<def:ValueListRef ValueListOID="VL.' itemoid +(-1) '"/>';
      put @7 '</ItemDef>'; 
      put @1;
   run;

   * Controlled Terminology *;
   proc sort data=deffmt;
      by fmtlab fmtname order rank;

   data _null_;
      set deffmt;
      by fmtlab fmtname order rank;
      file defpath(define.xml) mod encoding="utf-8";
      if _n_=1 then do;
         put @1;
         put @7 '<!-- ***************************************** -->';
         put @7 '<!-- The Controlled Terminology                -->';
         put @7 '<!-- ***************************************** -->';
      end;
      if first.fmtname then do;
         put @1;
         put @7 '<CodeList OID="CL.' fmtname +(-1)
                '" Name="' fmtlab +(-1)
                '" DataType="' datatype +(-1) '" >';
         if ncifmt ne '' then put @10 '<Alias Name="' ncifmt +(-1) '" Context="nci:ExtCodeID"/>';
      end;
      format condtext $200.;
      condtext = ''; 
      if rank ne . then condtext = 'Rank="' || compress(rank) || '"';
      if order ne . then condtext = left(trim(condtext) || ' OrderNumber="' || compress(order)  || '"');
      if ncifmt ne '' and nciitem = '' then condtext = left(trim(condtext) || ' def:ExtendedValue="Yes"');
      if upcase(fmttype)  = 'FORMAT' then put @10 '<CodeListItem CodedValue="' value +(-1) '" ' condtext +(-1) '><Decode><TranslatedText>' decode +(-1)  '</TranslatedText></Decode>';
      else if upcase(fmttype) = 'CT' then put @10 '<EnumeratedItem CodedValue="' value +(-1) '" ' condtext +(-1) '>';
      else if upcase(fmttype) = 'DICT' then put @10 '<ExternalCodeList Dictionary="' dictnm +(-1) '" Version="' dictver +(-1) '"/>';
      if nciitem ne '' then put @13 '<Alias Name="'  nciitem +(-1) '" Context="nci:ExtCodeID"/>';
      if upcase(fmttype)  = 'FORMAT' then put @10 '</CodeListItem>';
      else if upcase(fmttype) = 'CT' then put @10 '</EnumeratedItem>';
      if last.fmtname then put @7 '</CodeList>';
   run;

   %maxlen(defds(keep=dataset comment docref:),defvar(keep=dataset variable origin comment docref:),defvl2 (keep=dataset variable vlorder comment docref:),,);

   data comments;
      &maxvlen; length comtype $7.;
      set defds(in=a keep=dataset comment docref: where=(comment ne '' or docref1 ne ''))
         defvar(in=b keep=dataset variable origin comment docref:  methtyp where=(comment ne '' or docref1 ne ''))
         defvl2 (in=c keep=dataset variable vlorder comment docref: where=(comment ne '' or docref1 ne ''));
      if origin notin ('Predecessor');
      if b and upcase(origin) = 'DERIVED' then do;
         comtype = 'method';
         itemoid = catx('.',dataset,variable);
      end;
      else do;
         comtype='comment';
         if a then itemoid = dataset;
         if b then itemoid = catx('.',dataset,variable);
         if c then itemoid = catx('.',dataset,variable,'item' || compress(vlorder));
      end;      
      array docref{*} docref:;
      do i = 1 to dim(docref);
         if i = 1 and docref(1) = '' then output;
         else do;
            docid = scan(docref(i),1,'#');
            reftyp = scan(docref(i),2,'#');
            pdfref= scan(docref(i),3,'#');
            if docid ne '' then output;
         end;
      end;              
   run;

   proc sort data=comments;
      by descending comtype dataset variable vlorder;

   data _null_;
      set comments;
      by descending comtype dataset variable vlorder;
      file defpath(define.xml) mod  encoding="utf-8";
      if _n_=1 and comtype = 'method' then do;
         put @1;
         put @7 '<!-- ***************************************** -->';
         put @7 '<!-- Methods                                   -->';
         put @7 '<!-- ***************************************** -->';
      end;
      if first.comtype and comtype = 'comment' then do;
         put @1;
         put @7 '<!-- ***************************************** -->';
         put @7 '<!-- Comments                                  -->';
         put @7 '<!-- ***************************************** -->';
      end;
      if first.vlorder then do;
         if comtype = 'method' then put @7 '<MethodDef OID="MT.' itemoid +(-1) '" Name="Algorithm to derive ' itemoid +(-1) '" Type="' methtyp +(-1) '">';
         else put @7 '<def:CommentDef OID="COM.' itemoid +(-1) '">';
         put @10 '<Description><TranslatedText xml:lang="en">' comment +(-1) '</TranslatedText></Description>';
      end;
      format temp_1 temp_2 $200.;
      if docid ne '' then do;
         if pdfref = '' then put @10 '<def:DocumentRef leafID="LF.' docid +(-1) '"/>';
         else do;
            put @10 '<def:DocumentRef leafID="LF.' docid +(-1) '">';
            temp_1 = scan(pdfref,1);
            temp_2 =  scan(pdfref,2);
            if upcase(reftyp) = 'PRR' then put @13 '<def:PDFPageRef FirstPage="' temp_1 +(-1) '" LastPage="' temp_2 +(-1) '" Type="PhysicalRef"/>';
            if upcase(reftyp) = 'PR' then put @13 '<def:PDFPageRef PageRefs="' pdfref +(-1) '" Type="PhysicalRef"/>';
            if upcase(reftyp) = 'ND' then put @13 '<def:PDFPageRef PageRefs="' pdfref +(-1) '" Type="NamedDestination"/>';
            put @10 '</def:DocumentRef>';
         end;
      end;
      if last.vlorder then do;
         if comtype = 'method' then put @7 '</MethodDef>';
         else put @7 '</def:CommentDef>';
      end;
   run;
 

   ***Insert the LEAF for ARM***;
    %if "&armyn"="Y" %then %do;
    data _null_; 
	file defpath(define.xml) mod  encoding="utf-8";

    set metalib.defarm(where=(cat='PDFTEXT')); 
    x = length(xmlcode)- length(left(xmlcode)); 
    put @x xmlcode ; 
    %end;
    run;


   * End of XML file *;
   data _null_;
      file defpath(define.xml) mod  encoding="utf-8";
      put @1;
      if "&BOOKCRF" = "Y" then do;
         put @1"      <def:leaf ID='LF.acrf' xlink:href='acrf.pdf'>";
         put @1"         <def:title>Annotated Case Report Form</def:title>";
         put @1"      </def:leaf>      ";
      end;
      rgname = trim(left("&rgname"));
      rglabel = trim(left("&rglabel"));
      if "&REVGUIYN" = "Y" then do;
         put @7"<def:leaf ID='LF.&rg_name' xlink:href='" rgname +(-1) "'>";
         put @10"<def:title>" rglabel +(-1) "</def:title>";
         put @7"</def:leaf>";
      end;
      if "&COMPALGO" = "Y" then do;   
         put @7"<def:leaf ID='LF.ComplexAlgorithms' xlink:href='complexalgorithms.pdf'>";
         put @10"<def:title>Complex Algorithms</def:title>";
         put @7"</def:leaf> ";
         put @1;
      end;

      put @4  '</MetaDataVersion>';
      put @4  '</Study>';
      put @1  '</ODM>';
   run;

   exit:
%mend defxml;
%defxml;


