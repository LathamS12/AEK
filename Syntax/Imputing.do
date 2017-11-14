/***********************************************************************
* Author: Scott Latham
* Purpose: This file imputes missing data for the "Kids Today" project
* 			and constructs variables that need to be constructed AFTER
*			imputation
*
* Created: 8/7/2014
* Last modified: 5/31/2017
************************************************************************/

	use "${path}\Cross-Cohort Clean", clear
	pause on
		
	//Dropping missing observations for variables that are missing <100
		* Makes the imputation model more parsimonious    
		drop if BLACK ==.
		drop if MALE ==.
			

	#delimit ;

		gl impute "AGE_AUGK_MO MONTHS_K
					P1ANYLNG NO_ENG NOUS_BORN NONCITIZEN CITY RURAL
					SESQ1 SESQ2 SESQ3 SESQ4 SESQ1INT SESQ2INT SESQ3INT SESQ4INT SES_10 SES_90
					BAD_HEALTH UNDERWEIGHT OVERWEIGHT OBESE LOW_BWGHT PRETERM
					";

		gl reg "MALE MALEINT BLACK HISP ASIAN OTHER BLACKINT HISPINT ASIANINT OTHERINT MIDWEST SOUTH WEST WEIGHT WEIGHT2 SWEIGHT";

	#delimit cr

		sum $impute $impute2 $reg
		
	//Set and register the data
		mi set wide
		mi register imputed $impute
		mi register regular $reg

		set seed 30012 //Arbitrary seed value

		//Including all controls
			mi impute chained (regress) $impute = $reg, add(2) dots

			save "${path}\Cross-Cohort All Controls", replace


