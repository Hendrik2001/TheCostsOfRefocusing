
****ASSET PRICING****

clear

***********************
**bring in FF factors**
***********************

insheet using fffactors_DEC15.csv, n
drop if month==.
sort year month
save dataff1.dta, replace

clear

***********************************************
**bring in Fung-Hsieh trend following factors**
***********************************************
insheet using fung_hsieh_DEC15.csv, d
keep ptfsbd ptfsfx ptfscom year month
drop if year==.
sort year month
save dataff2.dta, replace

clear

***********************
**bring in MOM factor**
***********************

insheet using carhartmom.csv, n
sort year month
save dataff3.dta, replace

clear

***********************
**bring in bond factor factor**
***********************

insheet using bond_factor_DEC15.csv, n
sort year month
save dataff4.dta, replace

clear

***********************
**bring in credit spread factor**
***********************

insheet using credit_factor_DEC15.csv, n
drop if year==.
sort year month
save dataff5.dta, replace

clear


*****************************
** asset pricing PRE**
*****************************
use tass4_pre.dta
sort year month
merge m:1 year month using dataff1.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff2.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff3.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff4.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff5.dta
drop if _merge !=3
drop _merge

gen lhs = ret_star - rf
gen excess_ret = 0
gen beta1 = .
gen beta2 = .
gen beta3 = .
gen beta4 = .
gen beta5 = .
gen beta6 = .
gen beta7 = .
gen alpha = .
gen stdv = .
g r2=0
rename mktrf eq_prem
sort id
local end = maxcounter
sort unique_id mydate

forvalues t = 1/`end' {
	quietly reg lhs eq_prem smb ptfsbd ptfsfx ptfscom yr baa if unique_id_pre==`t'
	quietly replace r2 = e(r2) if unique_id_pre==`t'
	quietly predict yhat_ff
	quietly mat coef = e(b)
	quietly replace beta1 = coef[1,1] if unique_id_pre==`t'
	quietly replace beta2 = coef[1,2] if unique_id_pre==`t'
	quietly replace beta3 = coef[1,3] if unique_id_pre==`t'
	quietly replace beta4 = coef[1,4] if unique_id_pre==`t'
	quietly replace beta5 = coef[1,5] if unique_id_pre==`t'
	quietly replace beta6 = coef[1,6] if unique_id_pre==`t'
	quietly replace beta7 = coef[1,7] if unique_id_pre==`t'
	quietly replace alpha = coef[1,8] if unique_id_pre==`t'
	quietly replace excess_ret = lhs - yhat_ff + alpha if unique_id==`t'
	quietly sum excess_ret if unique_id_pre==`t'
	quietly replace stdv = r(sd) if unique_id_pre==`t'
	quietly drop yhat_ff
}

replace excess_ret = . if ret==.
replace excess_ret = . if alpha==.

drop unique_id_pre

g post=0

sort id mydate

save tass5_pre.dta, replace


*****************************
** asset pricing CRISIS**
*****************************
clear
use tass4_crisis.dta
sort year month
merge m:1 year month using dataff1.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff2.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff3.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff4.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff5.dta
drop if _merge !=3
drop _merge

gen lhs = ret_star - rf
gen excess_ret = 0
gen beta1 = .
gen beta2 = .
gen beta3 = .
gen beta4 = .
gen beta5 = .
gen beta6 = .
gen beta7 = .
gen alpha = .
gen stdv = .
g r2=0
rename mktrf eq_prem
sort id
local end = maxcounter
sort unique_id mydate

forvalues t = 1/`end' {
	quietly reg lhs eq_prem smb ptfsbd ptfsfx ptfscom yr baa if unique_id_crisis==`t'
	quietly replace r2 = e(r2) if unique_id_crisis==`t'
	quietly predict yhat_ff
	quietly mat coef = e(b)
	quietly replace beta1 = coef[1,1] if unique_id_crisis==`t'
	quietly replace beta2 = coef[1,2] if unique_id_crisis==`t'
	quietly replace beta3 = coef[1,3] if unique_id_crisis==`t'
	quietly replace beta4 = coef[1,4] if unique_id_crisis==`t'
	quietly replace beta5 = coef[1,5] if unique_id_crisis==`t'
	quietly replace beta6 = coef[1,6] if unique_id_crisis==`t'
	quietly replace beta7 = coef[1,7] if unique_id_crisis==`t'
	quietly replace alpha = coef[1,8] if unique_id_crisis==`t'
	quietly replace excess_ret = lhs - yhat_ff + alpha if unique_id==`t'
	quietly sum excess_ret if unique_id_crisis==`t'
	quietly replace stdv = r(sd) if unique_id_crisis==`t'
	quietly drop yhat_ff
}

replace excess_ret = . if ret==.
replace excess_ret = . if alpha==.

drop unique_id_crisis

g post=0

sort id mydate

save tass5_crisis.dta, replace


*****************************
** asset pricing POST**
*****************************
clear
use tass4_post.dta
sort year month
merge m:1 year month using dataff1.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff2.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff3.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff4.dta
drop if _merge !=3
drop _merge
merge m:1 year month using dataff5.dta
drop if _merge !=3
drop _merge

gen lhs = ret_star - rf
gen excess_ret = 0
gen beta1 = .
gen beta2 = .
gen beta3 = .
gen beta4 = .
gen beta5 = .
gen beta6 = .
gen beta7 = .
gen alpha = .
gen stdv = .
g r2=0
rename mktrf eq_prem
sort id
local end = maxcounter
sort unique_id mydate

forvalues t = 1/`end' {
	quietly reg lhs eq_prem smb ptfsbd ptfsfx ptfscom yr baa if unique_id_post==`t'
	quietly replace r2 = e(r2) if unique_id_post==`t'
	quietly predict yhat_ff
	quietly mat coef = e(b)
	quietly replace beta1 = coef[1,1] if unique_id_post==`t'
	quietly replace beta2 = coef[1,2] if unique_id_post==`t'
	quietly replace beta3 = coef[1,3] if unique_id_post==`t'
	quietly replace beta4 = coef[1,4] if unique_id_post==`t'
	quietly replace beta5 = coef[1,5] if unique_id_post==`t'
	quietly replace beta6 = coef[1,6] if unique_id_post==`t'
	quietly replace beta7 = coef[1,7] if unique_id_post==`t'
	quietly replace alpha = coef[1,8] if unique_id_post==`t'
	quietly replace excess_ret = lhs - yhat_ff + alpha if unique_id_post==`t'
	quietly sum excess_ret if unique_id_post==`t'
	quietly replace stdv = r(sd) if unique_id_post==`t'
	quietly drop yhat_ff
}

replace excess_ret = . if ret==.
replace excess_ret = . if alpha==.

sort id mydate

gen post=1

save tass5_post.dta, replace

append using tass5_pre.dta
append using tass5_crisis.dta

drop eq_pre smb ptfsbd ptfsfx ptfscom yr baa lhs unique_id_* maxcounter

save tass5.dta, replace


********************
*
**PRELIMINARILY DEFINE "CLOSED"**
*
********************

g crisis = 0
replace crisis = 1 if mydate>=573 & mydate<=594

drop post
g post = 0
replace post = 1 if mydate>594

egen max_mydate = max(mydate), by(id)
egen min_mydate = min(mydate), by(id)

*instaneous and constant measures of closure during the crisis
g closedxcrisis = 0
replace closedxcrisis = 1 if max_mydate>=573 & max_mydate<=594 & mydate==max_mydate

egen firm_closedxcrisis = max(closedxcrisis), by(companyid)

save potential_treat0.dta, replace

keep if firm_closedxcrisis==1
drop firm_closedxcrisis closedxcrisis

save potential_divcorr.dta, replace

****************************
*
****PRE-DEFINE TREATMENT***
*
**************************

clear

use potential_treat0
collapse (max) firm_closedxcrisis mydate, by(companyid)
rename firm_closedxcrisis treated
g firm_closed = 0
replace firm_closed=1 if mydate>=573 & mydate<=593
keep companyid firm_closed treated
save diag1.dta, replace

clear
use potential_treat0
sort companyid
merge m:1 companyid using diag1.dta
drop _merge
g mydate2 = mydate
collapse (max) firm_closed closedxcrisis treated mydate (min) mydate2, by(id)
g pre_treat=0
replace pre_treat = 1 if firm_closed==0 & treated==1 & closedxcrisis==0 & mydate2>=562 & mydate>=605
keep id pre_treat
save diag2.dta, replace

merge 1:m id using potential_treat0
drop _merge
collapse (max) pre_treat, by(companyid)
save diag3.dta, replace


****************************


erase dataff1.dta
erase dataff2.dta
erase dataff3.dta
erase dataff4.dta
erase dataff5.dta
erase tass4_pre.dta
erase tass4_crisis.dta
erase tass4_post.dta
erase tass5_pre.dta
erase tass5_post.dta
erase tass5_crisis.dta













