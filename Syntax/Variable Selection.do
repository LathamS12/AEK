/***************************************************************
* Author: Scott Latham
* Purpose: This file selects variables from the ECLS-K and
*			ECLS-K 2011 for inclusion in the analysis of 
*			changes in health outcomes
* 
* Creates: "F:\Scott\Change in K knowledge\Generated Datasets\Cross-Cohort Raw"
*
* Created: 8/5/2013
* Last modified: 6/15/2017
********************************************************/

clear all
set more off
set maxvar 10000
pause on
	
*******************
*  Base year 1998
*******************	
	use "$data\ECLS-K 98 BY.dta", clear
	
		keep /*

		ID variables
		*/ CHILDID PARENTID T1_ID T2_ID S1_ID S2_ID P1FIRKDG CREGION /*
	
	////////////////////////////
	// Demographic characteristics
	////////////////////////////
	
		Child characteristics - Two race variables
		*/ GENDER RACE R1_KAGE DOBMM DOBYY WKSESL WKPOVRTY P1PRIMPK P2CHPLAC P2CITIZN P1AGEENT  /*

	//////////////////////
	//	Outcome variables
	/////////////////////

		Teacher reported student abilities
			*/ T1CMPSEN-T1PRINT T1SORTS-T1STRAT T1OBSRV T1EXPLN T1CLSSFY /*
			*/ T2CMPSEN-T2PRINT T2SORTS-T2STRAT /*

		Behavioral outcomes
		*/ T1LEARN T1CONTRO T1INTERP T1EXTERN T1INTERN /*		
		*/ T2LEARN T2CONTRO T2INTERP T2EXTERN T2INTERN /*
		*/ P1LEARN P1CONTRO P1SOCIAL P1SADLON P1IMPULS /*
			
	
		Health outcomes
			*/  C1HEIGHT C1WEIGHT C1BMI									/*
			*/	P1WEIGHP P1WEIGHO P1TWINST P1COMPLI P1EARLY P1EARDAY	/*
			*/	P1WICMOM P1WICCHD P2COVER P2DENTIS						/*
			*/	P1HSCALE P1THERAP										/*
	
		Dates of completing survey
			*/ T1RSCOMM T1RSCODD T1RSCOYY A1COMPMM A1COMPDD A1COMPYY /*
				
		Weight
			*/ C1CPTW0 C2CPTW0 C1CW*
			
		gen NEW_COHORT = 0

		save "$path\1998 data raw", replace
			
		
*******************
*  Base year 2010
*******************	
	use "$data\ECLS-K 10 K-1", clear
		
		keep /*

		ID variables
		*/ CHILDID PARENTID T1_ID T2_ID S1_ID S2_ID X1FIRKDG X1REGION X1LOCALE  /*
			
	///////////////////////////////
	// Demographic characteristics
	////////////////////////////////

		Child characteristics - Two race variables (Parent interview/parent and school report)
		*/ X_CHSEX X_RACETH_R X1KAGE X1AGEENT X2KAGE X_DOBMM X_DOBYY X12SESL X2POVTY X12PRIMPK /*
		*/	P1ANYLNG P1ENGTOO P2BTHPLC P2CITIZN		/*

	//////////////////////
	//	Outcome variables
	/////////////////////	

		Teacher reported student ability
			*/  T1CMPSEN-T1PRINT T1SORTS-T1STRAT T1OBSRV T1EXPLN T1CLSSFY /*
			*/  T2CMPSEN-T2PRINT T2SORTS-T2STRAT /*
			
		Direct assessments
			*/ X1DCCSTOT X1NRSSCR /*
		
		Behavioral outcomes	
			*/ X1TCHCON X1TCHPER X1TCHEXT X1TCHINT X1TCHAPP /*
			*/ X2TCHCON X2TCHPER X2TCHEXT X2TCHINT X2TCHAPP /*
			*/ X1PRNAPP X1PRNCON X1PRNSOC X1PRNSAD X1PRNIMP /*
			
		Health outcomes
			*/  X1HEIGHT X1WEIGHT X1BMI									/*	
			*/	P1WEIGHP P1WEIGHO P1MULTIP P1DELCMP P1EARLY P1ERLYUN 	/*
			*/	P1WICMOM P1WICCHD P2COVER P2DENTIS						/*
			*/	P1HSCALE P2THERAP										/*

		Dates of completion
			*/ T1COMPMM T1COMPDD T1COMPYY	/*
				
			Weight - Using a different weight than Kids Today**
			*/ 	W1P0 W1T0 W12T0 W1C*
	
		//Rename variables to align with the 1998 cohort
		*************************************************
			rename X1FIRKDG 	P1FIRKDG
			rename X_CHSEX 		GENDER
			rename X_RACETH_R	RACE
			rename X1KAGE 		R1_KAGE
			rename X2KAGE 		R2_KAGE 
			rename X_DOBMM		DOBMM 
			rename X_DOBYY 		DOBYY  
			rename X2POVTY 		WKPOVRTY
			
			rename P1ENGTOO		P1ENGLIS
			rename P2BTHPLC		P2CHPLAC
			rename T1COMPMM 	T1RSCOMM
			rename T1COMPDD 	T1RSCODD
			rename T1COMPYY 	T1RSCOYY
			rename X1REGION		CREGION
			rename X1LOCALE		KURBAN
			
			rename X1TCHAPP T1LEARN
			rename X1TCHCON T1CONTRO
			rename X1TCHPER T1INTERP 
			rename X1TCHEXT T1EXTERN 
			rename X1TCHINT T1INTERN 

			rename X2TCHAPP T2LEARN
			rename X2TCHCON T2CONTRO
			rename X2TCHPER T2INTERP 
			rename X2TCHEXT T2EXTERN 
			rename X2TCHINT T2INTERN
			
			rename X1HEIGHT C1HEIGHT
			rename X1WEIGHT C1WEIGHT
			rename X1BMI 	C1BMI
	
		******************************************************************		

		//Recode variables as necessary to make appending possible		
			gen NEW_COHORT = 1 

			save "$path\2010 data raw", replace
	
	
		
	//Append the datasets together	
		use "$path\1998 data raw", clear
		
		append using "$path\2010 data raw"
	
		save "$path\Cross-Cohort raw", replace
	
	//Erase extra datasets
		erase "$path\1998 data raw.dta"
		erase "$path\2010 data raw.dta"
   
