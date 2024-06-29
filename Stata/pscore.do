**FIND FUNDS THAT "LOOK" JUST LIKE CLOSED FUNDS**
**NEXT COMPARE FUNDS IN FIRMS WITH CLOSED FUNDS TO FUNDS IN FIRMS THAT "SHOULD HAVE" CLOSED FUNDS**

clear
set more off

log using pscore.log, replace

use car36.dta
quietly keep if mydate==572
quietly keep id avgCAR36 stdv_ex_move
quietly rename avgCAR36 avgCAR
sort id
quietly merge 1:1 id using bridge.dta
quietly keep if _merge==3
quietly drop _merge

quietly egen minCAR = min(avgCAR), by(companyid)
quietly keep if avgCAR == minCAR
quietly bysort companyid: gen counter=_n
quietly keep if counter==1
quietly drop counter
quietly keep companyid minCAR stdv_ex_move
quietly rename stdv_ex_move risk_closed

quietly sum risk_closed, d
quietly replace risk_closed = r(p50) if risk_closed==.

save minCAR.dta, replace

clear

use tass12.dta

quietly merge m:1 companyid using minCAR.dta
quietly drop _merge

quietly merge 1:1 id mydate using car36.dta
quietly drop _merge
quietly rename avgCAR36 avgCAR


**BRING IN PERFORMANCE DATA FROM FUNDS THAT CLOSED**

quietly merge m:1 companyid using closed_perf.dta

quietly g closed_IR_missing = 0
quietly replace closed_IR_missing = 1 if _merge !=3

quietly replace closed_IR_q1=0 if _merge !=3
quietly replace closed_IR_q2=0 if _merge !=3
quietly replace closed_IR_q3=0 if _merge !=3
quietly replace closed_IR_q4=0 if _merge !=3

quietly drop _merge

quietly drop max_treated
quietly g treated = 0
quietly egen max_treated = max(TREATED), by(id)
quietly replace treated =1 if max_treated==1 & mydate==572

quietly keep if mydate<=572

quietly sum aum, d
quietly replace aum=r(p50) if aum==.
quietly g log_aum=log(aum+1)

tsset id mydate

quietly g LavgCAR = L.avgCAR
quietly g Llog_aum = L.log_aum
quietly g Lmissing_aum = L.missing_aum
quietly g Llog_firmscope = L.log_firmscope
quietly g Llog_firmage = L.log_firmage
quietly g LminCAR = L.minCAR
forvalues i=1/11 {
	quietly g Lfirmsz_q`i' = L.firmsz_q`i'
}
forvalues i=1/4 {
	quietly g minCAR_q`i'=0
	quietly g f_age_q`i' = 0
}

quietly sum log_age, d
quietly replace age_q1 = 1 if log_age<=r(p25)
quietly replace age_q2 = 1 if log_age<=r(p50) & log_age>r(p25)
quietly replace age_q3 = 1 if log_age<=r(p75) & log_age>r(p50)
quietly replace age_q4 = 1 if log_age>r(p75) & log_age !=.

quietly sum Llog_firmscope, d
quietly replace scope_q1 = 1 if Llog_firmscope<=r(p25)
quietly replace scope_q2 = 1 if Llog_firmscope<=r(p50) & Llog_firmscope>r(p25)
quietly replace scope_q3 = 1 if Llog_firmscope<=r(p75) & Llog_firmscope>r(p50)
quietly replace scope_q4 = 1 if Llog_firmscope>r(p75) & Llog_firmscope !=.

quietly sum LminCAR, d
quietly replace minCAR_q1 = 1 if LminCAR<=r(p25)
quietly replace minCAR_q2 = 1 if LminCAR<=r(p50) & LminCAR>r(p25)
quietly replace minCAR_q3 = 1 if LminCAR<=r(p75) & LminCAR>r(p50)
quietly replace minCAR_q4 = 1 if LminCAR>r(p75) & LminCAR !=.

quietly sum Llog_firmage, d
quietly replace f_age_q1 = 1 if Llog_firmage<=r(p25)
quietly replace f_age_q2 = 1 if Llog_firmage<=r(p50) & Llog_firmage>r(p25)
quietly replace f_age_q3 = 1 if Llog_firmage<=r(p75) & Llog_firmage>r(p50)
quietly replace f_age_q4 = 1 if Llog_firmage>r(p75) & Llog_firmage !=.

quietly g age_sq = log_age * log_age
quietly g scope_sq = Llog_firmscope * Llog_firmscope
quietly g fage_sq = Llog_firmage * Llog_firmage
quietly g minCAR_sq = LminCAR * LminCAR

quietly g psint1 = log_age * LminCAR
quietly g psint2 = Llog_firmscope * LminCAR
quietly g psint3 = Llog_firmage * LminCAR
quietly g psint4 = log_age * Llog_firmscope
quietly g psint5 = log_age * Llog_firmage
quietly g psint6 = Llog_firmscope * Llog_firmage


*keep if intheset==1
quietly drop if fund_closedxcrisis==1
quietly egen min_mydate = min(mydate), by(id)
quietly drop if min_mydate>561

quietly keep if mydate ==572
*keep if all_close_treat==1

quietly drop if stdv_ex_move==.
quietly drop if firmscope>50

ttest LavgCAR, by(treated)
ttest stdv_ex_move, by(treated)
ttest log_age, by(treated)
ttest Llog_aum, by(treated)
ttest Lmissing_aum, by(treated)
ttest Llog_firmscope, by(treated)
ttest Llog_firmage, by(treated)
ttest LminCAR, by(treated)
ttest risk_closed, by(treated)

hotelling beta1 beta2 beta3 beta4 beta5 beta6 beta7, by(treated)
hotelling Lfirmsz_q1 Lfirmsz_q2 Lfirmsz_q3 Lfirmsz_q4 Lfirmsz_q5 Lfirmsz_q6 Lfirmsz_q7 Lfirmsz_q8 Lfirmsz_q9 Lfirmsz_q10, by(treated)
hotelling treated LavgCAR stdv_ex_move beta* log_age Llog_aum Lmissing_aum Llog_firmscope Llog_firmage LminCAR risk_closed Lfirmsz_q1 Lfirmsz_q2 Lfirmsz_q3 Lfirmsz_q4 Lfirmsz_q5 Lfirmsz_q6 Lfirmsz_q7 Lfirmsz_q8 Lfirmsz_q9 Lfirmsz_q10, by(treated)
hotelling treated LavgCAR stdv_ex_move beta* log_age Llog_aum, by(treated)

probit treated LavgCAR stdv_ex_move beta* log_age Llog_aum Lmissing_aum Llog_firmscope Llog_firmage LminCAR minCAR_sq risk_closed Lfirmsz_q*
****probit treated LavgCAR stdv_ex_move beta* log_age Llog_aum Lmissing_aum Llog_firmscope Llog_firmage LminCAR risk_closed Lfirmsz_q* age_sq scope_sq fage_sq minCAR_sq psint*
****probit treated LavgCAR stdv_ex_move beta* age_q* Llog_aum Lmissing_aum scope_q* f_age_q* minCAR_q* risk_closed Lfirmsz_q* 
****probit treated LavgCAR stdv_ex_move beta* age_q* sz_q* scope_q* firmage_q* LminCAR risk_closed Lfirmsz_q* 


*areg treated LavgCAR stdv_ex_move beta* log_age Llog_aum Lmissing_aum, absorb (companyid) cluster(companyid)
predict pscore
mfx compute
sum pscore, d

save just_after_probit.dta, replace

quietly drop if pscore==.

quietly sum pscore if treated==1
quietly sum pscore if treated==0

quietly g scope = exp(log_firmscope)
quietly egen max_scope = max(scope), by(companyid)
quietly drop if max_scope==1

quietly g xtreme = 0

quietly g upper_bound99=0
quietly g upper_bound90=0
quietly sum pscore if treated==1, d
quietly replace upper_bound99 = r(p99)
quietly replace upper_bound90 = r(p90)

quietly g lower_bound=0
quietly sum pscore if treated==0, d
quietly replace lower_bound =r(p1)

quietly replace xtreme = 1 if pscore>upper_bound99
quietly replace xtreme = 1 if pscore<lower_bound 

twoway (kdensity pscore if treated==1 & xtreme==0) || (kdensity pscore if treated==0 & xtreme==0), legend(label(1 treated) label(2 non-treated))

***trim off top and bottom 1%***
quietly replace xtreme = 0
quietly replace xtreme = 1 if pscore>upper_bound99
quietly replace xtreme = 1 if pscore<lower_bound 
quietly sum pscore if treated==1 & xtreme ==0
quietly sum pscore if treated==0 & xtreme ==0
quietly drop if xtreme
quietly drop xtreme

quietly unique id if treated==1

****************************
**** Common Support ****
**************************

quietly keep id mydate pscore treated

quietly gen tsupport = pscore if treated==1
quietly gen csupport = pscore if treated==0

quietly egen upper_supporttreat = max(tsupport)
quietly egen lower_supporttreat = min(tsupport)

quietly egen upper_supportcont = max(csupport)
quietly egen lower_supportcont = min(csupport)

quietly sum upper_supporttreat lower_supporttreat upper_supportcont lower_supportcont

quietly gen toffcommon = 1
quietly replace toffcommon = 0 if treated==1 & pscore <= upper_supportcont & pscore >= lower_supportcont

quietly gen coffcommon = 1
quietly replace coffcommon = 0 if treated==0 & pscore <= upper_supporttreat & pscore >= lower_supporttreat  

quietly drop if toffcommon ==1 & treated==1
quietly drop if coffcommon ==1 & treated==0

quietly drop toffcommon coffcommon upper_supporttreat lower_supporttreat upper_supportcont lower_supportcont tsupport csupport 

unique id if treated==1
unique id if treated==0

*twoway (kdensity pscore if treated==1) || (kdensity pscore if treated==0), legend(label(1 treated) label(2 non-treated))

save pre_match.dta, replace

*******************************
***** MATCHING ******
*******************************

gsort -treated id

quietly gen counter=_n if treated==1
quietly replace counter = 0 if counter==.
quietly egen maxcounter = max(counter)

tab maxcounter

local end = maxcounter

quietly gen matched = 0
quietly gen matched_id = 0
quietly gen nearest_neighbor = .
quietly gen ptreat = 0
quietly gen id_to_match = 0
quietly gen dif = 9999999

gsort -treated -pscore id

forvalues t = 1/`end' { 
	*display `t'
	quietly:  replace ptreat = pscore if treated == 1 & counter == `t'
	quietly:  egen ptomatch = max(ptreat)
	quietly:  replace dif = abs(ptomatch - pscore) if matched_id==0 & treated==0
	quietly:  egen mindif = min(dif)
	quietly:  replace matched = 1 if dif==mindif & treated==0 & matched_id==0
	quietly:  egen maxmatched = max(matched), by(id)
	quietly:  replace matched_id = 1 if maxmatched==1
	quietly:  replace id_to_match = id if counter == `t'
	quietly:  egen treated_id = max(id_to_match)
	quietly:  replace nearest_neighbor = treated_id if dif==mindif & treated==0
	quietly:  replace id_to_match = 0
	quietly:  drop ptomatch mindif maxmatched treated_id
	quietly:  replace ptreat = 0
	quietly:  replace dif = 9999999
	} 


quietly gen control = 0
quietly replace control = 1 if matched==1
quietly keep if treated==1 | control==1
quietly drop counter maxcounter matched_id ptreat dif
quietly keep id pscore treated nearest_neighbor

save match.dta, replace
*2,370 unique funds

twoway (kdensity pscore if treated==1) || (kdensity pscore if treated==0, lpattern(dash)), legend(label(1 treated) label(2 control))

**merge untreated observations with tass12
*focus on control group
quietly keep if treated==0
*eliminate multiple nearest_neighbors (i.e., treatments with multiple controls)
sort nearest_neighbor id
quietly bysort nearest_neighbor: gen counter=_n
quietly keep if counter==1
quietly drop counter
quietly keep id 
sort id 
quietly merge 1:m id using tass12.dta
quietly drop if _merge !=3
quietly drop _merge
save match3.dta, replace
*control group observations merged with tass12

clear

use match.dta
quietly keep if treated==1
quietly keep id 
sort id 
quietly merge 1:m id using tass12.dta
quietly drop if _merge !=3
quietly drop _merge

append using match3.dta

save matched_set.dta, replace
*2,370 funds, from 958 firms


********************
*
* TABLE 4
*
*********************

reg ir TREATED sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, cluster(id)

areg ir TREATED sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)

areg ir TREATED int1c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)

areg ir TREATED ALL_TREAT sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
lincom TREATED - ALL_TREAT

areg ir TREATED ALL_TREAT int2 int3 sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
lincom TREATED - ALL_TREAT
lincom int2 - int3


**Emilie's proposed regression
*g int2c = ALL_TREAT * div_corr
*replace int2c = 0 if int2c==.

*areg ir TREATED ALL_TREAT int1c int2c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617 & firmscope<50, absorb(id) cluster(id)
*lincom TREATED - ALL_TREAT
*lincom int1c - int2c


**********************
*
* TABLE 5
*
*********************

areg ir Tx24 Txn36 sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* first24 next36 if intheset==1 & firmscope<50, absorb(id) cluster(id)
lincom Tx24 - Txn36

areg ir Tx24 Txn36 Tx24xrelated Txn36xrelated sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* first24 next36 if intheset==1 & firmscope<50, absorb(id) cluster(id)
lincom Tx24 - Txn36
lincom Tx24xrelated - Txn36xrelated


**REGRESSIONS CALLED FOR BY REVIEWER
areg ir max_treated int1c_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & firmscope<50, absorb(id) cluster(id)
areg ir max_treated int2_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & firmscope<50, absorb(id) cluster(id)
*areg ir max_treated int1c_max int2_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & firmscope<50, absorb(id) cluster(id)
areg ir max_treated int1c_max int2_max triple_int_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & firmscope<50, absorb(id) cluster(id)

**SUB SAMPLE REGRESSIONS CALLED FOR BY REVIEWER
areg ir max_treated int1c_max int2_max triple_int_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & max_firmscope<median_max_firmscope & firmscope<50, absorb(id) cluster(id)
areg ir max_treated int1c_max int2_max triple_int_max sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum*   if intheset==1 & max_firmscope>=median_max_firmscope & firmscope<50, absorb(id) cluster(id)


keep if mydate==572
keep id
merge 1:1 id using just_after_probit
drop if _merge !=3

ttest LavgCAR, by(treated)
ttest stdv_ex_move, by(treated)
ttest log_age, by(treated)
ttest Llog_aum, by(treated)
ttest Lmissing_aum, by(treated)
ttest Llog_firmscope, by(treated)
ttest Llog_firmage, by(treated)
ttest LminCAR, by(treated)
ttest risk_closed, by(treated)

hotelling beta1 beta2 beta3 beta4 beta5 beta6 beta7, by(treated)
hotelling Lfirmsz_q1 Lfirmsz_q2 Lfirmsz_q3 Lfirmsz_q4 Lfirmsz_q5 Lfirmsz_q6 Lfirmsz_q7 Lfirmsz_q8 Lfirmsz_q9 Lfirmsz_q10, by(treated)
hotelling treated LavgCAR stdv_ex_move beta* log_age Llog_aum Lmissing_aum Llog_firmscope Llog_firmage LminCAR risk_closed Lfirmsz_q1 Lfirmsz_q2 Lfirmsz_q3 Lfirmsz_q4 Lfirmsz_q5 Lfirmsz_q6 Lfirmsz_q7 Lfirmsz_q8 Lfirmsz_q9 Lfirmsz_q10, by(treated)
hotelling treated LavgCAR stdv_ex_move beta* log_age Llog_aum, by(treated)



*************************


log off
log close


erase minCAR.dta
erase just_after_probit.dta
erase match3.dta
erase pre_match.dta












