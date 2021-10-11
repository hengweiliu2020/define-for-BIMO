
%macro admacro;
options validvarname=v7 sasautos=('C:\BIMO') ;


%global  cdiscver protid descrip  revguiyn compalgo bookcrf rgname rg_name rglabel armyn ads file_location;

libname  ads 'C:\BIMO\adam'; *the location for analysis dataset;
%let ads=%str(C:\BIMO\adam);

libname  metalib 'C:\BIMO\meta'; *where to store the metadata;
%let file_location=%str(C:\BIMO\meta);

filename defpath 'C:\BIMO\define'; *where to store the define.xml;

/*******************************************************************************
Set up the macros variables below
CDISCVER: data standard name with IG version, E.g. SDTM 3.1.2, ADAM 1.0
PROTID: Protocol ID, e.g. XYZ003 
DESCRIP: Study description/title  
REVGUIYN (Y/N): Y if reviewers guide (pdf file) is part of define package?  
COMPALGO (Y/N): Y if complex Algorithms file (pdf file) is part of define package?  
BOOKCRF (Y/N): Y if aCRF is part of define package? 
RGNAME : Name of reviewers guide file (pdf), e.g. reviewersguide.pdf
RGLABEL: Display label for reviewers guide, e.g. Analysis Data Reviewers Guide
ARMYN (Y/N): Y if there is an Analysis Result Metadata section.
*******************************************************************************/

%let cdiscver=ADAM 1.1;
%let protid=ABC-123;
%let descrip=%str(A double blind study);

%let revguiyn=Y;
%let compalgo=N;
%let bookcrf=N;
%let rgname=bimo-rev-guide.pdf;
%let rg_name=%sysfunc(scan(&rgname,1,'.'));
%let rglabel=BIMO Reviewers Guide;
%let armyn=N;

%mend;
%admacro;





