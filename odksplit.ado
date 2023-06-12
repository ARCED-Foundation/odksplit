*! version 4.0.0 Mehrab Ali 07jun2023


cap program drop odksplit
program  odksplit

version 13
	

*  ----------------------------------------------------------------------------
*  1. Define syntax                                                            
*  ----------------------------------------------------------------------------
	
	#d ;
	syntax,
	Survey(string) 
	Data(string)
	[Label(string)]
	[Clear]
	[save(string)]

	
	;
	#d cr


	

**# Survey sheet
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*	

	import excel using "`survey'", sheet("survey") firstrow clear all
	drop if mi(type)
	cap rename value name
	gen choicename = word(type, 2) if regexm(type, "select_")
	
	
	* Find languages
	loc x = 1
	lookfor label
	
	loc _langlist = r(varlist)	
	loc _lang_number = wordcount("`_langlist'")
	
	foreach var in `=r(varlist)' {
		loc lang`x' `"`= subinstr("`var'", "label", "", .)'"'
		
		** Remove HTML tags 
		replace `var' = ustrregexra(`var', "\<.*?\>" , "" ) if strpos(`var',"<")
		loc ++x
	}
	
	
	
	* If multiple variables exist
	count if regexm(type, "select_multiple")==1
	if r(N)>0 loc _runmultiple = 1
	if `_runmultiple' levelsof name if regexm(type, "select_multiple"), 	local(mvars) clean
	
	* If single variables exist
	count if regexm(type, "select_one")==1
	if r(N)>0 loc _runsingle = 1

	if `_runsingle' {
		foreach var of loc singvars {
			levelsof choicename if name=="`var'", loc(_c_`var')
		}
	}
	
	* All variable list for variable labeling 	
	levelsof name if  !regexm(type, "begin group") & !regexm(type, "end group") ///
					& !regexm(type, "begin repeat") & !regexm(type, "end repeat") ///
					& type!="note", 	local(allvars) 	
	
	
	* Construct variable labels 
	foreach vars of loc allvars {
		loc i=1
		foreach language of loc _langlist {
			qui levelsof `language' if name=="`vars'",  loc(`vars'L`i')
			loc ++i
		}
	}
	
	
	
	
	
	tempfile _form 
	save	`_form'
	
	
	
	
**# Choices sheet 
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
	if `_runsingle' | `_runmultiple' {
		import excel using "`survey'", sheet("choices") firstrow clear all
		drop if mi(list_name)
		cap ren name value
		ren list_name choicename
		
		joinby choicename using `_form', unmatched(none) 
		destring value, gen(newvalue) force
		gsort choicename -value
		
		recode newvalue (else = .) if choicename==choicename[_n-1] & mi(newvalue[_n-1]) 
		drop if !regex(type, "select") | mi(newvalue)
		
		
		* Construct single value labels 	
		forval i=1/`_lang_number' {
			g lang_`i' = "lab def " + name + "_l`i' " + string(newvalue) + `" ""' + label`lang`i'' + `"", modify"'  if regexm(type, "select_one")
			levelsof lang_`i', loc(lab`i') 
			foreach lab of loc lab`i' {
				`lab'
			}
		}
		

		* Select one variable list
		levelsof name if regexm(type, "select_one"), local(singvars) clean
		
		
		tempfile _choices
		save	`_choices'
		
		tempfile labdo 
		label save using `labdo'
	}
	
	
	if `_runmultiple' {
		
		foreach language of loc _langlist {
			replace `language' = ustrregexra(`language', "\<.*?\>" , "" ) if strpos(`language',"<")
			replace `language' = subinstr(`language', "\$" , "", .) 
		}
		
		
		g mvalue  = subinstr(value, "-", "_", .) if regexm(type, "select_multiple")
		g mname = name + "_" + mvalue if regexm(type, "select_multiple")
		levelsof mname if regexm(type, "select_multiple"), loc(mvarlist) clean 

		* Construct multiple response labels 
		foreach vars of loc mvarlist {
			loc i=1
			foreach language of loc _langlist {
				qui levelsof `language' if mname=="`vars'",  loc(`vars'M`i')
				di `"``vars'M`i''"'
				loc ++i
			}
		}
	}
	
	
	
**# Open dataset
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*

	u "`data'", clear
	
	
	forval i=1/`_lang_number' {
		if `i'==1 lab lang `lang`i'', rename
		else lab lang `lang`i'', copy new
	}
	
	
	* Add variable labels
	n di as input "Starting labeling variables"

	qui foreach vars of loc allvars {
		
		cap conf var `vars'
		if !_rc loc allvarlist = "`vars'"
		else cap unab allvarlist : `vars'_*	
		if _rc n di as err "`vars' - not found"
		else {
			n di as result  "Labling variable - `vars'"
			
			foreach var of loc allvarlist {
 
				if mi(`"`=real("subinstr("`subinstr("`var'", "`vars'_", "", .)'", "_", "", .)")'"') continue
				forval i=1/`_lang_number' {
					lab lang `lang`i''
					
					if !mi(`"``vars'L`i''"') lab var `var' 	``vars'L`i''
					else  lab var `var' "`var'"
					notes `var': 	``vars'L`i''	
				}
			}
		}
	}
	
	n di as result _n "Completed labeling all variables" _n
	
	
	
	* Add labels to Single response variables 
	if `_runsingle' {
		n di as input "Starting labeling select_one variables"
		include `labdo'
		
		foreach vars of loc singvars {
			
			cap conf var `vars'
			if !_rc loc allvarlist = "`vars'"
			else cap unab allvarlist : `vars'_*	
			if _rc n di as err "`vars' - not found"
			else {
				n di as result  "Labeling values - `vars'"
				
				foreach var of loc allvarlist {
	 
					if mi(`"`=real("subinstr("`subinstr("`var'", "`vars'_", "", .)'", "_", "", .)")'"') continue
					forval i=1/`_lang_number' {
						lab lang `lang`i''
						cap lab val `var' `vars'_l`i'					
					}
				}
			}
		}
			
		n di as result "Completed labeling all value labels"
		
		
		
	}
	
	

	
	* Split and add labels to multiple response variables
	if `_runmultiple' {
		n di as input "Starting labeling select_multiple variables"
		
		qui foreach vars of loc mvarlist {
		
			cap conf var `vars'
			if !_rc loc allvarlist = "`vars'"
			else cap unab allvarlist : `vars'_*	
			if _rc n di as err "`vars' - not found"
			else {
				n di as result  "Labling multiple response variable - `vars'"
				
				foreach var of loc allvarlist {
					
					loc mainvarname = subinstr("`var'", "_", "", .)
					loc mainvalue	= subinstr("`var'", "`mainvarname'_", "", .)
					cap gen `var' = regexm(`mainvarname', "`mainvalue'"), after(`mainvarname')
					
					if mi(`"`=real("subinstr("`subinstr("`var'", "`vars'_", "", .)'", "_", "", .)")'"') continue
					forval i=1/`_lang_number' {
						lab lang `lang`i''
						di `"``vars'M`i''"'
						if !mi(`"``vars'M`i''"') lab var `var' 	``vars'M`i''
						else  lab var `var' "`var'"
						notes `var': 	``vars'M`i''
					}
				}
			}
		}	
		n di as result "Completed labeling multiple response variables"
	}
	
	if mi("`label'") {
		n di as result _n "The data is labelled in `_lang_number' language(s). Run below command lines to change language as you want." 
		forval i=1/`_lang_number' {
			n di as smcl `" {stata  lab lang `lang`i''}"'
		}
	}
	
	else {
		n di as result _n "The data is labelled in `_lang_number' language(s). Run below command lines to change language as you want." 
		forval i=1/`_lang_number' {
			n di as smcl `"{stata  lab lang `lang`i''}"'
			lab lang `label'
			lab lang default, rename
			n di as smcl "`label' is set as default label"
		}
	}
	
	if !mi(`save') save using "`save'", replace


end
