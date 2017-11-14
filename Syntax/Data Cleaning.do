/***************************************************************
* Author: Scott Latham
* Purpose: This file cleans variables from ECLS-K and
*			ECLS-K 2010 for inclusion in the analysis of 
*			changes across ECLS cohorts
* 
* Created: 8/5/2013
* Last modified: 5/31/2017
*****************************************************************/

pause on
use "${path}\Cross-Cohort raw", clear

	//Sample selection 
		keep if P1FIRKDG == 1
	
	//Recode missing values
		order *ID
		recode CREGION-T2CMPST (-1=.a) (-7=.) (-8=.) (-9=.)

		label define year 0 "1998" 1 "2010"
		label values NEW_COHORT year

	////////////////
	// Demographics
	////////////////
		//Gender
			recode GENDER (2=0)
			rename GENDER MALE
			label variable MALE "Child is male"
				
			label define male 0 "Female" 1 "Male"
			label values MALE male

		//Age	
		
			//Date that teacher answered questionnaire
				gen SURV_MM = T1RSCOMM
				recode SURV_MM (8=0) (9=1) (10=2) (11=3) (12=4) ///
					(1=5) (2=6) (3=7) (4=8) (5=9) (6=10) (7=11)
				
				gen SURV_DD = (T1RSCODD-1)/30

				gen MONTHS_K =  SURV_MM+SURV_DD //Based on teacher report
				replace MONTHS_K =. if T1RSCOMM <8 & (T1RSCOYY == 1998 | T1RSCOYY==2010)
				label var MONTHS_K "Months in kindergarten at assessment"
			
			//Composite age (based on teacher survey dates and birthdate)
				gen MONTH = (DOBMM-1)/12
				gen AGE_AUGK = .
			
				replace AGE_AUGK = 1998.666-(DOBYY+MONTH) if NEW_COHORT==0
				replace AGE_AUGK = 2010.666-(DOBYY+MONTH) if NEW_COHORT==1

				gen AGE_AUGK_MO = AGE_AUGK*12	
				label variable AGE_AUGK_MO "Age on August 1st of kindergarten year (Months)"
					
		//Race 				
			gen ALL = 1
			label variable ALL "All students"

			gen WHITE = RACE==1
			replace WHITE =. if RACE >=.
			label variable WHITE "Child is white"
			
			gen BLACK = RACE == 2
			replace BLACK = . if RACE >=.
			label variable BLACK "Child is black"
			
			gen HISP = RACE == 3 | RACE ==4
			replace HISP = . if RACE >=.
			label variable HISP "Child is Hispanic"	
			
			gen ASIAN = RACE ==5
			replace ASIAN = . if RACE>=.
			label variable ASIAN "Child is Asian"
			
			gen OTHER = RACE >5
			replace OTHER = . if RACE >=.
			label variable OTHER "Child is not white/black/Hispanic"
			
			recode RACE (4=3) (5=4) (6/8 =5)
			label define race 1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Other"
			label values RACE race
		
		//SES
			egen SESQ98 = cut(WKSESL), group(5)
			egen SESQ10 = cut(X12SESL), group(5)

			replace SESQ98 = SESQ10 if SESQ98 >=.
			rename SESQ98 SESQ
			recode SESQ (0=1) (1=2) (2=3) (3=4) (4=5)
			
			label define quints 1 "Lowest quintile" 2 "2" 3 "3" 4 "4" 5 "Highest quintile"
			label values SESQ quints
			label variable SESQ "Income quintiles"
			
			tab SESQ, gen(SESQ)

			rename WKPOVRTY POVERTY
			recode POVERTY (2=0) (3=0)
			label var POVERTY "Student was below the poverty line"

			gen LOW_INC = SESQ1 ==1 | SESQ2 ==1
			replace LOW_INC = . if SESQ1 ==.
			
			
			//Create 90/10 vars
			gen SES = WKSESL if NEW_COHORT ==0
			replace SES = X12SESL if NEW_COHORT==1

			gen SES_10 =0 if SES !=.
			gen SES_90 =0 if SES !=. //Uses bandwidth of .15
			
			sum SES if NEW_COHORT==0, detail
				replace SES_10 = 1 if abs(SES - r(p10)) < .15 & NEW_COHORT==0
				replace SES_90 = 1 if abs(SES - r(p90)) < .15 & NEW_COHORT==0

			sum SES if NEW_COHORT==0, detail
				replace SES_10 = 1 if abs(SES - r(p10)) < .15 & NEW_COHORT==1
				replace SES_90 = 1 if abs(SES - r(p90)) < .15 & NEW_COHORT==1
				
				
		//Citizenship
			gen NOUS_BORN = P2CHPLAC ==2
			replace NOUS_BORN = . if P2CHPLAC ==.
			label var NOUS_BORN "Student was not born in U.S."

			gen NONCITIZEN = P2CITIZN ==2
			replace NONCITIZEN = . if P2CITIZN ==.
			label var NONCITIZEN "Child is not a U.S. citizen"		


		//Language spoken at home
			recode P1ANYLNG (2=0)
			
			gen NO_ENG = P1ENGLIS ==2
			replace NO_ENG =. if P1ENGLIS ==.
			label var NO_ENG "English not spoken in child's home"

		//Location

			recode KURBAN (2 11 12 13 =1) (3 4 21 22 23 =2) (5 6 31 32 33 =3) (7 41 42 43 = 4)
			label define kurb 1 "City" 2 "Suburb" 3 "Town" 4 "Rural"
			label values KURBAN kurb

			gen CITY = KURBAN ==1
			replace CITY = . if KURBAN ==.
			label var CITY "Child lives in a city"

			gen RURAL = KURBAN ==4
			replace RURAL =. if KURBAN ==.
			label var RURAL "Child lives in a rural area"
			
			tab CREGION, gen(r)
			replace r1 = . if CREGION ==.
			rename r1 NORTHEAST

			replace r2 = . if CREGION ==.
			rename r2 MIDWEST

			replace r3 = . if CREGION ==.
			rename r3 SOUTH

			replace r4 = . if CREGION ==.
			rename r4 WEST
	

	//////////////////
	//	Outcomes
	////////////////////
		
		* Health outcomes
		**********************

		  //Birth complications seem to be different across cohorts
		  //In 1998, multi births are linked to complications, in 2010 not so?
		.
		//Child weight
			gen UNDERWEIGHT = C1BMI < 14
			replace UNDERWEIGHT = . if C1BMI ==.
			label var UNDERWEIGHT "Child's BMI < 14"
			
			gen OVERWEIGHT = C1BMI >=17
			replace OVERWEIGHT = . if C1BMI ==.
			label var OVERWEIGHT "Child's BMI >= 17"
			
			gen OBESE = C1BMI >=18
			replace OBESE = . if C1BMI ==.
			label var OBESE "Child's BMI >= 18"
			
			gen SEV_OBESE = C1BMI >=18.5
			replace SEV_OBESE = . if C1BMI ==.
			label var SEV_OBESE "Child's BMI >= 18.5"
			
		//Birthweight
			gen P1BWGHT_O = (P1WEIGHP*16) + P1WEIGHO
			gen P1BWGHT_G = P1BWGHT_O * 28.3495
			
			gen LOW_BWGHT = P1BWGHT_G < 2500
			replace LOW_BWGHT = . if P1BWGHT_G ==.
			label var LOW_BWGHT "Birth weight below 2500g"
			
			gen VLOW_BWGHT = P1BWGHT_G < 1500
			replace LOW_BWGHT = . if P1BWGHT_G ==.
			label var VLOW_BWGHT "Birth weight below 1500g"
		
		//Multiple birth status
			gen MULTIPLE = P1TWINST <9
			replace MULTIPLE = 1 if P1MULTIP >1 & P1MULTIP <.
			replace MULTIPLE = . if P1TWINST ==. & NEW_COHORT ==0
			replace MULTIPLE = . if P1MULTIP ==. & NEW_COHORT ==1
			label var MULTIPLE "Child is part of multiple birth (twin or more)"
				
		//Preterm birth
			gen WKS_PRET = P1EARLY if P1EARDAY ==1
			replace WKS_PRET = P1EARLY/7 if P1EARDAY ==2
			replace WKS_PRET = 0 if P1EARDAY ==.a
			
			replace WKS_PRET = P1EARLY if P1ERLYUN ==1
			replace WKS_PRET = P1EARLY/7 if P1ERLYUN ==2
			replace WKS_PRET = 0 if P1ERLYUN ==.a
			
			gen PRETERM = WKS_PRET >=3 & WKS_PRET <.
			replace PRETERM = . if WKS_PRET ==.
			label var PRETERM "Child born 37 weeks or earlier"
			
			gen V_PRETERM = WKS_PRET >=7 & WKS_PRET <.
			replace V_PRETERM = . if WKS_PRET ==.
			label var V_PRETERM "Child born 33 weeks or earlier"
			
			gen E_PRETERM = WKS_PRET >=12 & WKS_PRET <.
			replace E_PRETERM = . if WKS_PRET ==.
			label var E_PRETERM "Child born 28 weeks or earlier"
			
		//Child health
			gen BAD_HEALTH = P1HSCALE == 4 | P1HSCALE ==5 if P1HSCALE !=.
			label var BAD_HEALTH "Parent reported child health as 'fair' or 'poor'"
			
		//Child received services before K
			gen PTHERAP = P1THERAP if NEW_COHORT ==0
			replace PTHERAP = P2THERAP if NEW_COHORT ==1
			label var PTHERAP "Child received therapy or other services before K"
			
		//WIC receipt
			recode P1WICMOM P1WICCHD P2COVER (2=0)
			
			gen DENTIST_MT1 = P2DENTIS >=4
			replace DENTIST_MT1 = . if P2DENTIS >=.
			label var DENTIST_MT1 "Last visit to dentist was more than 1 year ago"
			
		
		* Cognitive outcomes
		*********************
			loc abilities = "CMPSEN STORY LETTER PRDCT READS WRITE PRINT SORTS ORDER RELAT SOLVE GRAPH MEASU STRAT"
			
			//Label and standardize proficiency variables
				foreach x in 1 2	{
					label var T`x'CMPSEN	"Uses complex sentence structures"
					label var T`x'STORY 	"Understands and interprets stories"
					label var T`x'LETTER	"Easily names upper/lowercase letters"
					label var T`x'PRDCT		"Predicts what will happen next in stories"
					label var T`x'READS		"Reads simple books independently"
					label var T`x'WRITE		"Demonstrates early writing behaviors"
					label var T`x'PRINT		"Understands conventions of print"
					label var T`x'SORTS		"Sorts/classifies items by different rules"
					label var T`x'ORDER		"Orders groups of objects"
					label var T`x'RELAT		"Understands relative quantities"
					label var T`x'SOLVE		"Solves problems involving numbers"
					label var T`x'GRAPH		"Demonstrates understanding of graphs"
					label var T`x'MEASU		"Uses measuring instruments accurately"
					label var T`x'STRAT		"Uses multiple strategies to solve math problems"
					
					foreach i in `abilities'	{
						
						//Standardize outcomes
							loc lab: variable label T`x'`i' 
							egen T`x'`i'z = std(T`x'`i')
							label var T`x'`i'z "`lab'"
						
						//Generate bounded variables
							gen T`x'`i'_b = T1`i' 
							recode T`x'`i'_b (6 7 = 1)
							label var T`x'`i'_b "T`x'`i' bounded"

							recode T`x'`i'(6 7 =.) // NA was coded differently across waves	
						
						} //close i loop
				} //close x loop

			//Overall proficiency (reading, math)
			
				//Fall K
					egen READ1 = rowmean(T1CMPSEN T1STORY T1LETTER T1PRDCT T1READS T1WRITE T1PRINT)
					label var READ1 "Average literacy proficiency"

					egen MATH1 = rowmean(T1SORTS T1ORDER T1RELAT T1SOLVE T1GRAPH T1MEASU T1STRAT)
					label var MATH1 "Average math proficiency"

				
			//Construct individual high and low proficiency indicators (bounded and unbounded)
				foreach x in `abilities'	{
				
					forvalues i = 1/3	{
						//Main results
							gen 	`x'_LO`i' = T1`x' <=`i'
							replace `x'_LO`i' = . if T1`x' >=.
							label variable `x'_LO`i' "Child has low proficiency in  `x'"

							gen 	`x'_HI`i' = T1`x' >=6-`i'
							replace `x'_HI`i' = . if T1`x' >=.
							label variable `x'_HI`i' "Child has high proficiency in `x'"

						//Bounded
							gen 	`x'_LO`i'_b = T1`x'_b  <=`i'
							replace `x'_LO`i'_b = . if T1`x'_b >=.
							label variable `x'_LO`i'_b "Child has low proficiency in  `x' (bounded)"
						
							gen 	`x'_HI`i'_b = T1`x'_b  >=6-`i'
							replace `x'_HI`i'_b = . if T1`x'_b >=.
							label variable `x'_HI`i'_b "Child has high proficiency in `x' (bounded)"
							
					} //closes i loop
				} // closes x loop

				drop T1OBSRV T1EXPLN T1CLSSFY  // These weren't collected in the spring
		

			//Aggregated high/low proficiency variables (bounded and unbounded)

				egen read_num = rownonmiss(CMPSEN_HI2 STORY_HI2 LETTER_HI2 PRDCT_HI2 READS_HI2 WRITE_HI2 PRINT_HI2)

				forvalues i = 1/3	{
				
					egen r_hi`i' = rowtotal(CMPSEN_HI`i' STORY_HI`i' LETTER_HI`i' PRDCT_HI`i' READS_HI`i' WRITE_HI`i' PRINT_HI`i')
						gen READ_HI`i' = r_hi`i'/read_num >= .5 & read_num != 0
						replace READ_HI`i' = . if read_num ==0
						label var READ_HI`i' "Proficient in at least half literacy skills" 
					
					egen r_lo`i' = rowtotal(CMPSEN_LO`i' STORY_LO`i' LETTER_LO`i' PRDCT_LO`i' READS_LO`i' WRITE_LO`i' PRINT_LO`i')
						gen READ_LO`i' = r_lo`i'/read_num >= .5 & read_num != 0
						replace READ_LO`i' = . if read_num ==0
						label var READ_LO`i' "Not proficient in at least half literacy skills" 
						
				}
					
				egen math_num = rownonmiss(SORTS_HI2 ORDER_HI2 RELAT_HI2 SOLVE_HI2 GRAPH_HI2 MEASU_HI2 STRAT_HI2)

				forvalues i = 1/3	{
			
					egen m_hi`i'= rowtotal(SORTS_HI`i' ORDER_HI`i' RELAT_HI`i' SOLVE_HI`i' GRAPH_HI`i' MEASU_HI`i' STRAT_HI`i')	
						gen MATH_HI`i' = m_hi`i'/math_num >= .5 & math_num != 0
						replace MATH_HI`i' = . if math_num ==0
						label var MATH_HI`i' "Proficient in at least half math skills" 

					egen m_lo`i'= rowtotal(SORTS_LO`i' ORDER_LO`i' RELAT_LO`i' SOLVE_LO`i' GRAPH_LO`i' MEASU_LO`i' STRAT_LO`i')
						gen MATH_LO`i' = m_lo`i'/math_num >= .5 & math_num != 0
						replace MATH_LO`i' = . if math_num ==0
						label var MATH_LO`i' "Not proficient in at least half math skills" 
				}
				
			//Basic and advanced skills (Rule was >50% students were rated a 1 or 2 in fall of 1998)

				*Using rule that >50% students were rated a 1 or 2 in fall of 1998)
					egen READ_BAS1 = rowmean(T1CMPSEN T1STORY T1LETTER T1PRDCT) //Unbounded
					label var READ_BAS1 "Easy reading skills (rule based)"

					egen READ_ADV1 = rowmean(T1READS T1WRITE T1PRINT) 
					label var READ_ADV1 "Hard reading skills (rule based)"				

					
					egen MATH_BAS1 = rowmean(T1SORTS T1ORDER T1GRAPH) //Unbounded
					label var MATH_BAS1 "Easy math skills (rule based)"
				
					egen MATH_ADV1= rowmean(T1SOLVE T1MEASU T1RELAT T1STRAT)
					label var MATH_ADV1 "Hard math skills (rule based)"	
					
				*As defined by factor analysis	
					egen READ_BAS2 = rowmean(T1CMPSEN T1STORY T1PRDCT) //Unbounded
					label var READ_BAS2 "Easy reading skills (factor analysis)"

					egen READ_ADV2 = rowmean(T1READS T1WRITE T1PRINT) 
					label var READ_ADV2 "Hard reading skills (factor analysis)"		
					

					egen MATH_BAS2 = rowmean(T1SORTS T1ORDER T1RELAT) //Unbounded
					label var MATH_BAS2 "Easy math skills (factor analysis)"
				
					egen MATH_ADV2 = rowmean(T1SOLVE T1GRAPH T1MEASU T1STRAT)
					label var MATH_ADV2 "Hard math skills (factor analysis)"

			//Standardize outcomes

				foreach x in READ1 MATH1   {
					loc lab: variable label `x'
					egen `x'z = std(`x')
					label var `x'z "lab"
				}

				foreach x in READ_BAS1 READ_BAS2 READ_ADV1 READ_ADV2 MATH_BAS1 MATH_BAS2 MATH_ADV1 MATH_ADV2 {
					loc lab: variable label `x'
					egen `x'z = std(`x')
					label var `x'z "lab"
				}
				
		* Behavioral outcomes
		***********************
			label var T1LEARN  "Approaches to learning"
			label var T1EXTERN "Externalizing behavior"
			label var T1INTERN "Internalizing behavior"
			label var T1INTERP "Interpersonal behavior"
			label var T1CONTRO "Self-control"
				
			//Dichotomize behavioral outcomes
				foreach x in INTERN EXTERN LEARN INTERP CONTRO	{
					
					sum T1`x' if NEW_COHORT ==0 //Get values in 1998
						loc plus1 = r(mean) + r(sd) 
						loc plus1_5 = r(mean) + (1.5 * r(sd))
						loc minus1 = r(mean) - r(sd)
					
					gen `x'_HI1 = T1`x' >= `plus1'
					replace `x'_HI1 = . if T1`x' ==.
					label var `x'_HI1 "1 SD above 1998 mean"
				
					gen `x'_HI2 = T1`x' >= `plus1_5'
					replace `x'_HI2 = . if T1`x' ==.
					label var `x'_HI2 "1.5 SD above 1998 mean"
					
					gen `x'_LO1 = T1`x' <= `minus1'
					replace `x'_LO1 = . if T1`x' ==.
					label var `x'_LO1 "1 SD below 1998 mean" 
					
					egen T1`x'z = std(T1`x')
					
				}
				
	
	//////////////////
	//Interactions		
	//////////////////
	
		gen MALEINT = MALE*NEW_COHORT
		label var MALEINT "Child is male in the 2010 cohort"
			
		foreach i in BLACK HISP ASIAN OTHER	{
			gen `i'INT = `i' ==1 & NEW_COHORT ==1
			replace `i'INT =. if `i' ==.
			label variable `i'INT "Child is `i' and in the 2010 cohort"
		}	

		forvalues i = 1/5	{
			gen SESQ`i'INT = SESQ`i' ==1 & NEW_COHORT ==1
			replace SESQ`i'INT = . if SESQ`i'==.
			label variable SESQ`i'INT "Student was in quintile `i' in 2010 cohort"
		}	
		
	

		foreach x in BLACK HISP ASIAN OTHER	{	
			gen `x'_LOWSES = LOW_INC*`x'
			gen `x'_LOWSES10 = `x'_LOWSES * NEW_COHORT
		} // closes x loop
			
		
	//Sampling weight
		gen WEIGHT = C1CW0 if NEW_COHORT==0
		replace WEIGHT = W1C0 if NEW_COHORT==1

		gen WEIGHT2 = C1CPTW0 if NEW_COHORT==0
		replace WEIGHT2 = W1T0 if NEW_COHORT==1
		
		gen SWEIGHT = C2CPTW0 if NEW_COHORT ==0
		replace SWEIGHT = W12T0 if NEW_COHORT ==1


		
save "${path}\Cross-Cohort Clean", replace
