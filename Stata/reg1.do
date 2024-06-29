
set more off
clear

*log using reg1.log, replace

use integrate4.dta
keep id mydate crisis_treat* fund_closedxcrisis div_corr corr_eps
bysort id mydate: gen counter=_n
drop if id==.
keep if counter==1
drop counter
***turn off the next step when using categorical measure of div_corr***
replace div_corr = . if div_corr>0.985
merge 1:1 id mydate using tass5.dta
drop _merge

merge m:1 companyid using diag3.dta
replace pre_treat=0 if _merge !=3
replace pre_treat=0 if mydate<=593
replace pre_treat=0 if mydate>=618
drop _merge
rename pre_treat TREATED

sort id mydate
merge 1:1 id mydate using intheset
*drop if _merge !=3
drop _merge

egen mindate = min(mydate), by(id)

save tass6.dta, replace

g fundcounter_i=1
g missing_aum_firm =0
replace missing_aum_firm=1 if aum==.

collapse (sum) aum fundcounter_i (max) missing_aum_firm, by (companyid mydate)

rename aum aum_firm
rename fundcounter_i fundcounter_j
g log_firmscope = log(fundcounter_j)

sort companyid mydate

merge 1:m companyid mydate using tass6.dta
drop _merge

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


bysort id: gen counter=_n
egen maxcounter=max(counter), by(id)


**for funds that were at least two years old at the start of the crisis, what effect did a firm closure of another fund have on change in fund performance**

unique id if intheset==1
unique companyid if intheset==1

g int1c = 0
replace int1c = div_corr * TREATED if div_corr !=.

egen ever_treated = max(TREATED), by(id)
g first30 = 0
replace first30 = 1 if ever_treated & mydate>=594 & mydate<=623
g second30 = 0
replace second30 = 1 if ever_treated & mydate>=624 & mydate<=653

save tass7.dta, replace


*create firm-level data for fund-level analysis

keep if intheset==1
keep if firmscope<50
*keep if mydate<=617

collapse (mean) year_dum* excess ret post aum sz_q* fundcounter_j year (max) TREATED age, by(companyid mydate)
g log_firmscope = log(fundcounter_j)
g log_firmage = log(age+1)
xtile age_dec = age, nq(10)
tab age_dec, gen(firmage_q)
egen stdv_firm = sd(excess), by(companyid TREATED)
rename fundcounter_j firm_scope
rename age firm_age
g firm_ir = excess/stdv_firm
forvalues i=1/11 {
	rename sz_q`i' firmsz_q`i'
}
save tass8.dta, replace


******************
*
* FUND LEVEL
*
******************

*NOTE:  MYDATE 617 IS 24 MONTHS AFTER THE CRISIS

keep companyid mydate firmsz_q* log_firmage firmage_q* firm_age

merge 1:m companyid mydate using tass7.dta 
drop _merge

merge 1:1 id mydate using car36
drop _merge

merge m:1 companyid mydate using all_close_treat.dta
drop _merge

g ALL_TREAT = 0
replace ALL_TREAT = all_close_treat - TREATED
replace ALL_TREAT=0 if ALL_TREAT==-1
sum ALL_TREAT if intheset==1 & mydate<=617

g time_treat = mydate - 594
g int2 = TREATED*time_treat

g int3 =ALL_TREAT*time_treat_all
replace int3 =0 if int3==.

egen max_treated = max(TREATED), by(id)
replace max_treated = 0 if mydate<594

g first24 = 0
replace first24 = 1 if mydate>593 & mydate<=617

g next36 = 0
replace next36 = 1 if mydate>617

g Tx24 = 0
replace Tx24 = max_treated * first24

g Txn36 = 0
replace Txn36 = max_treated * next36

egen max_int1c = max(int1c), by(id)
replace max_int1c = 0 if mydate<594

egen max_int2 = max(int2), by(id)
replace max_int2 = 0 if mydate<594

g Tx24xrelated = Tx24 * max_int1c
g Txn36xrelated = Txn36 * max_int1c

g triple_int = 0
replace triple_int = TREATED * time_treat * div_corr if div_corr !=.

g int1c_max = 0
replace int1c_max = max_treated * div_corr if div_corr !=.
g int2_max = max_treated * time_treat
g triple_int_max = 0
replace triple_int_max = max_treated * time_treat * div_corr if div_corr !=.

egen max_firmscope = max(firmscope), by (companyid)
sum max_firmscope if max_treated==1 & intheset==1 & firmscope<50, d
g median_max_firmscope = r(p50)

save tass12.dta, replace

****FROM THE BEGINNING OF THE DATA SET UNTIL THE ONSET OF THE CRISIS (575) AND THEN FROM THE END OF THE CRISIS (594) UNTIL 2 years LATER****

*BASIC IR RESULTS: TABLE 2 COLUMNS 1-3

unique companyid if intheset==1 & mydate<=617 & firmscope<50

reg ir TREATED sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, cluster(id)
areg ir TREATED sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
areg ir TREATED int1c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)

*reg ret TREATED sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, cluster(id)
*areg ret TREATED sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
*areg ret TREATED int1c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)

**excluding the last month of 2009
*areg ir TREATED sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset2==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
*areg ir TREATED int1c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset2==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)

STOP HERE

****************************************************************
*
**JUST THOSE FUNDS THAT ARE CATEGORICALLY DIVERSIFIED OR NOT&**
*
****************************************************************

merge 1:1 id mydate using cat
g matched = 0
replace matched = 1 if _merge==3
egen max_matched = max(matched), by(id)
g RHS = div*TREATED
replace RHS=0 if RHS==.
g INT = int1c * div
replace INT = 0 if INT==.


areg ir RHS sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)





********************
*
***ALL CLOSURES ***
*
********************

**COMPARING ANY CLOSURE TO THOSE TREATED DURING THE CRISIS**

*areg ir TREATED ALL_TREAT sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
*lincom TREATED - ALL_TREAT

*areg ir TREATED ALL_TREAT int1c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
*lincom TREATED - ALL_TREAT


**Emilie's proposed regression
*g int2c = ALL_TREAT * div_corr
*replace int2c = 0 if int2c==.

*areg ir TREATED ALL_TREAT int1c int2c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
*lincom TREATED - ALL_TREAT
*lincom int1c - int2c

**********************
*
* EFFECTS OVER TIME, SAME SAMPLE WINDOW
*
*********************

*areg ir TREATED ALL_TREAT int2 int3 sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
*lincom TREATED - ALL_TREAT
*lincom int2 - int3


**********************
*
* EFFECTS OVER TIME, LONGER SAMPLE WINDOW (TABLE 5)
*
*********************

areg ir Tx24 Txn36 sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* first24 next36 if intheset==1 & firmscope<50, absorb(id) cluster(id)
lincom Tx24 - Txn36

areg ir Tx24 Txn36 Tx24xrelated Txn36xrelated sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* first24 next36 if intheset==1 & firmscope<50, absorb(id) cluster(id)
lincom Tx24 - Txn36
lincom Tx24xrelated - Txn36xrelated

**REGRESSIONS CALLED FOR BY REVIEWER
*areg ir max_treated int1c_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & firmscope<50, absorb(id) cluster(id)
*areg ir max_treated int2_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & firmscope<50, absorb(id) cluster(id)
*areg ir max_treated int1c_max int2_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & firmscope<50, absorb(id) cluster(id)
*areg ir max_treated int1c_max int2_max triple_int_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & firmscope<50, absorb(id) cluster(id)

g median_rel_int = 0
sum int1c if int1c !=0, d
replace median_rel_int = 1 if int1c >=r(p50)

g intheset2 = intheset
replace intheset2 = 1 if median_rel_int==1
g intheset3 = intheset
replace intheset3 = 1 if median_rel_int==0

areg ir max_treated time_treat sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset2==1 & firmscope<50, absorb(id) cluster(id)
areg ir max_treated time_treat sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset3==1 & firmscope<50, absorb(id) cluster(id)


*quietly g xtreme = 0
*quietly sum ir, d
*quietly g upper_bound = r(p90)
*quietly g lower_bound =r(p10)

*quietly replace xtreme = 1 if ir>upper_bound
*quietly replace xtreme = 1 if ir<lower_bound

*twoway (kdensity ir if max_treated==1 & median_rel_int==1 & xtreme==0) || (kdensity ir if max_treated==1 & median_rel_int==0 & xtreme==0), legend(label(1 related) label(2 unrelated))

*drop upper_bound lower_bound xtreme

**SUB SAMPLE REGRESSIONS CALLED FOR BY REVIEWER

areg ir max_treated int1c_max int2_max triple_int_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & max_firmscope<median_max_firmscope & firmscope<50, absorb(id) cluster(id)
areg ir max_treated int1c_max int2_max triple_int_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & max_firmscope>=median_max_firmscope & firmscope<50, absorb(id) cluster(id)


*********************************
*
**TABLE 1 PANEL A: SUMMARY STATS
*
*******************************

sum ir TREATED ALL_TREAT div_corr stdv aum firmscope aum_firm age firm_age post year if intheset==1 & mydate<=617 & firmscope<50

g aum2=aum
sum aum, d
replace aum2 = r(p50) if aum2==.

*corr ir TREATED ALL_TREAT stdv aum2 firmscope aum_firm age firm_age year if intheset==1 & mydate<=617 & firmscope<50
*corr ir TREATED ALL_TREAT div_corr stdv aum2 firmscope aum_firm age firm_age year if intheset==1 & mydate<=617 & firmscope<50


save summstats.dta, replace

log off
log close


erase tass6.dta
*erase tass8.dta


/*

*****************************************
*
***FIRM LEVEL****
*
*****************************************

*firm-level analysis
clear
use tass8.dta

bysort companyid (mydate) : gen avgCAR_firm = sum(excess)/sum(excess < .)
sort companyid mydate

*BASIC IR RESULTS

reg firm_ir TREATED log_firmscope firmsz_q* log_firmage year_dum*, cluster(companyid)
areg firm_ir TREATED log_firmscope firmsz_q* log_firmage year_dum*, absorb(companyid) cluster(companyid)

merge m:1 companyid mydate using all_close_treat.dta
drop _merge

g ALL_TREAT = 0
replace ALL_TREAT = all_close_treat - TREATED

areg firm_ir all_close_treat log_firmscope firmsz_q* log_firmage year_dum*, absorb(companyid) cluster(companyid)
areg firm_ir ALL_TREAT TREATED log_firmscope firmsz_q* log_firmage year_dum*, absorb(companyid) cluster(companyid)
lincom TREATED - ALL_TREAT

*areg firm_ir all_close_treat firmsz_q* log_firmscope log_firmage year_dum*, absorb(companyid) cluster(companyid)
*areg firm_ir ALL_TREAT TREATED firmsz_q* log_firmscope log_firmage year_dum*, absorb(companyid) cluster(companyid)
*lincom TREATED - ALL_TREAT


*sort companyid mydate

*clear

/*