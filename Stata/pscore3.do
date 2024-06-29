**FIND FUNDS THAT "LOOK" JUST LIKE CLOSED FUNDS**
**NEXT COMPARE FUNDS IN FIRMS WITH CLOSED FUNDS TO FUNDS IN FIRMS THAT "SHOULD HAVE" CLOSED FUNDS**

clear
set more off

log using pscore.log, replace

use car36.dta
keep if mydate==572
keep id avgCAR36 stdv_ex_move
rename avgCAR36 avgCAR
sort id
merge 1:1 id using bridge
keep if _merge==3
drop _merge

egen minCAR = min(avgCAR), by(companyid)
keep if avgCAR == minCAR
bysort companyid: gen counter=_n
keep if counter==1
drop counter
keep companyid minCAR stdv_ex_move
rename stdv_ex_move risk_closed

sum risk_closed, d
replace risk_closed = r(p50) if risk_closed==.

save minCAR.dta, replace

clear

use tass10.dta

merge m:1 companyid using minCAR.dta
drop _merge

merge 1:1 id mydate using car36.dta
drop _merge
rename avgCAR36 avgCAR


**BRING IN PERFORMANCE DATA FROM FUNDS THAT CLOSED**

merge m:1 companyid using closed_perf

g closed_IR_missing = 0
replace closed_IR_missing = 1 if _merge !=3

replace closed_IR_q1=0 if _merge !=3
replace closed_IR_q2=0 if _merge !=3
replace closed_IR_q3=0 if _merge !=3
replace closed_IR_q4=0 if _merge !=3

drop _merge

g treated = 0
egen max_treated = max(TREATED), by(id)
replace treated =1 if max_treated==1 & mydate==572

keep if mydate<=572

sum aum, d
replace aum=r(p50) if aum==.
g log_aum=log(aum+1)

tsset id mydate

g LavgCAR = L.avgCAR
g Llog_aum = L.log_aum
g Lmissing_aum = L.missing_aum
g Llog_firmscope = L.log_firmscope
g Llog_firmage = L.log_firmage
g LminCAR = L.minCAR
forvalues i=1/11 {
	g Lfirmsz_q`i' = L.firmsz_q`i'
}
forvalues i=1/4 {
	g minCAR_q`i'=0
	g f_age_q`i' = 0
}

sum log_age, d
replace age_q1 = 1 if log_age<=r(p25)
replace age_q2 = 1 if log_age<=r(p50) & log_age>r(p25)
replace age_q3 = 1 if log_age<=r(p75) & log_age>r(p50)
replace age_q4 = 1 if log_age>r(p75) & log_age !=.

sum Llog_firmscope, d
replace scope_q1 = 1 if Llog_firmscope<=r(p25)
replace scope_q2 = 1 if Llog_firmscope<=r(p50) & Llog_firmscope>r(p25)
replace scope_q3 = 1 if Llog_firmscope<=r(p75) & Llog_firmscope>r(p50)
replace scope_q4 = 1 if Llog_firmscope>r(p75) & Llog_firmscope !=.

sum LminCAR, d
replace minCAR_q1 = 1 if LminCAR<=r(p25)
replace minCAR_q2 = 1 if LminCAR<=r(p50) & LminCAR>r(p25)
replace minCAR_q3 = 1 if LminCAR<=r(p75) & LminCAR>r(p50)
replace minCAR_q4 = 1 if LminCAR>r(p75) & LminCAR !=.

sum Llog_firmage, d
replace f_age_q1 = 1 if Llog_firmage<=r(p25)
replace f_age_q2 = 1 if Llog_firmage<=r(p50) & Llog_firmage>r(p25)
replace f_age_q3 = 1 if Llog_firmage<=r(p75) & Llog_firmage>r(p50)
replace f_age_q4 = 1 if Llog_firmage>r(p75) & Llog_firmage !=.

g age_sq = log_age * log_age
g scope_sq = Llog_firmscope * Llog_firmscope
g fage_sq = Llog_firmage * Llog_firmage
g minCAR_sq = LminCAR * LminCAR

g int1 = log_age * LminCAR
g int2 = Llog_firmscope * LminCAR
g int3 = Llog_firmage * LminCAR
g int4 = log_age * Llog_firmscope
g int5 = log_age * Llog_firmage
g int6 = Llog_firmscope * Llog_firmage


*keep if intheset==1
drop if fund_closedxcrisis==1
egen min_mydate = min(mydate), by(id)
drop if min_mydate>561

keep if mydate ==572

drop if stdv_ex_move==.
drop if firmscope>50


probit treated LavgCAR stdv_ex_move beta* log_age Llog_aum Lmissing_aum Llog_firmscope Llog_firmage LminCAR risk_closed Lfirmsz_q1 Lfirmsz_q2 Lfirmsz_q3 Lfirmsz_q4 Lfirmsz_q5 Lfirmsz_q6 Lfirmsz_q7 Lfirmsz_q8 Lfirmsz_q9 Lfirmsz_q10



*areg treated LavgCAR stdv_ex_move beta* log_age Llog_aum Lmissing_aum, absorb (companyid) cluster(companyid)
predict pscore
mfx compute
sum pscore, d

save just_after_probit.dta, replace

drop if pscore==.

sum pscore if treated==1
sum pscore if treated==0

g scope = exp(log_firmscope)
egen max_scope = max(scope), by(companyid)
drop if max_scope==1

g xtreme = 0

g upper_bound99=0
g upper_bound75=0
sum pscore if treated==1, d
replace upper_bound99 = r(p99)
replace upper_bound75 = r(p75)

g lower_bound=0
sum pscore if treated==0, d
replace lower_bound =r(p1)

replace xtreme = 1 if pscore>upper_bound75
replace xtreme = 1 if pscore<lower_bound 

twoway (kdensity pscore if treated==1 & xtreme==0) || (kdensity pscore if treated==0 & xtreme==0), legend(label(1 treated) label(2 non-treated))

***trim off top and bottom 1%***
replace xtreme = 0
replace xtreme = 1 if pscore>upper_bound75
replace xtreme = 1 if pscore<lower_bound 
sum pscore if treated==1 & xtreme ==0
sum pscore if treated==0 & xtreme ==0
drop if xtreme
drop xtreme

unique id if treated==1

****************************
**** Common Support ****
**************************

keep id mydate pscore treated

gen tsupport = pscore if treated==1
gen csupport = pscore if treated==0

egen upper_supporttreat = max(tsupport)
egen lower_supporttreat = min(tsupport)

egen upper_supportcont = max(csupport)
egen lower_supportcont = min(csupport)

sum upper_supporttreat lower_supporttreat upper_supportcont lower_supportcont

gen toffcommon = 1
replace toffcommon = 0 if treated==1 & pscore <= upper_supportcont & pscore >= lower_supportcont

gen coffcommon = 1
replace coffcommon = 0 if treated==0 & pscore <= upper_supporttreat & pscore >= lower_supporttreat  

drop if toffcommon ==1 & treated==1
drop if coffcommon ==1 & treated==0

drop toffcommon coffcommon upper_supporttreat lower_supporttreat upper_supportcont lower_supportcont tsupport csupport 

unique id if treated==1
unique id if treated==0

*twoway (kdensity pscore if treated==1) || (kdensity pscore if treated==0), legend(label(1 treated) label(2 non-treated))

save pre_match.dta, replace

*******************************
***** MATCHING ******
*******************************

gsort -treated id

gen counter=_n if treated==1
replace counter = 0 if counter==.
egen maxcounter = max(counter)

tab maxcounter

local end = maxcounter

gen matched = 0
gen matched_id = 0
gen nearest_neighbor = .
gen ptreat = 0
gen id_to_match = 0
gen dif = 9999999

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


gen control = 0

replace control = 1 if matched==1

keep if treated==1 | control==1

drop counter maxcounter matched_id ptreat dif

keep id pscore treated nearest_neighbor

save match.dta, replace
*2,370 unique funds

twoway (kdensity pscore if treated==1) || (kdensity pscore if treated==0, lpattern(dash)), legend(label(1 treated) label(2 control))

keep if treated==0
bysort nearest_neighbor: gen counter=_n
keep if counter==1
keep id 
sort id 
merge 1:m id using tass10.dta
drop if _merge !=3
drop _merge

save match2.dta, replace
*1,192 unique funds

drop counter
bysort id: gen counter=_n
keep if counter==1
keep id 
sort id 
merge 1:m id using tass12.dta
drop if _merge !=3
drop _merge
save match3.dta, replace

clear

use match.dta
keep if treated==1
keep id 
sort id 
merge 1:m id using tass10.dta
drop if _merge !=3
drop _merge

append using match2.dta
*2,370 unique funds

 
areg ir TREATED sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617, absorb(id) cluster(id)

replace int1c = 0 if int1c==.

areg ir TREATED int1c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617, absorb(id) cluster(id)

save matched_set.dta, replace
*2,370 funds, from 958 firms

clear

use match.dta
keep if treated==1
keep id 
sort id 
merge 1:m id using tass12.dta
drop if _merge !=3
drop _merge

append using match3.dta

areg ir TREATED ALL_TREAT sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617, absorb(id) cluster(id)
lincom TREATED - ALL_TREAT

areg ir TREATED ALL_TREAT int1c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617, absorb(id) cluster(id)
lincom TREATED - ALL_TREAT

areg ir TREATED ALL_TREAT int1c sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1, absorb(id) cluster(id)
lincom TREATED - ALL_TREAT

g time_treat = mydate - 594
g int2 = TREATED*time_treat

areg ir TREATED ALL_TREAT int1c time_treat sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1, absorb(id) cluster(id)
lincom TREATED - ALL_TREAT

areg ir TREATED ALL_TREAT int1c time_treat sz_q* scope_q* age_q* firmsz_q* firmage_q* year_dum* if intheset==1 & mydate<=617, absorb(id) cluster(id)
lincom TREATED - ALL_TREAT

clear

use matched_set.dta

keep if mydate==572

keep id

save matched_funds.dta, replace

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














