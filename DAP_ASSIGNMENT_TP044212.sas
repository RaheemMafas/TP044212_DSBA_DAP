/* Loading the dataset to SAS Studio*/
PROC IMPORT OUT=DAP_ASGMNT_DATA_TP044212 
		DATAFILE="/home/rmafas0/sasuser.v94/DAP_ASSIGNMENT/Table_4.xls" DBMS=XLS 
		REPLACE;
	GETNAMES=NO;
	NAMEROW=1;
	DATAROW=2;
	ENDROW=521;
	ENDCOL=O;
RUN;


/* Visualising the dataset */
TITLE1 'Offenses Reported to Law Enforcement of US';
TITLE2 'by State by City 100,000 and over in population';
TITLE3 'January to June 2014–2015';
PROC PRINT DATA=DAP_ASGMNT_DATA_TP044212 LABEL;
	LABEL 
		State='Name of the State' 
		City='Name of the City' 
		Violent_crime='Violent Crime' 
		Rape_revised_definition='Rape (Revised Definition)' 
		Rape_legacy_definition='Rape (Legacy Definition)' 
		Aggravated_assault='Aggravated Assault' 
		Property_crime='Property Crime' 
		Larceny_theft='Larceny Theft' 
		Motor_vehicle_theft='Motor Vehicle Theft';
RUN;
TITLE1;
TITLE2;
TITLE3;


/* Create a format to group missing and non-missing values*/
PROC FORMAT ;
	value $missfmt ""='missing' other='non-missing';
	value missfmt .='missing' other='non-missing';
	value $missfmt ?='missing' other='non-missing';
RUN;

/* Printing no. of missing values with percentages */
TITLE1 'Missing Values';
PROC FREQ DATA=DAP_ASGMNT_DATA_TP044212;
	format _CHAR_ $missfmt.;
	tables _CHAR_ / missing missprint nocum;
	format _NUMERIC_ missfmt.;
	tables _NUMERIC_ / missing missprint nocum;
RUN;
TITLE1;


/* Data Transformation */
DATA PP_DAP_ASGMNT_DATA_TP044212;
	SET DAP_ASGMNT_DATA_TP044212;
	RETAIN 	
		m_state
		m_city
		m_population; 
	if not missing(state) 
		then m_state=state;
		else state=m_state;
	if not missing(city) 
		then m_city=city;
		else city=m_city;
	if not missing(population) 
		then m_population=round(population+(population*0.0072));
   		else population=m_population;
   	Rape=SUM(Rape_revised_definition, Rape_legacy_definition);	
 		DROP 	
   		m_state
   		m_city
		m_population
		Rape_revised_definition
		Rape_legacy_definition;
RUN;


/* Replacing missing values using MEAN */
PROC STDIZE DATA=PP_DAP_ASGMNT_DATA_TP044212 REPONLY MISSING=MEAN 
		OUT=PRP_DAP_ASGMNT_DATA_TP044212;
	VAR Violent_crime Murder Rape Robbery Aggravated_assault 
		Property_crime Burglary Larceny_theft Motor_vehicle_theft Arson;
RUN;


/* Rounding function for the replaced values & Data Transformation */
DATA FINAL_DAP_ASGMNT_DATA_TP044212;
	SET PRP_DAP_ASGMNT_DATA_TP044212;
	
	Violent_crime=round (Violent_crime, 1);
	Murder=round (Murder, 1);
	Rape=round (Rape, 1);
	Robbery=round (Robbery, 1);
	Aggravated_assault=round (Aggravated_assault, 1);
	Property_crime=round (Property_crime, 1);
	Burglary=round (Burglary, 1);
	Larceny_theft=round (Larceny_theft, 1);
	Motor_vehicle_theft=round (Motor_vehicle_theft, 1);
	Arson=round (Arson, 1);
	
   	Total_property_crime=SUM (Property_crime, Burglary);
 	Total_theft=SUM (Larceny_theft, Motor_vehicle_theft);
 	Total_Crime=SUM (Violent_crime, Total_property_crime, Total_theft, Arson);
 	
 	Violent_crime_pcnt=ROUND (((Violent_crime/Total_crime)*100), 0.01);
 	Total_property_crime_pcnt=ROUND (((Total_property_crime/Total_crime)*100), 0.01);
 	Total_theft_pcnt=ROUND (((Total_theft/Total_crime)*100), 0.01);
 	Arson_pcnt=ROUND (((Arson/Total_crime)*100), 0.01);
 	
RUN;


/* Checking missing values - After Pre-processing */
TITLE1 'Missing Values check - After Replacement using MEAN';
PROC MEANS DATA=FINAL_DAP_ASGMNT_DATA_TP044212 NMISS;
RUN;
TITLE1;


/* Printing Fully Preprocessed dataset - Final */
TITLE1 'Fully Preprocessed dataset';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
TITLE3 'Offenses Reported to Law Enforcement of US';
TITLE4 'by State by City 100,000 and over in population';
TITLE5 'January to June 2014–2015';
PROC PRINT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 NOOBS LABEL ;
		LABEL
		State='Name of the State' 
		City='Name of the City' 
		Violent_crime='Violent Crimes' 
		Rape='Rape (Revised & Legacy)' 
		Aggravated_assault='Aggravated Assault' 
		Property_crime='Property Crimes' 
		Larceny_theft='Larceny Theft' 
		Motor_vehicle_theft='Motor Vehicle Theft' 
		Total_crime='Total No. of Crimes'
		Total_theft='Total No. of Theft'
		Total_Property_crime='Total No. of Property Crimes'
		Violent_crime_pcnt='Violent Crimes Percentage'
		Total_property_crime_pcnt='Total Property Crimes Percentage'
		Total_theft_pcnt='Total Theft Percentage'
		Arson_pcnt='Arson Percentage';
RUN;
TITLE1; TITLE2; TITLE3; TITLE4; TITLE5;

/* Contents of the Fully Preprocessed dataset - Final */
PROC CONTENTS DATA=FINAL_DAP_ASGMNT_DATA_TP044212;
RUN;


/* ~~~~~~~~~~~~~~~~~~~~~~~~  Objective 1 ~~~~~~~~~~~~~~~~~~~~~~~~  */
/* Overall Crime Analysis by main categories grouped by years */
TITLE1 'Overall Crime Analysis by main categories grouped by years';
PROC TABULATE DATA=FINAL_DAP_ASGMNT_DATA_TP044212;
     CLASS State Year;
     VAR Population Violent_crime Property_crime Burglary Larceny_theft Motor_vehicle_theft Arson Total_crime;
     TABLE State='' , 
		Year*(population*(SUM=''*f=comma16.) 
      	Violent_crime='Violent Crime'*(SUM=''*f=comma16.) 
  		Property_crime='Property Crime'*(sum=''*f=comma16.) 
  		Burglary*(sum=''*f=comma16.) 
  		Larceny_theft='Larceny Theft'*(sum=''*f=comma16.) 
  		Motor_vehicle_theft='Motor Vehicle Theft'*(sum=''*f=comma16.) 
        Arson*(sum=''*f=comma16.) 
        Total_crime='Total Crimes'*(sum=''*{s={fontweight=bold} f=comma16.}))
        / BOX='State';
RUN;
TITLE1;


/* Overall Crime Analysis by main categories aggregated and grouped by years */
TITLE1 'Overall Crime Analysis by main categories aggregated and grouped by years';
PROC TABULATE DATA=FINAL_DAP_ASGMNT_DATA_TP044212;
     CLASS State Year;
     VAR Population Violent_crime Total_Property_crime Total_theft Arson Total_crime;
     TABLE State='' , 
		Year*(population*(SUM=''*f=comma16.) 
      	Violent_crime='Violent Crime'*(SUM=''*f=comma16.) 
  		Total_Property_crime='Total Property Crime'*(sum=''*f=comma16.) 
  		Total_theft='Total Theft'*(sum=''*f=comma16.) 
        Arson*(sum=''*f=comma16.) 
        Total_crime='Total Crimes'*(sum=''*{s={fontweight=bold} f=comma16.}))
        / BOX='State' ;
RUN;
TITLE1;


/* Overall Crime Analysis by aggregated crimes and grouped by years */
/* Simple Hbar with total crime values */
ODS GRAPHICS / RESET WIDTH=6.4IN HEIGHT=11IN IMAGEMAP;
PROC SGPLOT DATA=FINAL_DAP_ASGMNT_DATA_TP044212;
	TITLE H=8pt "Overall Crime Analysis by aggregated crimes and grouped by years"; 
	HBAR State / RESPONSE=Total_Crime GROUP=Year GROUPDISPLAY=Cluster STAT=Sum
	DATASKIN=Gloss DATALABELFITPOLICY=none DATALABEL;
	YAXIS;
	XAXIS GRID;
	RUN;
ODS GRAPHICS / RESET;


/* Overall Crime Analysis of USA */
/* Violent Crime Analysis */
TITLE1'Violent Crimes in USA in 2014 & 2015';  
PROC TABULATE DATA=FINAL_DAP_ASGMNT_DATA_TP044212; 
     CLASS Year; 
     VAR Population Murder Robbery Rape Aggravated_assault Violent_crime; 
	 TABLE   
        Year*(population*(sum=''*f=comma16.) 
  		Murder='Murder'*(sum=''*f=comma16.) 
  		Rape='Rape'*(sum=''*f=comma16.)
  		Robbery='Robbery'*(sum=''*f=comma16.) 
  		Aggravated_assault='Aggrevated Assault'*(sum=''*f=comma16.) 
      	Violent_crime='Violent Crimes'*(SUM=''*f=comma16.)); 
RUN; 
TITLE1;


/* Total Crimes in USA in 2014 & 2015 - Category Wise */
TITLE1'Total Crimes in USA in 2014 & 2015 - Category Wise';  
PROC TABULATE DATA=FINAL_DAP_ASGMNT_DATA_TP044212; 
     CLASS Year; 
     VAR Population Violent_crime Property_crime Burglary Larceny_theft 
     Motor_vehicle_theft Arson Total_crime; 
	 TABLE   
        Year*(population*(sum=''*f=comma16.) 
      	Violent_crime='Violent Crimes'*(SUM=''*f=comma16.)  
  		Property_crime='Property Crimes'*(sum=''*f=comma16.) 
  		Burglary='Burglary'*(sum=''*f=comma16.) 
  		Larceny_theft='Larceny Theft'*(sum=''*f=comma16.) 
  		Motor_vehicle_theft='Motor Vehicle Theft'*(sum=''*f=comma16.)
  		Arson*(sum=''*f=comma16.)  
        Total_crime='Total Crimes'*(sum=''*{s={fontweight=bold} f=comma16.})) 
        / BOX='State';          
RUN; 
TITLE1;


/* Total Crimes in USA in 2014 & 2015 - Aggregated Category Wise */
TITLE1'Total Crimes in USA in 2014 & 2015 - Aggregated Category Wise';  
PROC TABULATE DATA=FINAL_DAP_ASGMNT_DATA_TP044212; 
     CLASS Year; 
     VAR Population Violent_crime Total_Property_crime Total_theft Arson Total_crime; 
	 TABLE   
        Year*(population*(sum=''*f=comma16.) 
      	Violent_crime='Violent Crimes'*(SUM=''*f=comma16.)  
  		Total_Property_crime='Total Property Crimes'*(sum=''*f=comma16.)  
  		Total_theft='Total Theft'*(sum=''*f=comma16.)  
  		Arson*(sum=''*f=comma16.)  
        Total_crime='Total Crimes'*(sum=''*{s={fontweight=bold} f=comma16.})) 
        / BOX='State';          
RUN; 
TITLE1;


/* ~~~~~~~~~~~~~~~~~~~~~~~~  Objective 2 ~~~~~~~~~~~~~~~~~~~~~~~~  */
/* Bar Chart (State wise crime totals - by main categories grouped by years) */
ODS GRAPHICS / RESET WIDTH=7in HEIGHT=11in IMAGEMAP;
PROC SGPLOT DATA=FINAL_DAP_ASGMNT_DATA_TP044212;
	TITLE1 H=10pt "State wise crime totals by main categories grouped by years";
	hbar State / response=Total_Crime group=Year groupdisplay=Cluster 
	dataskin=Gloss stat=Sum name='Bar' categoryorder=respdesc DATALABELFITPOLICY=none 
	DATALABEL;
	XAXIS GRID;
RUN;
ODS GRAPHICS / RESET;


/* State wise crime analysis by main categories - Top five states */
DATA TOP_FIVE_STATES;
SET FINAL_DAP_ASGMNT_DATA_TP044212;
WHERE State in ('CALIFORNIA','TEXAS','FLORIDA','NEW YORK','ARIZONA');
RUN;

TITLE1 BOLD H=12pt 'Total Crime of States and City by categories - Top five states'; 
PROC TABULATE DATA=TOP_FIVE_STATES;
    CLASS  State City Year;
    VAR population violent_crime property_crime Burglary Larceny_theft Motor_vehicle_theft Arson total_crime;
	TABLE State=''* (city=''),  
           year*(population*(sum=''*f=comma16.)
      		Violent_crime='Violent Crime'*(SUM=''*f=comma16.) 
  			Property_crime='Property Crime'*(sum=''*f=comma16.) 
  			Burglary*(sum=''*f=comma16.) 
  			Larceny_theft='Larceny Theft'*(sum=''*f=comma16.) 
  			Motor_vehicle_theft='Motor Vehicle Theft'*(sum=''*f=comma16.) 
        	Arson*(sum=''*f=comma16.) 
        	Total_crime='Total Crimes'*(sum=''*{s={fontweight=bold} f=comma16.}))
        	/ BOX='State';
RUN;
TITLE2;


/* Pie Chart (State wise crime totals by main categories grouped by years */
PROC TEMPLATE;
	DEFINE STATGRAPH WebOne.Pie;
		BEGINGRAPH;
		ENTRYTITLE "Pie Chart (State wise crime totals by main categories grouped by years)";
		LAYOUT REGION;
		PIECHART CATEGORY=State RESPONSE=Total_Crime / GROUP=Year GROUPGAP=2% 
			START=90 DATALABELLOCATION=INSIDE;
		ENDLAYOUT;
		ENDGRAPH;
	END;
RUN;

ODS GRAPHICS / RESET IMAGEMAP;
PROC SGRENDER TEMPLATE=WebOne.Pie DATA=FINAL_DAP_ASGMNT_DATA_TP044212;
RUN;
ODS GRAPHICS / RESET;


/* ~~~~~~~~~~~~~~~~~~~~~~~~  Objective 3 ~~~~~~~~~~~~~~~~~~~~~~~~  */
/* Sorting the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=SORTED_DAP_ASGMNT_DATA_TP044212;
by descending Total_crime;
RUN;

/* Print the sorted data */
TITLE1 'Top most cities with the highest crime rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=SORTED_DAP_ASGMNT_DATA_TP044212 (obs=15) NOOBS LABEL;
VAR State City Year Population Total_crime;
LABEL Total_crime='Total Crime';

RUN;
TITLE1; TITLE2;


/* City wise crime analysis by main categories - Top five cities */
DATA TOP_FIVE_CITIES;
SET FINAL_DAP_ASGMNT_DATA_TP044212;
WHERE City in ('NEW YORK', 'HOUSTON', 'LOS ANGELES', 'CHICAGO' 'SAN ANTONIO');
RUN;

TITLE1'Total Crime by Categories - top five Cities'; 
PROC TABULATE DATA=TOP_FIVE_CITIES;
     CLASS  State City Year;
     VAR population Violent_crime Property_crime Burglary Larceny_theft 
     Motor_vehicle_theft Arson Total_crime;
	 TABLE State=''* (City=''),  
           year*(population*(sum=''*f=comma16.)
      		Violent_crime='Violent Crime'*(SUM=''*f=comma16.) 
  			Property_crime='Property Crime'*(sum=''*f=comma16.) 
  			Burglary*(sum=''*f=comma16.) 
  			Larceny_theft='Larceny Theft'*(sum=''*f=comma16.) 
  			Motor_vehicle_theft='Motor Vehicle Theft'*(sum=''*f=comma16.) 
  			Arson*(sum=''*f=comma16.) 
        	Total_crime='Total Crimes'*(sum=''*{s={fontweight=bold} f=comma16.}))
        	/ BOX='State';         
RUN;
TITLE1;


/* City wise crime analysis by main categories (Agggregated) - Top five cities */
TITLE1'Total Crime by Categories (Agggregated) - top five Cities'; 
PROC TABULATE DATA=TOP_FIVE_CITIES;
     CLASS  State City Year;
     VAR population Violent_crime Total_Property_crime Total_theft Arson Total_crime;
	 TABLE State=''* (City=''),  
           year*(population*(sum=''*f=comma16.)
      		Violent_crime='Violent Crime'*(SUM=''*f=comma16.) 
  			Total_Property_crime='Total Property Crime'*(sum=''*f=comma16.) 
  			Total_theft='Total Theft'*(sum=''*f=comma16.) 
  			Arson*(sum=''*f=comma16.) 
        	Total_crime='Total Crimes'*(sum=''*{s={fontweight=bold} f=comma16.}))
        	/ BOX='State';         
RUN;
TITLE1;


/* Pie Chart (City wise crime totals by main categories grouped by years - Top five cities */
PROC TEMPLATE;
	DEFINE STATGRAPH WebOne.Pie;
		BEGINGRAPH;
		ENTRYTITLE "Pie Chart (City wise crime totals by main categories 
		grouped by years - Top five cities)";
		LAYOUT REGION;
		PIECHART CATEGORY=City RESPONSE=Total_Crime / GROUP=Year GROUPGAP=2% 
			START=90 DATALABELLOCATION=INSIDE;
		ENDLAYOUT;
		ENDGRAPH;
	END;
RUN;

ODS GRAPHICS / RESET IMAGEMAP;
PROC SGRENDER TEMPLATE=WebOne.Pie DATA=TOP_FIVE_CITIES;
RUN;
ODS GRAPHICS / RESET;


/* ~~~~~~~~~~~~~~~~~~~~~~ Individual Crime wise analysis - City ~~~~~~~~~~~~~~~~~~~~~~ */
/* City wise crime by Murder grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_MC;
by descending Murder;
RUN;

TITLE1 'Top most cities with the highest Murder rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_MC (obs=10) NOOBS;
VAR State City Year Population Murder;
RUN;
TITLE1; TITLE2;


/* City wise crime by Robbery grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_RC;
by descending Robbery;
RUN;

TITLE1 'Top most cities with the highest Robbery rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_RC (obs=10) NOOBS;
VAR State City Year Population Robbery;
RUN;
TITLE1; TITLE2;


/* City wise crime by Aggravated assault grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_AAC;
by descending Aggravated_assault;
RUN;

TITLE1 'Top most cities with the highest Aggravated assault rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_AAC (obs=10) NOOBS;
VAR State City Year Population Aggravated_assault;
RUN;
TITLE1; TITLE2;


/* City wise crime by Rape grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_RAC;
by descending Rape;
RUN;

TITLE1 'Top most cities with the highest Rape rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_RAC (obs=10) NOOBS;
VAR State City Year Population Rape;
RUN;
TITLE1; TITLE2;


/* City wise crime by Property crime grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_PC;
by descending Property_crime;
RUN;

TITLE1 'Top most cities with the highest Property crime rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_PC (obs=10) NOOBS;
VAR State City Year Population Property_crime;
RUN;
TITLE1; TITLE2;

/* City wise crime by Burglary grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_BC;
by descending Burglary;
RUN;

TITLE1 'Top most cities with the highest Burglary rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_BC (obs=10) NOOBS;
VAR State City Year Population Burglary;
RUN;
TITLE1; TITLE2;

/* City wise crime by Larceny theft grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_LTC;
by descending Larceny_theft;
RUN;

TITLE1 'Top most cities with the highest Larceny theft rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_LTC (obs=10) NOOBS;
VAR State City Year Population Larceny_theft;
RUN;
TITLE1; TITLE2;

/* City wise crime by Motor Vehicle theft grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_MVC;
by descending Motor_vehicle_theft;
RUN;

TITLE1 'Top most cities with the highest Motor vehicle theft rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_MVC (obs=10) NOOBS;
VAR State City Year Population Motor_vehicle_theft;
RUN;
TITLE1; TITLE2;


/* ~~~~~~~~~~~~~~~~~~~~~~ Categorical crime wise analysis - City ~~~~~~~~~~~~~~~~~~~~~~ */
/* City wise crime by Violent crime grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_VC;
by descending Violent_crime;
RUN;

TITLE1 'Top most cities with the highest Violent crime rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_VC (obs=10) NOOBS;
VAR State City Year Population Violent_crime;
RUN;
TITLE1; TITLE2;


/* City wise crime by Total property crime grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_TPC;
by descending Total_property_crime;
RUN;

TITLE1 'Top most cities with the highest Total property crime rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_TPC (obs=10) NOOBS;
VAR State City Year Population Total_property_crime;
RUN;
TITLE1; TITLE2;


/* City wise crime by Total theft grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_TTC;
by descending Total_theft;
RUN;

TITLE1 'Top most cities with the highest Total theft rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_TTC (obs=10) NOOBS;
VAR State City Year Population Total_theft;
RUN;
TITLE1; TITLE2;


/* City wise crime by Arson grouped by years - Top five cities */
/* Sorting & Printing the dataset to find top crime rated cities */
PROC SORT DATA=FINAL_DAP_ASGMNT_DATA_TP044212 OUT=CITY_WISE_CRIME_BY_AC;
by descending Arson;
RUN;

TITLE1 'Top most cities with the highest Arson rate';
TITLE2 '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
PROC PRINT DATA=CITY_WISE_CRIME_BY_AC (obs=10) NOOBS;
VAR State City Year Population Arson;
RUN;
TITLE1; TITLE2;


