
clear
set more off
*log using reg1_expost.log, replace


**attached intheset_expost to the main dataset (integrate4_expost), and calculate funds' first month (mindate)

use integrate4_expost.dta
*1,122,194 observations, mydate 408-664, 15,030 unique funds.
sort id mydate


merge 1:1 id mydate using intheset_expost
*intheset_expost:  3,345 unique funds, 143,776 fund-months, mydate 595-664.  Carries "intheset_expost"

replace intheset_expost=0 if intheset_expost==.
drop _merge
egen mindate = min(mydate), by(id)

save tass6_expost.dta, replace


**subroutine to create fund-month-level variables:  aum, missing_aum, a measure of scope (fundcounter/log_firmscope)
g fundcounter_i=1
g missing_aum_firm =0
replace missing_aum_firm=1 if aum==.
collapse (sum) aum fundcounter_i (max) missing_aum_firm, by (companyid mydate)
rename aum aum_firm
rename fundcounter_i fundcounter_j
g log_firmscope = log(fundcounter_j)
sort companyid mydate

merge 1:m companyid mydate using tass6_expost.dta
drop _merge




**create fund ir, age, missing_aum, size declies, winsorize excess_ret, year dummies, count of number of fund-months (maxcounter)

g age = mydate - mindate +1 
g log_age = log(age)

xtile sz_dec = aum, nq(10)
replace sz_dec=0 if aum==.
tab sz_dec, gen(sz_q)

xtile age_dec = age, nq(10)
tab age_dec, gen(age_q)

g missing_aum = 0
replace missing_aum = 1 if aum==.

sum stdv, d
replace stdv=r(p99) if stdv>r(p99)
replace stdv=r(p1) if stdv<r(p1)

g ir = excess_ret/stdv
sum ir, d
replace ir=r(p99) if ir>r(p99)
replace ir=r(p1) if ir<r(p1)

sum excess_ret, d
replace excess_ret = r(p99) if excess_ret>r(p99)
replace excess_ret = r(p1) if excess_ret<r(p1)

g scope_q1 = 0
g scope_q2 = 0
g scope_q3 = 0
g scope_q4 = 0
g firmscope = exp(log_firmscope)
sum firmscope, d
replace scope_q1 = 1 if firmscope <=r(p25)
replace scope_q2 = 1 if firmscope >r(p25) & firmscope <=r(p50)
replace scope_q3 = 1 if firmscope >r(p50) & firmscope <=r(p75)
replace scope_q4 = 1 if firmscope >r(p75)

tab year, gen(year_dum) 


save tass7_expost.dta, replace
*15,030 unique funds, 1,122,194 observations, 4,364 firms



******************
*
* FIRM LEVEL
*
******************

rename crisis_treat24 TREATED


collapse (sum) excess (mean) year_dum* ret post aum sz_q* fundcounter_j year (max) TREATED age, by(companyid mydate)
g log_firmscope = log(fundcounter_j)
g log_firmage = log(age+1)
xtile age_dec = age, nq(10)
tab age_dec, gen(firmage_q)
rename fundcounter_j firm_scope
rename age firm_age
rename excess firm_excess
forvalues i=1/11 {
	rename sz_q`i' firmsz_q`i'
}

sort companyid mydate

save tass8_expost.dta, replace
*4,364 firms, 404,450 observations



******************
*
* FUND LEVEL
*
******************

keep companyid mydate firmsz_q* log_firmage firmage_q* firm_age firm_excess

merge 1:m companyid mydate using tass7_expost.dta 
drop _merge

rename crisis_treat24 POST_TREAT

g firm_excess_minusi = firm_excess - excess
g scope_minusi = firmscope - 1
g avg_firm_excess_minusi = firm_excess_minusi/scope_minusi
drop firm_excess_minusi
rename avg_firm_excess_minusi firm_excess_minusi

tsset, clear
tsset id mydate

gen firm_moveave_ex = (firm_excess_minusi + L1.firm_excess_minusi + L2.firm_excess_minusi + L3.firm_excess_minusi + L4.firm_excess_minusi + L5.firm_excess_minusi + L6.firm_excess_minusi + L7.firm_excess_minusi + L8.firm_excess_minusi + L9.firm_excess_minusi + L10.firm_excess_minusi + L11.firm_excess_minusi)/12
gen firm_sum_sq_ex = (firm_excess_minusi-firm_moveave_ex)*(firm_excess_minusi-firm_moveave_ex) + (L1.firm_excess_minusi-firm_moveave_ex)*(L1.firm_excess_minusi-firm_moveave_ex) + (L2.firm_excess_minusi-firm_moveave_ex)*(L2.firm_excess_minusi-firm_moveave_ex) + (L3.firm_excess_minusi-firm_moveave_ex)*(L3.firm_excess_minusi-firm_moveave_ex) + (L4.firm_excess_minusi-firm_moveave_ex)*(L4.firm_excess_minusi-firm_moveave_ex) + (L5.firm_excess_minusi-firm_moveave_ex)*(L5.firm_excess_minusi-firm_moveave_ex) + (L6.firm_excess_minusi-firm_moveave_ex)*(L6.firm_excess_minusi-firm_moveave_ex)  + (L7.firm_excess_minusi-firm_moveave_ex)*(L7.firm_excess_minusi-firm_moveave_ex) + (L8.firm_excess_minusi-firm_moveave_ex)*(L8.firm_excess_minusi-firm_moveave_ex) + (L9.firm_excess_minusi-firm_moveave_ex)*(L9.firm_excess_minusi-firm_moveave_ex) + (L10.firm_excess_minusi-firm_moveave_ex)*(L10.firm_excess_minusi-firm_moveave_ex) + (L11.firm_excess_minusi-firm_moveave_ex)*(L11.firm_excess_minusi-firm_moveave_ex)
gen firm_var_ex_move = firm_sum_sq_ex/12
gen firm_stdv_ex_move = sqrt(firm_var_ex_move)
drop firm_sum_sq_ex firm_var_ex_move

g firm_ir_minusi = firm_excess_minusi/firm_stdv_ex_move

sum firm_ir_minusi, d
replace firm_ir_minusi = r(p1) if firm_ir_minusi<r(p1) & firm_ir_minusi !=.
replace firm_ir_minusi = r(p99) if firm_ir_minusi>r(p99) & firm_ir_minusi !=.

xtile firm_ir_dec = firm_ir_minusi, nq(10)
replace firm_ir_dec=0 if firm_ir_minusi==.
tab firm_ir_dec, gen(firm_ir_q)


drop year_dum*

tab year, gen (year_dum)

drop if id==.

save pre_expost_testset.dta, replace
*1,122,194 observations, from 15,030 funds and 4364 firms



*************************************
*
*DIF-IN-DIF WITH FIRM FIXED EFFECTS
*
************************************

**create dif-in-dif set (at least 12 obs ex-dates after 623 and crisis months)
drop if id==.
keep id mydate
drop if mydate>623
drop if mydate>=575 & mydate<=593
bysort id: gen counter=_n
egen maxcounter = max(counter), by(id)
keep if maxcounter>=12
keep if counter==1
keep id

save expost_dindset.dta, replace

clear

use pre_expost_testset

*create cohort dummies
keep id mydate min_mydate year
keep if mydate==min_mydate
rename year min_year
keep id min_year
sort id

merge 1:m id using pre_expost_testset
drop _merge

g CRISIS = 0
replace CRISIS = 1 if mydate>=575 & mydate<=593

merge m:1 id using expost_dindset
drop if _merge !=3
drop _merge

*merge m:1 id using highcorr_set
*merge m:1 id using dropcorr_set

drop if _merge==3
drop _merge drop_corr

egen max_mydate = max(mydate), by(id)
drop if max_mydate>=573 & max_mydate<=593

tab min_year, gen (min_year_dum)

**CROSS-SECTION**

sum ir POST_TREAT max_firm_closedxcrisis start_postcrisis firm_ir_minusi stdv aum_firm aum firmscope age firm_age year if mydate<=623 & CRISIS==0 & firmscope<50

g aum2=aum
sum aum, d
replace aum = r(p50) if aum==.

g firm_ir_minusi2 = firm_ir_minusi
g missing_firmir =0
replace missing_firmir=1 if firm_ir_minusi==.
sum firm_ir_minusi, d
replace firm_ir_minusi=r(p50) if firm_ir_minusi==.

corr ir POST_TREAT max_firm_closedxcrisis start_postcrisis firm_ir_minusi stdv aum aum_firm firmscope age firm_age year if mydate<=623 & CRISIS==0 & firmscope<50


reg ir firm_ir_q* firmsz_q* sz_q* scope_q* age_q* firmage_q* year_dum* if mydate<=623 & CRISIS==0 & firmscope<50, cluster(id)
reg ir POST_TREAT max_firm_closedxcrisis start_postcrisis if mydate<=623 & CRISIS==0 & firmscope<50, cluster(id)
reg ir POST_TREAT max_firm_closedxcrisis start_postcrisis firm_ir_q* firmsz_q* sz_q* scope_q* age_q* firmage_q* year_dum* if mydate<=623 & CRISIS==0 & firmscope<50, cluster(id)

areg ir POST_TREAT firm_ir_q* firmsz_q* sz_q* scope_q* age_q* firmage_q* year_dum* if mydate<=623 & CRISIS==0 & firmscope<50, absorb(companyid) cluster(companyid)
areg ir POST_TREAT max_firm_closedxcrisis start_postcrisis firm_ir_q* firmsz_q* sz_q* scope_q* age_q* firmage_q* year_dum* if mydate<=623 & CRISIS==0 & firmscope<50, absorb(companyid) cluster(companyid)


save expost_dindset2.dta, replace



log off
log close
