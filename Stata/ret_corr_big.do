*********************************************************
**CORRELATION BETWEEN THE `i' - 100TH FUNDS IN A FIRM**
*********************************************************

*log using ret_corr_big.log, replace

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
		
		sort id mydate
		quietly merge 1:1 id mydate using epsilon.dta
		quietly drop _merge

		sort companyid mydate
		quietly merge m:1 companyid using simulcounter
		quietly drop _merge
		quietly drop if simulcounter<=`x'
		
		save big_temp.dta, replace

		quietly keep companyid id mydate ret epsilon simulcounter

		sort companyid 
		quietly merge m:1 companyid id using fundcounter
		quietly drop if _merge !=3
		quietly drop _merge
		
		quietly reshape wide ret epsilon id, i(companyid mydate) j(fund_counter)
		quietly drop if id`n'==.
		quietly drop if id`i'==.
		quietly keep companyid mydate id`i'  id`n' ret`i' ret`n' epsilon`i' epsilon`n' simulcounter 

		sort companyid
		save ret_wide1.dta, replace

		**eliminate pairs with too few observations 
		quietly gen too_few_flag = 0
		quietly gen ret`i'_dum = 0
		quietly replace ret`i'_dum=1 if ret`i' !=.
		quietly gen ret`n'_dum = 0
		quietly replace ret`n'_dum=1 if ret`n' !=.

		quietly bysort companyid ret`i'_dum ret`n'_dum: gen pair_counter=_n
		quietly replace pair_counter=0 if ret`i'==.
		quietly replace pair_counter=0 if ret`n'==.
		quietly egen max_pair_counter=max(pair_counter), by(companyid ret`i'_dum ret`n'_dum)
		quietly replace too_few_flag=1 if max_pair_counter<12
		*quietly keep if too_few_flag==0
		
		save ret_wide2.dta, replace

		quietly bysort companyid id`i' id`n': gen counter=_n
		quietly drop if counter>1
		quietly keep companyid id`i' id`n'
		save include_`i'_`n'.dta, replace

		**create sequential firm id**

		clear
		use big_temp.dta
		quietly keep companyid id mydate ret epsilon

		*flag firms that fail the pair_counter test
		sort companyid
		quietly merge m:1 companyid using include_`i'_`n'
		quietly drop if _merge !=3
		quietly drop _merge
		quietly keep if id==id`i' | id==id`n'

		*create unique (sequential) firm id
		quietly bysort companyid: gen counter=_n
		quietly drop if counter>1
		quietly drop counter
		quietly keep companyid
		quietly gen firm_id=_n

		*merge in wide returns
		sort companyid
		quietly merge 1:m companyid using ret_wide2
		quietly drop _merge

		save corr_base.dta, replace

		***`i'th fund on 'n'TH fund***

		sort firm_id mydate
		
		quietly bysort companyid: gen counter=_n
		quietly count if counter==1
		quietly g nvals = r(N)
		local end = nvals
		quietly drop counter nvals

		quietly gen div_corr=0
		quietly gen div_corr_eps=0
		forvalues j=1/`end' {
			display `j'
			capture noisily correlate ret`i' ret`n' if firm_id==`j'
			capture noisily replace div_corr = r(rho) if firm_id==`j'
			capture noisily correlate epsilon`i' epsilon`n' if firm_id==`j'
			capture noisily replace div_corr_eps = r(rho) if firm_id==`j'
		}
		
		quietly keep companyid id`i' id`n' div_corr div_corr_eps
		quietly rename div_corr div_corr_`i'_`n'
		quietly rename div_corr_eps corr_eps_`i'_`n'

		quietly bysort companyid: gen counter=_n
		quietly drop if counter>=2
		quietly drop counter

		save div_corr_`i'_`n', replace
	}
}


*log off
*log close

*****clean-up*****
erase big_temp.dta