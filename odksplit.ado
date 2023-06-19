*! version 4.0.0 Mehrab Ali 17jun2023


cap program drop odksplit
program  odksplit

version 9
	

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
	[DATEformat(string)]

	
	;
	#d cr


	
qui {
	
	loc dateformat = upper("`dateformat'")
	
	if mi("`dateformat'") & !inlist("`dateformat'", "MDY", "DMY") {
		n di as err "option dateformat() incorrectly specified. Only MDY or DMY are acceptable."
		ex 198
	}
	
	if mi("`dateformat'") loc `dateformat' = "MDY"
	
	
**# Survey sheet
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*	

	import excel using "`survey'", sheet("survey") firstrow  all `clear'
	drop if mi(type)
	cap rename value name
	replace name = trim(itrim(name))
	
	gen choicename = word(type, 2) if regexm(type, "select_")
	
	* List of date and datetime variables
	levelsof name if inlist(type, "date"), loc(dates) clean
	levelsof name if inlist(type, "datetime", "start", "end"), loc(datetimes) clean
	
	* Find languages
	loc x = 1
	lookfor label
	
	loc _langlist = r(varlist)	
	loc _lang_number = wordcount("`_langlist'")
	
	foreach var in `=r(varlist)' {
		loc lang`x' `"`= subinstr("`var'", "label", "", .)'"'
		
		** Remove HTML tags 
		replace `var' = ustrregexra(`var', "\<.*?\>" , "" ) if strpos(`var',"<")
		replace `var' = trim(itrim(`var'))
		loc ++x
	}
	
	
	
	* If multiple variables exist
	count if regexm(type, "select_multiple")==1
	if r(N)>0 	loc _runmultiple = 1
	else 		loc _runmultiple = 0
	
	if `_runmultiple' levelsof name if regexm(type, "select_multiple"), 	local(mvars) clean
	
	* If single variables exist
	count if regexm(type, "select_one")==1
	if r(N)>0 	loc _runsingle = 1
	else 		loc _runsingle = 0
	
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
		replace value = trim(itrim(value))
		destring value, gen(newvalue) force
		gsort choicename -value
		
		recode newvalue (else = .) if choicename==choicename[_n-1] & mi(newvalue[_n-1]) 
		drop if !regex(type, "select") | mi(newvalue)
		
		
		* Construct single value labels 	
		forval i=1/`_lang_number' {
			replace label`lang`i'' = subinstr(label`lang`i'', "`=char(13)'", " ", .)
			replace label`lang`i'' = subinstr(label`lang`i'', "`=char(10)'", " ", .)
			replace label`lang`i'' = trim(itrim(label`lang`i''))
			
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
			replace `language' = trim(itrim(`language'))
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
	
	if `_lang_number' > 1 {
		forval i=1/`_lang_number' {
			if `i'==1 lab lang `lang`i'', rename
			else lab lang `lang`i'', copy new
		}
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
					cap lab lang `lang`i''
					
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
						cap lab lang `lang`i''
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
						cap lab lang `lang`i''
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
	
	if `_lang_number' > 1 {	
		if mi("`label'") {
			n di as result _n "The data is labelled in `_lang_number' language(s). Run below command lines to change language as you want." 
			forval i=1/`_lang_number' {
				n di as smcl `" {stata  lab lang `lang`i''}"'
			}
		}
		
		else {
			n di as result _n "The data is labelled in `_lang_number' language(s). Run below command lines to change language as you want." 

			lab lang `label'
			lab lang default, rename
			n di as smcl "`label' is set as default label"
		}
	}
	
**# Change the formats of date and datetime variables

	

	if !mi("`dates'") {
		foreach date of loc dates {
			
			cap confirm var `date'
			
			if !_rc {
				count if mi(`date')
				if `=r(N)'<`=_N' {
					tempvar 	`date'_t
					gen double 	``date'_t' = date(`date', "`dateformat'"), after(`date')
					drop 		`date'
					gen 		`date' = ``date'_t', after(``date'_t')
					format 		`date' %td
					drop  		``date'_t'
				}
			}			
		}
	}

	loc datetimes =  `"`datetimes' submissiondate"'

	foreach datetime of loc datetimes {
		cap confirm var `datetime'
		
		if !_rc {
			tempvar 	`datetime'_t
			gen double 	``datetime'_t' = Clock(`datetime', "`dateformat'hms"), after(`datetime')
			drop 		`datetime'
			gen 		`datetime' = ``datetime'_t', after(``datetime'_t')
			format 		`datetime' %tC	
			drop  		``datetime'_t'
		}
	}

	
	
	if !mi("`save'") save  "`save'", replace

}
end


