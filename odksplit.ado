*! version 3.1.0 Mehrab Ali 17dec2021



** To dos:
* 1. Add return list 
* 2. Make faster - more use of wildcard to copy labels - multiple response 
* 3. Explore if while loop makes it faster




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
	[Multiple]
	[SINGle]
	[VARlabel]
	[Wide]
	[Long]
	
	;
	#d cr

* Confirm the language	
	if ("`label'" != "") {
		local newlabel  label`label'
	}

	* If no language, use the label column
	else if ("`label'" != "") {
		local newlabel  "label"
	}

	
* Wide or long
	if ("`long'" != "")	& ("`wide'" != "")	{
		di as err "options long and wide may not be combined"
		exit(error(184))
	}
	else {
		if ("`wide'" != "") {
			local datafmt = "wide"
		}
		else local datafmt = "long"
	}
	

	
	if ("`label'" != "") {
		local newlabel  label`label'
	}

	* If no language, use the label column
	else if ("`label'" != "") {
		local newlabel  "label"
	}
	
* Make sure data is saved or cleaned
	if ("`clear'" == "")  {
		di as err "Data in memory will be lost. Enter 'ok' if you want to continue. Enter 'cancel' otherwise", _request(_per)

		if regexm(lower( "`per'"), "cancel") !=1 & regexm(lower( "`per'"), "ok") !=1  {  
			di as err "What's wrong with paying attention???!!! ಠ益ಠ  "_newline(4)
			di as err "Say OK or CANCEL ಠ益ಠ  ", _request(_per)
			if regexm(lower( "`per'"), "cancel") !=1 & regexm(lower( "`per'"), "ok") !=1  {  
				di as err "You are hopeless!!! Goodbye. ಠ益ಠ  "
			}
		}
	}



* Start processing 
	if regexm(lower( "`per'"), "ok") ==1 | ("`clear'" != "") {		
		di "This might take few moments. Please wait... (☉.☉)"
		
		* long format 
		if ("`datafmt'" == "long" | "`datafmt'" == "wide") {

		* Open dataset
		u "`data'", clear

			* Split and add labels to multiple response variables 
			if  ("`multiple'"!="") {
				di as input "Starting labeling select_multiple variables"
				
				qui {

					preserve
						import excel using "`survey'", sheet("survey") firstrow clear all
						cap rename value name
						drop if type==""
						keep type name
						gen typem=1 if regexm(type, "select_multiple")==1
						keep if typem==1
						split type

						levelsof name, local(mvars) clean

						tempfile surveysheet
						save `surveysheet'

						import excel using "`survey'", sheet("choices") firstrow clear all
						cap rename name value
						rename list_name type2
						drop if type2==""
						keep type2 value `newlabel'

						tempfile choicesheet
						save `choicesheet'
					restore

					foreach x of local  mvars {
						cap confirm variable `x'
						
						if !_rc {
							n di as result  "Working on variable - `x'"
							tostring `x', replace

							preserve
								u `surveysheet', clear
								levelsof type2 if name=="`x'", local(`x'_y) clean
								
								u `choicesheet', clear
								levelsof value if type2=="``x'_y'", local(`x'_ch) clean
							restore

							cap tostring `x', replace
							count if `x'!=""
							if `r(N)'==0 noi di "No observation for `x'"

							if `r(N)'>0 {

								split  `x' if `x'!="", gen(`x't_) destring	
										
								foreach b of local `x'_ch {
									local v = regexr("`b'", "-", "_")
									cap drop `x'_`v'
											
									cap egen `x'_`v'=anymatch(`x't_*) if `x'!="", v(`b')
									cap recode `x'_`v' (0=.) if `x'==""
									
									preserve
									u `choicesheet', clear
									cap levelsof `newlabel' if type2=="``x'_y'" & value=="`b'", local(`x'_`v'la) clean
									restore 
									cap label var `x'_`v' "``x'_`v'la'"
									cap notes: `x'_`v': "``x'_`v'la'"
								}
									cap order `x'_*, after(`x') sequential
									cap drop `x't_* 
									
							}
						}

						else {
							n di as error "`x' does not exist"
						}
					}

				}

				n di as result "Completed splitting all variables "
			}

			* Add labels to Single response variables 
			if  ("`single'"!="") {
				n di as input "Starting labeling select_one variables"
				
				qui {
					preserve
						import excel using "`survey'", sheet("survey") firstrow clear all
						cap rename value name
						drop if type==""
						keep type name
						gen typem=1 if regexm(type, "select_one")==1
						keep if typem==1
						split type

						levelsof name, local(mvars_sing) clean

						tempfile surveysheet_sing
						save `surveysheet_sing'

						import excel using "`survey'", sheet("choices") firstrow clear all
						cap rename  name value
						rename list_name type2
						drop if type2==""
						keep type2 value `newlabel'

						tempfile choicesheet_sing
						save `choicesheet_sing'
					restore

					foreach z of local  mvars_sing {
						cap confirm variable `z'
						
						if !_rc {
							n di as result  "Working on variable - `z'"
							
							preserve
								u `surveysheet_sing', clear
								levelsof type2 if name=="`z'", local(`z'_y) clean
								
								u `choicesheet_sing', clear
								levelsof value if type2=="``z'_y'", local(`z'_ch) clean
							restore
							
											
							foreach b of local `z'_ch {
								local v = regexr("`b'", "-", "_")	
								preserve
								u `choicesheet_sing', clear
								cap levelsof `newlabel' if type2=="``z'_y'" & value=="`b'", local(`z'_`v'la) clean
								restore 
								
								cap label define `z' `b' "``z'_`v'la'", modify
								
								if _rc {
									n di as error "`z' cannot be labeled"
								}
							}
							cap la val `z' `z'				
						}

						else {
						n di as error "`z' does not exist"
						}				
					}
				}

				n di as result "Completed labeling all value labels"
			}

			* Add variable labels
			if  ("`varlabel'"!="") {

				n di as input "Starting labeling variables"

				qui {
					preserve
						import excel using "`survey'", sheet("survey") firstrow clear all
						drop if type==""
						keep type name `newlabel'
						gen typem=1 if regexm(type, "begin group")!=1 & regexm(type, "end group")!=1 & regexm(type, "begin repeat")!=1 & regexm(type, "end repeat")!=1 & type!="note"
						keep if typem==1
						split type

						levelsof name, local(mvars_lab) clean

						tempfile surveysheet_lab
						save `surveysheet_lab'

					restore

					foreach z of local  mvars_lab {
						cap confirm variable `z'
						
						if !_rc {
							n di as result  "Working on variable - `z'"
							
							preserve
								u `surveysheet_lab', clear
								levelsof `newlabel' if name=="`z'", local(`z'_y) clean
							restore
							
							cap label var `z'  "``z'_y'"
							cap notes `z': "``z'_y'"
							
							local `z'_l1 :	variable label `z'
							
							
							if "``z'_l1'" =="" {
								label var `z'  "`z'"
								notes `z': "`z'"
							}

						}
						
						else {
							n di as error "`z' does not exist"
							}
					}

				}
				n di as result "Completed labeling all variables"
			}

			if ("`multiple'"=="") & ("`single'"=="") & ("`varlabel'"=="") {
				di as error "Please specify at least one of the options: multiple, single or varlabel"
			}
		}
	
	}

		* wide format 
		if "`datafmt'" == "wide" {
			* Split and add labels to multiple response variables 
			if  ("`multiple'"!="") {
				di as input "Starting labeling select_multiple variables"
				
				qui {

					preserve
						import excel using "`survey'", sheet("survey") firstrow clear all
						cap rename value name
						drop if type==""
						keep type name
						gen typem=1 if regexm(type, "select_multiple")==1
						keep if typem==1
						split type

						levelsof name, local(mvars) clean

						tempfile surveysheet
						save `surveysheet'

						import excel using "`survey'", sheet("choices") firstrow clear all
						cap rename name value
						rename list_name type2
						drop if type2==""
						keep type2 value `newlabel'

						tempfile choicesheet
						save `choicesheet'
					restore

					foreach x of local  mvars {
						lookfor `x'
						loc mv_n = wordcount("`r(varlist)'")
						
						forval mv = 1/`mv_n' {
							cap confirm variable `x'_`mv'
							if _rc continue
							if `mv'>1 {
								_crcslbl `x'_`mv' `x'_1
								notes `x'_`mv': `: variable label `x'_1'
								continue
							}
							
							if !_rc {
								n di as result  "Working on variable - `x'_`mv'"
								tostring `x'_`mv', replace

								preserve
									u `surveysheet', clear
									levelsof type2 if name=="`x'", local(`x'_y) clean
									
									u `choicesheet', clear
									levelsof value if type2=="``x'_y'", local(`x'_ch) clean
								restore

								cap tostring `x'_`mv', replace
								count if `x'_`mv'!=""
								if `r(N)'==0 noi di "No observation for `x'_`mv'"

								if `r(N)'>0 {

									split  `x'_`mv' if `x'_`mv'!="", gen(`x'_`mv't_) destring	
											
									foreach b of local `x'_ch {
										local v = regexr("`b'", "-", "_")
										cap drop `x'_`mv'_`v'
												
										cap egen `x'_`mv'_`v'=anymatch(`x'_`mv't_*) if `x'_`mv'!="", v(`b')
										cap recode `x'_`mv'_`v' (0=.) if `x'==""
										
										preserve
										u `choicesheet', clear
										cap levelsof `newlabel' if type2=="``x'_y'" & value=="`b'", local(`x'_`v'la) clean
										restore 
										cap label var `x'_`mv'_`v' "``x'_`v'la'"
										cap notes: `x'_`mv'_`v': "``x'_`v'la'"
									}
										cap order `x'_`mv'_*, after(`x'_`mv') sequential
										cap drop `x'_`mv't_* 
										
								}
							}

							else {
								n di as error "`x'_`mv' does not exist"
							}
						}
						
					}

				}

				n di as result "Completed splitting all variables "
			}

			* Add labels to Single response variables 
			if  ("`single'"!="") {
				n di as input "Starting labeling select_one variables"
				
				qui {
					preserve
						import excel using "`survey'", sheet("survey") firstrow clear all
						cap rename value name
						drop if type==""
						keep type name
						gen typem=1 if regexm(type, "select_one")==1
						keep if typem==1
						split type

						levelsof name, local(mvars_sing) clean

						tempfile surveysheet_sing
						save `surveysheet_sing'

						import excel using "`survey'", sheet("choices") firstrow clear all
						cap rename  name value
						rename list_name type2
						drop if type2==""
						keep type2 value `newlabel'

						tempfile choicesheet_sing
						save `choicesheet_sing'
					restore

					foreach z of local  mvars_sing {
						lookfor `z'
						loc mv_n = wordcount("`r(varlist)'")
						
						forval mv = 1/`mv_n' {
							cap confirm variable `z'_`mv'
							if _rc continue		
							
							if `mv'>1 {
								_crcslbl `z'_`mv' `z'_1
								notes `z'_`mv': `: variable label `z'_1'
								continue
							}
					
						if !_rc {
							n di as result  "Working on variable - `z'_`mv'"
							
							preserve
								u `surveysheet_sing', clear
								levelsof type2 if name=="`z'", local(`z'_y) clean
								
								u `choicesheet_sing', clear
								levelsof value if type2=="``z'_y'", local(`z'_ch) clean
							restore
							
											
							foreach b of local `z'_ch {
								local v = regexr("`b'", "-", "_")	
								preserve
								u `choicesheet_sing', clear
								cap levelsof `newlabel' if type2=="``z'_y'" & value=="`b'", local(`z'_`v'la) clean
								restore 
								
								cap label define `z' `b' "``z'_`v'la'", modify
								
								if _rc {
									n di as error "`z' cannot be labeled"
								}
							}
							cap la val `z'_`mv' `z'				
						}

						else {
						n di as error "`z'_`mv' does not exist"
						}				
					}
				}

				n di as result "Completed labeling all value labels"
			}

			* Add variable labels
			if  ("`varlabel'"!="") {

				n di as input "Starting labeling variables"

				qui {
					preserve
						import excel using "`survey'", sheet("survey") firstrow clear all
						drop if type==""
						keep type name `newlabel'
						gen typem=1 if regexm(type, "begin group")!=1 & regexm(type, "end group")!=1 & regexm(type, "begin repeat")!=1 & regexm(type, "end repeat")!=1 & type!="note"
						keep if typem==1
						split type

						levelsof name, local(mvars_lab) clean

						tempfile surveysheet_lab
						save `surveysheet_lab'

					restore

					foreach z of local  mvars_lab {
						preserve
							u `surveysheet_lab', clear
							levelsof `newlabel' if name=="`z'", local(`z'_y) clean
						restore
						
						lookfor `z'_
						loc mv_n = wordcount("`r(varlist)'")
						
						forval mv = 1/`mv_n' {
							cap confirm variable `z'_`mv'
							if _rc continue
							
						
							if !_rc {
								n di as result  "Working on variable - `z'_`mv'"
								
								if `mv'==1 {
									cap label var `z'_`mv'  "``z'_y'"
									cap notes `z'_`mv': "``z'_y'"
									
									local `z'_l1 :	variable label `z'_`mv'
									
									
									if "``z'_l1'" =="" {
										label var `z'_`mv'  "`z'"
										notes `z'_`mv': "`z'"
									}
								}
								
								else {
									_crcslbl `z'_`mv' `z'_1
									notes `z'_`mv': `: variable label `z'_1'
								}
								
							}
						
						else {
							n di as error "`z' does not exist"
							}
						}
					}

				}
				n di as result "Completed labeling all variables"
			}

			if ("`multiple'"=="") & ("`single'"=="") & ("`varlabel'"=="") {
				di as error "Please specify at least one of the options: multiple, single or varlabel"
			}
		}
}

if regexm(lower( "`per'"), "cancel") ==1  {
	di as err "{•̃_•̃} Save your data and run the program again"
}
	

end
