**STUDY TREATED FUNDS OPENED AFTER THE CRISIS**

clear

set more off

use potential_treat2.dta
*15,030 unique funds, 1,122,194 observations, 4364 firms

********************
*
**DEFINE THE TEST SET
*
********************

g intheset_expost = 1

replace intheset_expost = 0 if min_mydate<593
*144,891 observations from 1,080 firms and 3,358 funds remain.

replace intheset_expost = 0 if mydate>623
*41,892 observations from 2,476 funds and 889 firms remain

merge m:1 id using divcorr_set
replace intheset_expost = 0 if _merge==3
drop _merge drop_corr

drop if intheset_expost==0

bysort id: gen counter=_n
egen maxcounter=max(counter), by(id)

replace intheset_expost = 0 if maxcounter<12

drop if intheset_expost==0

keep id mydate intheset_expost

save intheset_expost.dta, replace



clear


use integrate3.dta, replace

merge m:m companyid id using potential_treat2.dta


******************
*
**DIV_CORR<0.985**
*
******************

replace closedxcrisis = 0 if _merge !=3
drop _merge
replace closedxcrisis = 0 if div_corr>=0.985  
drop fund_closedxcrisis
egen fund_closedxcrisis = max(closedxcrisis), by(id)
replace fund_closedxcrisis = 0 if div_corr>=0.985  

*instantaneous and constant FIRM measures of closure during the crisis
egen firm_closedxcrisis = max(closedxcrisis), by(companyid mydate)
egen max_firm_closedxcrisis = max(closedxcrisis), by(companyid)
replace max_firm_closedxcrisis = 0 if div_corr>=0.985 

*a fund cannot be treated unles it started AFTER financial crisis

keep companyid max_firm_closedxcrisis
bysort companyid max_firm_closedxcrisis: gen counter=_n
keep if counter==1
drop counter
egen max_max = max(max_firm_closedxcrisis), by(companyid)
replace max_firm_closedxcrisis = 1 if max_max==1
bysort companyid: gen counter=_n
keep if counter==1
drop counter max_max

sort companyid

merge 1:m companyid using tass5.dta
replace max_firm_closedxcrisis=0 if _merge !=3
drop _merge

egen min_mydate = min(mydate), by(id)
*replace max_firm_closedxcrisis = 0 if min_mydate<593

**crisis_treat24 equals one for two years after the end of the crisis
g crisis_treat24 = 0
replace crisis_treat24 = 1 if max_firm_closedxcrisis==1 & min_mydate>=594 & min_mydate<=623

g start_postcrisis = 0
replace start_postcrisis = 1 if min_mydate>=594 & mydate<=623
*replace start_postcrisis = 0 if max_firm_closedxcrisis==1

save integrate4_expost.dta, replace


****CLEAN UP****

*erase potential_treat2.dta
*erase integrate3.dta








