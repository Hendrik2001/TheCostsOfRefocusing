*********************************************************
**CORRELATION BETWEEN THE `i' - 100TH FUNDS IN A FIRM**
*********************************************************

*log using cat_corr_big.log, replace

clear

set more off

use potential_divcorr.dta
keep companyid mydate
bysort companyid mydate: gen counter=_n
egen maxcounter = max(counter)
g last = 65
local end = last 

forvalues x = 1/`end' {
	display `x'
	local n = `x' +1
	
	forvalues i=1/`x' {

		clear
		use potential_divcorr.dta
		
		sort companyid mydate
		merge m:1 companyid using simulcounter
		drop _merge
		drop if simulcounter<=`x'
		
		save big_temp_cat.dta, replace

		keep companyid id mydate cat simulcounter

		sort companyid 
		merge m:1 companyid id using fundcounter
		drop if _merge !=3
		drop _merge
		
		reshape wide cat id, i(companyid mydate) j(fund_counter)
		drop if id`n'==.
		drop if id`i'==.
		keep companyid mydate id`i'  id`n' cat`i' cat`n' simulcounter 

		sort companyid
		save ret_wide1_cat.dta, replace

		**eliminate pairs with too few observations 
		gen too_few_flag = 0
		gen cat`i'_dum = 0
		replace cat`i'_dum=1 if cat`i' !=""
		gen cat`n'_dum = 0
		replace cat`n'_dum=1 if cat`n' !=""

		bysort companyid cat`i'_dum cat`n'_dum: gen pair_counter_cat=_n
		replace pair_counter_cat=0 if cat`i'==""
		replace pair_counter_cat=0 if cat`n'==""
		egen max_pair_counter_cat=max(pair_counter_cat), by(companyid cat`i'_dum cat`n'_dum)
		replace too_few_flag=1 if max_pair_counter_cat<12
		*quietly keep if too_few_flag==0
		
		save ret_wide2_cat.dta, replace

		bysort companyid id`i' id`n': gen counter=_n
		drop if counter>1
		keep companyid id`i' id`n'
		save include_cat_`i'_`n'.dta, replace

		**create sequential firm id**

		clear
		use big_temp_cat.dta
		keep companyid id mydate cat

		*flag firms that fail the pair_counter test
		sort companyid
		merge m:1 companyid using include_cat_`i'_`n'
		drop if _merge !=3
		drop _merge
		keep if id==id`i' | id==id`n'

		*create unique (sequential) firm id
		bysort companyid: gen counter=_n
		drop if counter>1
		drop counter
		keep companyid
		gen cat_firm_id=_n

		*merge in wide returns
		sort companyid
		merge 1:m companyid using ret_wide2_cat.dta
		drop _merge

		save corr_base_cat.dta, replace

		***`i'th fund on 'n'TH fund***

		sort cat_firm_id mydate
		
		bysort companyid: gen counter=_n
		count if counter==1
		g nvals = r(N)
		local end = nvals
		drop counter nvals

		g same_cat=0
		forvalues j=1/`end' {
			display `j'
			replace same_cat=1 if cat`i'==cat`n' & cat_firm_id==`j'
			}
		
		keep companyid id`i' id`n' cat`i' cat`n' same_cat
		quietly rename same_cat same_cat_`i'_`n'
		
		bysort companyid: gen counter=_n
		drop if counter>=2
		drop counter

		save div_corr_cat_`i'_`n', replace
	}
}


*log off
*log close

*****clean-up*****
erase big_temp_cat.dta