/***************************************************************
* Author: Scott Latham
* Purpose: This file analyzes variables from ECLS-K and
*			ECLS-K 2010 to determine whether kindergarten knowledge
*			has changed across cohorts
* 
* Creates: 
*
* Created: 8/6/2013
* Last modified: 5/29/2017

********************************************************/

	pause on
	use "${path}\Cross-Cohort All Controls", clear //Imputed using all control variables
	
	mi svyset [pw=WEIGHT]
	
	/////////////////////////////////
	//  Setting up macros
	/////////////////////////////////
		
		//Outcomes
			gl cognitive 	"READ_HI2 READ_LO2 MATH_HI2 MATH_LO2"
					
			gl bad_behav1 	"CONTRO_LO1 INTERP_LO1 EXTERN_HI1 INTERN_HI1 LEARN_LO1"

			gl abilities    "T1CMPSEN T1STORY T1LETTER T1PRDCT T1READS T1WRITE T1PRINT T1SORTS T1ORDER T1RELAT T1SOLVE T1GRAPH T1MEASU T1STRAT"

			gl health		"BAD_HEALTH UNDERWEIGHT OVERWEIGHT OBESE LOW_BWGHT PRETERM "

			gl all_dvs	" CONTRO_LO1 INTERP_LO1 EXTERN_HI1 INTERN_HI1 LEARN_LO1 READ_HI2 READ_LO2 MATH_HI2 MATH_LO2 BAD_HEALTH UNDERWEIGHT OVERWEIGHT OBESE LOW_BWGHT PRETERM"
		
		//Controls
			gl age		"AGE_AUGK_MO MONTHS_K " 
			gl race	 	"BLACK HISP ASIAN OTHER "
			gl ses		"SESQ1 SESQ2 SESQ3 SESQ4 "
			gl lang 	"P1ANYLNG NO_ENG NOUS_BORN NONCITIZEN" 
			gl region 	"CITY RURAL MIDWEST SOUTH WEST"
			
		#delimit ;
			gl tchars "B1TMALE B1TAGE B1HISP B1ASIAN B1BLACK B1OTHER B1TGRAD B1YRSKIN B1YRSCH 
				B1EARLY B1ELEM B1DEVLP B1MTHDRD B1MTHDMA B1MTHDSC B1ELEMCT B1ERLYCT B1SPECED B1ESL"; 
		#delimit cr	
	
			gl controls "$cent $parbeliefs2 $activities $comp $tchars "
	
		//Interactions
			gl r_ints	"BLACKINT HISPINT ASIANINT OTHERINT "
			gl s_ints	"SESQ1INT SESQ2INT SESQ3INT SESQ4INT "	
		
			
		//Parameters
			gl cluster "T1_ID"

		//Sample			
			reg $health [pw=WEIGHT] 
			gen samp = e(sample) ==1

	
		//Table 1 - health outcomes
			capture program drop descrip	
			program descrip	
				args vars format title
			
				tempname desc
				tempfile table
				postfile `desc' str75 (var) str8(m1998 m2010) str4(star) using `table'	
				
				foreach x in `vars'	{
					
					mi estimate: svy: mean `x' if NEW_COHORT ==0 & samp ==1

						matrix m = e(b_mi)
						matrix var = e(V_mi)
						
						loc `x'98m = m[1,1]
						loc `x'98se = sqrt(var[1,1])

					mi estimate: svy: mean `x' if NEW_COHORT ==1 & samp ==1

						matrix m = e(b_mi)
						matrix var = e(V_mi)
						
						loc `x'10m = m[1,1]
						loc `x'10se = sqrt(var[1,1])
						
					loc diff`x' = ``x'10m' - ``x'98m'					
					loc t`x' = `diff`x'' / ``x'98se' //Calculate t score

					loc star ""
						if abs(`t`x'') 	>= 1.645	loc star = "+"
						if abs(`t`x'')	>= 1.96		loc star = "*"
						if abs(`t`x'') 	>= 2.57		loc star = "**"
						if abs(`t`x'') 	>= 3.17		loc star = "***"
						
					foreach val in `x'98m `x'10m `x'98se `x'10se	{
						loc `val'_r: di `format' (``val'' *100) //Create rounded values
					}

					post `desc' ("`x'") ("``x'98m_r'") 			("``x'10m_r'") 			("`star'")
				
				} // close x loop
				
				postclose `desc'

				preserve
					use `table', clear		
					export excel using "Z:\save here\Scott Latham\America's entering kindergarteners\Tables/`title'.xls", replace
				restore

			end //Ends program "descrip' 

		descrip 	"$health"			"%3.1f"		"Health outcomes"
		

		//Table 2 - descriptives by race
		capture program drop descrip_by_race	
		program descrip_by_race	
			args vars format title
		
			tempname desc
			tempfile table
			postfile `desc' str75(var) str7(w98 w10 sw b98 b10 sb h98 h10 sh) using `table'	
			
			post `desc' ("") ("White98") ("White10") ("") ("Black98") ("Black10") ("") ("Hisp98") ("Hisp10") ("")
			
			foreach x in `vars'	{
				
				foreach race in WHITE BLACK HISP	{
				
					mi estimate: svy: mean `x' if NEW_COHORT ==0 & samp ==1 & `race'==1
						matrix m = e(b_mi)
						matrix var = e(V_mi)
						loc `x'98m_`race' = round((m[1,1]*100), .1)
						loc n98`race' = e(N)
						
					mi estimate: svy: mean `x' if NEW_COHORT ==1 & samp ==1 & `race'==1
						matrix m = e(b_mi)
						matrix var = e(V_mi)
						loc `x'10m_`race' = round((m[1,1]*100), .1)
						loc n10`race' = e(N)
						
					ttest `x' if samp==1 & `race'==1, by(NEW_COHORT)
					
					loc star`race' ""
						if `r(p)' < .1		loc star`race' = "+"
						if `r(p)' <.05		loc star`race' = "*"
						if `r(p)' <.01		loc star`race' = "**"
						if `r(p)' <.001		loc star`race' = "***"
					
				} // close race loop
				
				post `desc' ("`x'") 	("``x'98m_WHITE'") ("``x'10m_WHITE'") ("`starWHITE'") ("``x'98m_BLACK'")  ("``x'10m_BLACK'") ("`starBLACK'") ("``x'98m_HISP'") ("``x'10m_HISP'") ("`starHISP'")

			} // close x loop
			
			post `desc' ("") ("`n98WHITE'") ("`n10WHITE'") ("") ("`n98BLACK'") ("`n10BLACK'") ("") ("`n98HISP'") ("`n10HISP'") ("")
			
			
			postclose `desc'

			preserve
				use `table', clear		
				export excel using "Z:\save here\Scott Latham\America's entering kindergarteners\Tables/`title' - descriptives by race.xls", replace
			restore

		end //Ends program "descrip_comp' 
		
		descrip_by_race	"$all_dvs"			"%3.2f"		"All school readiness outcomes"
		descrip_by_race	"$bad_behav1"		"%3.2f"		"All school readiness outcomes"
		
	//Table 3 - descriptives by income
		capture program drop descrip_by_inc	
		program descrip_by_inc	
			args vars format title
		
			tempname desc
			tempfile table
			postfile `desc' str75(var) str7(h98 h10 hs  l98 l10 ls) using `table'	
			
			post `desc' ("") ("High98") ("High10") ("") ("Low98") ("Low10") ("") 
			
			foreach x in `vars'	{
				
				foreach inc in SES_10 SES_90	{
				
					mi estimate: svy: mean `x' if NEW_COHORT ==0 & samp ==1 & `inc'==1
						matrix m = e(b_mi)
						loc `x'98m_`inc' = round((m[1,1]*100), .1)
						loc n98`inc' = e(N)
						
					mi estimate: svy: mean `x' if NEW_COHORT ==1 & samp ==1 & `inc'==1
						matrix m = e(b_mi)
						loc `x'10m_`inc' = round((m[1,1]*100), .1)
						loc n10`inc' = e(N)
				
					ttest `x' if samp==1 & `inc'==1, by(NEW_COHORT)
					
					loc star`inc' ""
						if `r(p)' < .1		loc star`inc' = "+"
						if `r(p)' <.05		loc star`inc' = "*"
						if `r(p)' <.01		loc star`inc' = "**"
						if `r(p)' <.001		loc star`inc' = "***"
						
						
				} // close race loop
				
				post `desc' ("`x'") ("``x'98m_SES_90'")   ("``x'10m_SES_90'") ("`starSES_90'") ("``x'98m_SES_10'")  ("``x'10m_SES_10'")  ("`starSES_10'") 

			} // close x loop
			
			post `desc' ("") ("`n98SES_90'") ("`n10SES_90'") ("") ("`n98SES_10'") ("`n10SES_10'") ("")
			
			
			postclose `desc'

			preserve
				use `table', clear		
				export excel using "Z:\save here\Scott Latham\America's entering kindergarteners\Tables/`title' - descriptives by income.xls", replace
			restore

		end //Ends program "descrip_by_inc' 
		
		descrip_by_inc	"$all_dvs"			"%3.2f"		"All school readiness outcomes"
		descrip_by_inc	"$bad_behav1"		"%3.2f"		"Behavior"
		
	
	
	//Table 4 - gaps by race/ethnicity & income
		capture program drop gaps_by_inc
		program gaps_by_inc
			args vars format title
		
			tempname desc
			tempfile table
			postfile `desc' str75 (var) m1998_lo m1998_hi diff98 m2010_lo m2010_hi diff2010 diff_in_diff str4(stars) using `table'	
			
			foreach x in `vars'	{
				
				mi estimate: svy: mean `x' if NEW_COHORT ==0 & SES_10 ==1 & samp ==1	
					matrix m = e(b_mi)
					matrix var = e(V_mi)
					loc `x'98m_lo = m[1,1]
					loc `x'98se_lo = sqrt(var[1,1]) 
					
				mi estimate: svy: mean `x' if NEW_COHORT ==1 & SES_10 ==1 & samp ==1
					matrix m = e(b_mi)
					matrix var = e(V_mi)
					loc `x'10m_lo = m[1,1]
					
					
				mi estimate: svy: mean `x' if NEW_COHORT ==0 & SES_90 ==1 & samp ==1
					matrix m = e(b_mi)
					matrix var = e(V_mi)				
					loc `x'98m_hi = m[1,1]
					loc `x'98se_hi = sqrt(var[1,1])
					
				mi estimate: svy: mean `x' if NEW_COHORT ==1 & SES_90 ==1 & samp ==1
					matrix m = e(b_mi)
					matrix var = e(V_mi)
					loc `x'10m_hi = m[1,1]
			
			
				loc diff98 = ``x'98m_hi' - ``x'98m_lo'
				loc diff10 = ``x'10m_hi' - ``x'10m_lo'
				loc diff_diff = `diff10' - `diff98'
				
				loc poolse = (``x'98se_lo' + ``x'98se_hi') / 2 //Pooling SE between high and low income children	
				loc tpool = `diff_diff' / `poolse'
				
				loc star ""
					if abs(`tpool') 	>= 1.645	loc star = "+"
					if abs(`tpool')		>= 1.96		loc star = "*"
					if abs(`tpool') 	>= 2.57		loc star = "**"
					if abs(`tpool') 	>= 3.17		loc star = "***"
						
					foreach val in `x'98m_lo `x'10m_lo `x'98m_hi `x'10m_hi diff98 diff10 diff_diff	{
						loc `val'_r: di `format' (``val'' * 100) //Create rounded values
					}

				post `desc' ("`x'") (``x'98m_lo_r') (``x'98m_hi_r') (`diff98_r')  (``x'10m_lo_r') (``x'10m_hi_r') (`diff10_r') (`diff_diff_r') ("`star'")
			
			} // close x loop
			
			postclose `desc'

			preserve
				use `table', clear		
				export excel using "Z:\save here\Scott Latham\America's entering kindergarteners\Tables/`title' 2.xls", replace
			restore

		end //Ends program "desc_by_inc"
		
		gaps_by_inc 	"$health"		"%3.1f"		"Health descriptives by income"
		gaps_by_inc 	"$bad_behav1"	"%3.2f"		"Behavior"
		
		
		
	//Race-based gaps
		capture program drop gaps_by_race	
		program gaps_by_race	
			args vars format title
		
			tempname desc
			tempfile table
			postfile `desc' str75(var) str6(bw98 bw10 bwdiff bwstars hw98 hw10 hwdiff hwstars) using `table'	
			
			foreach x in `vars'	{
				
				foreach race in WHITE BLACK HISP	{
				
					mi estimate: svy: mean `x' if NEW_COHORT ==0 & samp ==1 & `race'==1
						matrix m = e(b_mi)
						matrix var = e(V_mi)
						loc `x'98m_`race' = m[1,1]
						loc `x'98se_`race' = sqrt(var[1,1]) 
					
					mi estimate: svy: mean `x' if NEW_COHORT ==1 & samp ==1 & `race'==1
						matrix m = e(b_mi)
						matrix var = e(V_mi)
						loc `x'10m_`race' = m[1,1]
				
				}
				
				foreach gap in bw hw	{
					if "`gap'" =="bw"	loc comp_race = "BLACK"
					if "`gap'" =="hw"	loc comp_race = "HISP"
					
					loc `gap'98 = ``x'98m_WHITE' - ``x'98m_`comp_race''
					loc `gap'10 = ``x'10m_WHITE' - ``x'10m_`comp_race''
					loc `gap'diff = ``gap'10' - ``gap'98'
					
					loc `gap'_poolse = (``x'98se_WHITE' + ``x'98se_`comp_race'') / 2		
					loc `gap'_t = ``gap'diff' / ``gap'_poolse'
				
					loc `gap'star ""
						if abs(``gap'_t') 	>= 1.645	loc `gap'star = "+"
						if abs(``gap'_t')	>= 1.96		loc `gap'star = "*"
						if abs(``gap'_t') 	>= 2.57		loc `gap'star = "**"
						if abs(``gap'_t') 	>= 3.17		loc `gap'star = "***"
					
				}		
	
				foreach val in bw98 bw10 bwdiff hw98 hw10 hwdiff	{
					loc `val'_r: di `format' (``val'' * 100) //Create rounded values
				}

				post `desc' ("`x'") 	("`bw98_r'")  ("`bw10_r'")	("`bwdiff_r'") ("`bwstar'")  ("`hw98_r'") 	("`hw10_r'") ("`hwdiff_r'") ("`hwstar'")

			} // close x loop
			
			postclose `desc'

			preserve
				use `table', clear		
				export excel using "Z:\save here\Scott Latham\America's entering kindergarteners\Tables/`title' - gaps by race.xls", replace
			restore

		end //Ends program "descrip_comp' 
		
		gaps_by_race	"$bad_behav1 $cognitive  $health"	"%3.2f"		"All school readiness outcomes"
	
	
	//Executive function
	
		capture program drop EF_race	
		program EF_race
			args vars format
		
			tempname desc
			tempfile table
			postfile `desc' str75 (var) str7(all sd white black blackgap hisp hispgap) using `table'	
			
			foreach x in `vars'	{
			
				sum `x' if samp ==1 [aw=WEIGHT2]
					loc `x'mean: di `format' r(mean)
					loc `x'sd: di `format' r(sd)
					
				sum `x' if samp ==1 & WHITE==1 [aw=WEIGHT2]
					loc `x'white: di `format' r(mean)
					
				sum `x' if samp ==1 & BLACK==1 [aw=WEIGHT2]
					loc `x'black: di `format' r(mean)
	
				sum `x' if samp ==1 & HISP==1 [aw=WEIGHT2]
					loc `x'hisp: di `format' r(mean)
				
				loc `x'bgap = round((``x'white' - ``x'black') / ``x'sd', .01)
				loc `x'hgap = round((``x'white' - ``x'hisp') / ``x'sd', .01)
				

				post `desc' ("`x'") ("``x'mean'") (`"(``x'sd')"') ("``x'white'") ("``x'black'") ("``x'bgap'")  ("``x'hisp'") ("``x'hgap'")

			
			} // close x loop
			
			postclose `desc'

			preserve
				use `table', clear		
				export excel using "Z:\save here\Scott Latham\America's entering kindergarteners\Tables/EF vars - by race.xls", replace
			restore

		end //Ends program "EF_race" 
		
		EF_race 	"X1NRSSCR X1DCCSTOT"	"%4.2f"
		
		
		capture program drop EF_inc	
		program EF_inc	
			args vars format
		
			tempname desc
			tempfile table
			postfile `desc' str75 (var) str7(all sd high low gap) using `table'	
			
			foreach x in `vars'	{
			
				sum `x' if samp ==1 [aw=WEIGHT2]
					loc `x'mean: di `format' r(mean)
					loc `x'sd: di `format' r(sd)
					
				sum `x' if samp ==1 & SES_90==1 [aw=WEIGHT2]
					loc `x'high: di `format' r(mean)
				
				sum `x' if samp ==1 & SES_10==1 [aw=WEIGHT2]
					loc `x'low: di `format' r(mean)
					
				loc `x'gap = round((``x'high' - ``x'low') / ``x'sd', .01)

				post `desc' ("`x'") ("``x'mean'") (`"(``x'sd')"') ("``x'high'") ("``x'low'") ("``x'gap'")  
			
			} // close x loop
			
			postclose `desc'

			preserve
				use `table', clear		
				export excel using "Z:\save here\Scott Latham\America's entering kindergarteners\Tables/EF vars - by income.xls", replace
			restore

		end //Ends program "EF_inc" 
		
		EF_inc 	"X1NRSSCR X1DCCSTOT"	"%4.2f"

		
		/*	
	//Changes in descriptives over time by SES
	
		capture program drop descrip_by_inc	
		program descrip_by_inc	
			args vars format title
		
			tempname desc
			tempfile table
			postfile `desc' str75 (var) m1998_lo m1998_hi diff98 m2010_lo m2010_hi diff2010 using `table'	
			
			foreach x in `vars'	{
				
				sum `x' if NEW_COHORT ==0 & SESQ1 ==1 & samp ==1 [aw=WEIGHT2]
				loc `x'1998m_lo: di `format' r(mean)

				sum `x' if NEW_COHORT ==1 & SESQ1 ==1 & samp ==1 [aw=WEIGHT2]
				loc `x'2010m_lo: di `format' r(mean)
				
				sum `x' if NEW_COHORT ==0 & SESQ5 ==1 & samp ==1 [aw=WEIGHT2]
				loc `x'1998m_hi: di `format' r(mean)

				sum `x' if NEW_COHORT ==1 & SESQ5 ==1 & samp ==1 [aw=WEIGHT2]
				loc `x'2010m_hi: di `format' r(mean)
			
				loc diff98 = ``x'1998m_hi' - ``x'1998m_lo'
				loc diff10 = ``x'2010m_hi' - ``x'2010m_lo'

				post `desc' ("`x'") (``x'1998m_lo') (``x'1998m_hi') (`diff98')  (``x'2010m_lo') (``x'2010m_hi') (`diff10')
			
			} // close x loop
			
			postclose `desc'

			preserve
				use `table', clear		
				export excel using "Z:\save here\Scott Latham\America's entering kindergarteners\Tables/`title'.xls", replace
			restore

		end //Ends program "descrip' 
		
		descrip_by_inc 	"$health"	"%4.2f"		"Health descriptives by income"

		