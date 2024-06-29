
clear
set more off

*log using cat_corr_integrate.log, replace

**********************************************************************************
*
* APPENDING CORRELATION DATA FILES STEP 1: THE FIRST 1-45 PAIRWISE CORRELATIONS
*
**********************************************************************************

forvalues x = 1/44 {
	display `x'
	local n = `x' + 1
		
	forvalues i=1/`x' {
		quietly append using div_corr_cat_`i'_`n'.dta
	}
}

*div_cons1 is the focal fund
*div_cons2 is the fund the focal fund is correlated with
g div_cons1=.
g div_cons2=.
g cat_corr=-999

save ret_corr_cat_int1.dta, replace

clear

forvalues x = 2/45 {
	display `x'
	local n = `x' - 1
		
	forvalues i=1/`n' {
		quietly use ret_corr_cat_int1.dta
		quietly keep if same_cat_`i'_`x' !=.
		quietly replace div_cons1 = id`x'
		quietly replace div_cons2 = id`i'
		quietly replace cat_corr = same_cat_`i'_`x' if same_cat_`i'_`x' !=.
		quietly keep companyid div_cons* cat_corr 
		quietly drop if div_cons1==. | div_cons2==.
		quietly drop if cat_corr==-999
		quietly save cat_corr`x'_`i'.dta, replace
	}
}

clear

forvalues x = 2/45 {
	display `x'
	local n = `x' - 1
	forvalues i=1/`n' {
	quietly append using cat_corr`x'_`i'.dta
	}
}

save cat_corr_temp1.dta, replace


**********************************************************************************
*
* APPENDING CORRELATION DATA FILES STEP 2: THE NEXT X-Y PAIRWISE CORRELATIONS
*
**********************************************************************************

clear

forvalues x = 45/62 {
	display `x'
	local n = `x' + 1
		
	forvalues i=1/`x' {
		quietly append using div_corr_cat_`i'_`n'.dta
	}
}

g dup_cons=.
g div_cons1=.
g div_cons2=.
g cat_corr=-999

save ret_corr_cat_int2.dta, replace

clear

forvalues x = 46/63 {
	display `x'
	local n = `x' - 1
		
	forvalues i=1/`n' {
		quietly use ret_corr_cat_int2.dta
		quietly keep if same_cat_`i'_`x' !=.
		quietly replace div_cons1 = id`x'
		quietly replace div_cons2 = id`i'
		quietly replace cat_corr = same_cat_`i'_`x' if same_cat_`i'_`x' !=.
		quietly keep companyid div_cons* cat_corr
		quietly drop if div_cons1==. | div_cons2==.
		quietly drop if cat_corr==-999
		quietly save cat_corr`x'_`i'.dta, replace
	}
}

clear

forvalues x = 46/63 {
	display `x'
	local n = `x' - 1
	forvalues i=1/`n' {
	quietly append using cat_corr`x'_`i'.dta
	}
}

save cat_corr_temp2.dta, replace



**********************************************************************************
*
* APPENDING CORRELATION DATA FILES STEP 3: THE NEXT X-Y PAIRWISE CORRELATIONS
*
**********************************************************************************


clear

forvalues x = 63/65 {
	display `x'
	local n = `x' + 1
		
	forvalues i=1/`x' {
		quietly append using div_corr_cat_`i'_`n'.dta
	}
}

g dup_cons=.
g div_cons1=.
g div_cons2=.
g cat_corr=-999


save cat_corr_int3.dta, replace

clear

forvalues x = 64/66 {
	display `x'
	local n = `x' - 1
		
	forvalues i=1/`n' {
		quietly use cat_corr_int3.dta
		quietly keep if same_cat_`i'_`x' !=.
		quietly replace div_cons1 = id`x'
		quietly replace div_cons2 = id`i'
		quietly replace cat_corr = same_cat_`i'_`x' if same_cat_`i'_`x' !=.
		quietly keep companyid div_cons* cat_corr
		quietly drop if div_cons1==. | div_cons2==.
		quietly drop if cat_corr==-999
		quietly save cat_corr`x'_`i'.dta, replace
	}
}

clear

forvalues x = 64/66 {
	display `x'
	local n = `x' - 1
	forvalues i=1/`n' {
	quietly append using cat_corr`x'_`i'.dta
	}
}

save cat_corr_temp3.dta, replace
append using cat_corr_temp2.dta
append using cat_corr_temp1.dta

bysort companyid div_cons1 div_cons2 cat_corr: gen counter=_n
keep if counter==1
drop counter

sort companyid div_cons1 div_cons2
g cat_corr_id = _n

sort div_cons1 div_cons2

save complete_catcorr.dta, replace


************clean-up*************
*log off
*log close

erase cat_corr_temp1.dta
erase cat_corr_temp2.dta
erase ret_corr_cat_int1.dta
erase ret_corr_cat_int2.dta
erase ret_corr_cat_int3.dta


forvalues x = 1/65 {
	display `x'
	local n = `x' + 1
		
	forvalues i=1/`x' {
		*quietly erase div_corr_cat_`i'_`n'.dta
	}
}

forvalues x = 1/65 {
	display `x'
	local n = `x' + 1
	forvalues i=1/`x' {
	*quietly erase include_cat_`i'_`n'.dta
	}
}

forvalues x = 2/65 {
	display `x'
	local n = `x' + 1
	forvalues i=1/`x' {
	*quietly erase cat_corr`n'_`i'.dta
	}
}

