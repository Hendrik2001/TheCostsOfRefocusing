**FIND FIRMS THAT "LOOK" JUST LIKE FIRMS THAT CLOSED A FUND PRE-CRISIS**
clear
set more off

log using pscore2.log, replace

use expost_dindset2.dta

merge m:1 companyid using minCAR.dta
drop if _merge !=3
drop _merge

merge 1:1 id mydate using car36.dta
drop if _merge==2
drop _merge
rename avgCAR36 avgCAR

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

keep if mydate<=623
keep if CRISIS==0 
keep if firmscope<50


*TREATED FUNDS ARE IN FIRMS THAT CLOSED A FUND DURING THE CRISIS *AND* OPEN A NEW ONE POST-CRISIS
g treated = 0
egen max_treated = max(POST_TREAT), by(companyid)
replace treated =1 if max_treated==1 & mydate==572
drop if max_treated==1 & treated==0

*CONTROL GROUP OBSERVATIONS ARE FUNDS IN FIRMS TAHT COLSED A FUND DURING THE CRISIS BUT DID NOT OPEN A FUND POST-CRISIS

keep if mydate ==572
drop if stdv_ex_move==.

keep if max_firm_closedxcrisis==1

ttest LavgCAR, by(treated)
ttest stdv_ex_move, by(treated)
ttest firm_ir_minusi, by(treated)
ttest Llog_aum, by(treated)
ttest Lmissing_aum, by(treated)
ttest log_age, by(treated)
ttest Llog_firmscope, by(treated)
ttest Llog_firmage, by(treated)

hotelling beta1 beta2 beta3 beta4 beta5 beta6 beta7, by(treated)
hotelling Lfirmsz_q1 Lfirmsz_q2 Lfirmsz_q3 Lfirmsz_q4 Lfirmsz_q5 Lfirmsz_q6 Lfirmsz_q7 Lfirmsz_q8 Lfirmsz_q9 Lfirmsz_q10, by(treated)
hotelling LavgCAR firm_ir_minusi stdv_ex_move Llog_aum Lmissing_aum log_age Llog_firmscope Llog_firmage beta* Lfirmsz_q*, by(treated)

probit treated LavgCAR firm_ir_minusi stdv_ex_move Llog_aum Lmissing_aum log_age Llog_firmscope Llog_firmage beta* Lfirmsz_q*

mfx compute
predict pscore
sum pscore, d

save just_after_probit_pscore2.dta, replace

drop if pscore==.

sum pscore if treated==1
sum pscore if treated==0

g xtreme = 0

g upper_bound75=0
sum pscore if treated==1, d
replace upper_bound75 = r(p75)

g lower_bound=0
sum pscore if treated==0, d
replace lower_bound =r(p1)

replace xtreme = 1 if pscore>upper_bound75
replace xtreme = 1 if pscore<lower_bound 

twoway (kdensity pscore if treated==1 & xtreme==0) || (kdensity pscore if treated==0 & xtreme==0), legend(label(1 treated) label(2 non-treated))

***trim off top and bottom 1%***
sum pscore if treated==1 & xtreme ==0
sum pscore if treated==0 & xtreme ==0
drop if xtreme==1
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

save pre_match_pscore2.dta, replace

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

bysort nearest_neighbor: gen counter=_n
replace counter=1 if nearest_neighbor==.
drop if counter>1
drop counter

save match_pscore2.dta, replace

twoway (kdensity pscore if treated==1) || (kdensity pscore if treated==0, lpattern(dash)), legend(label(1 treated) label(2 control))

**ALL FUNDS FROM THE MATCH**

*control group observations (ready for regressions)
keep if treated==0
keep id 
sort id 
merge 1:m id using expost_dindset2.dta
drop if _merge !=3
drop _merge

save match2_pscore2.dta, replace

*treated observations (funds in firms that closed a fund during the crisis and opened one later)
clear
use match_pscore2
drop if nearest_neighbor==.
keep nearest_neighbor 
rename nearest_neighbor id
sort id
merge 1:m id using expost_dindset2.dta
drop if _merge !=3
drop _merge
keep if mydate<=574
save nearest_neighbor.dta, replace


**ALL POST-MATCH DATA FROM THE "TREATED" FIRMS**

keep companyid 
bysort companyid: gen counter=_n
keep if counter==1
sort companyid 
merge 1:m companyid using expost_dindset2.dta
drop if _merge !=3
drop _merge
drop if mydate<594

append using match2_pscore2.dta
append using nearest_neighbor.dta

save match_reg.dta, replace

*max_firm_closedxcrisis is always equal to one by design (only firms that closed funds during the crisis can be treatments or controls)
*start_postcrisis is collinear with POST_TREAT by design (only firms that opened a fund post-crisis can be treated)

reg ir POST_TREAT max_firm_closedxcrisis start_postcrisis firm_ir_q* firmsz_q* sz_q* scope_q* age_q* firmage_q* year_dum* if mydate<=623 & CRISIS==0 & firmscope<50, cluster(id)
areg ir POST_TREAT max_firm_closedxcrisis start_postcrisis firm_ir_q* firmsz_q* sz_q* scope_q* age_q* firmage_q* year_dum* if mydate<=623 & CRISIS==0 & firmscope<50, absorb(companyid) cluster(companyid)

keep if mydate==572

keep id

merge 1:1 id using just_after_probit_pscore2.dta
drop if _merge !=3

ttest LavgCAR, by(treated)
ttest stdv_ex_move, by(treated)
ttest firm_ir_minusi, by(treated)
ttest Llog_aum, by(treated)
ttest Lmissing_aum, by(treated)
ttest log_age, by(treated)
ttest Llog_firmscope, by(treated)
ttest Llog_firmage, by(treated)

hotelling beta1 beta2 beta3 beta4 beta5 beta6 beta7, by(treated)
hotelling Lfirmsz_q1 Lfirmsz_q2 Lfirmsz_q3 Lfirmsz_q4 Lfirmsz_q5 Lfirmsz_q6 Lfirmsz_q7 Lfirmsz_q8 Lfirmsz_q9 Lfirmsz_q10, by(treated)
hotelling LavgCAR firm_ir_minusi stdv_ex_move Llog_aum Lmissing_aum log_age Llog_firmscope Llog_firmage beta* Lfirmsz_q*, by(treated)




*************************


*log off
*log close














