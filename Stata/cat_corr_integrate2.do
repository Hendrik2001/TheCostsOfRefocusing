clear

set more off

***********************************************
*
* Make a list of every fund (id) in complete_divcorr and call it potential_treat1.dta
*
**********************************************

use complete_catcorr
*file with companyid, div_cons1, div_cons2, cat_corr, cat_corr_id

keep div_cons1
rename div_cons1 id
save catcorr_id1.dta, replace
use complete_catcorr
keep div_cons2 
rename div_cons2 id
append using catcorr_id1.dta
bysort id: gen counter=_n
keep if counter==1
drop counter
sort id

save potential_treat1_cat.dta, replace
unique id


clear

*********************************
*
**MERGE IN everything from potential_treat0, in particular the "CLOSED" VARIABLE, merge it with potential_treat1.dta, and call it potential_treat0.dta
*
*********************************
use potential_treat0.dta

*3,176 funds closed during the crisis
unique id if closedxcrisis==1

merge m:1 id using potential_treat1_cat.dta
replace closedxcrisis = 0 if _merge !=3

*2,584 funds closed have at least one div_corr measure
unique id if closedxcrisis==1

drop _merge
egen fund_closedxcrisis = max(closedxcrisis), by(id)

keep company id closedxcrisis fund_closedxcrisis crisis mydate min_mydate

save potential_treat2_cat.dta, replace



***********
*
*create a file of ids with min_mydate
*
***********

keep if mydate==min_mydate
keep id min_mydate
save minmydate.dta, replace

rename id other_fund
rename min_mydate oth_minmydate
save oth_minmydate.dta, replace

clear

*************************************
*
* Eliminate "twins" 
*
*************************************

*********
*
* batch1
*
********

*rename div_cons1 as id, div_cons2 as "other_fund" to facilitate appending

use complete_divcorr
keep companyid div_cons1 div_cons2 div_corr corr_eps
rename div_cons1 id
rename div_cons2 other_fund
sort companyid id other_fund
save batch1.dta, replace

clear

*********
*
* "batch2"
*
********

*rename div_cons1 as id, div_cons2 as "other_fund" to facilitate appending

use complete_divcorr
keep companyid div_cons1 div_cons2 div_corr corr_eps
rename div_cons2 id
rename div_cons1 other_fund
sort companyid id other_fund

append using batch1.dta
merge m:1 id using minmydate.dta
drop if _merge !=3
drop _merge
rename min_mydate id_minmydate
merge m:1 other_fund using oth_minmydate.dta
drop if _merge !=3
drop _merge
*here we have a full list of all focal funds and all funds that are correlated with focal funds

*********
*
* batch3
* focus on (unique) funds with div_corr>0.985
*
********

replace corr_eps=. if corr_eps==-999

*focus on (unique) funds with div_corr>0.985
keep if div_corr>0.985
keep id other_fund div_corr id_minmydate oth_minmydate

bysort id other_fund: gen counter=_n
keep if counter==1
drop counter

*keep_id is a dummy =1 if we should keep the fund
g keep_id=0
g keep_other_fund=0
sort id
replace keep_id = 1 if id_minmydate <= oth_minmydate
replace keep_other_fund = 1 if oth_minmydate<id_minmydate

save batch3.dta, replace


*********
*
* batch4
* identify other_fund ids when keep_id==0 for an id and rename other_fund id
*
********

keep if keep_id==0
keep other_fund div_corr
rename other_fund id

save batch4.dta, replace
 
clear


*********
*
* highcorr_set
* set of funds to be kept, even though they are highly correlated (i.e., b/c we've eliminated their "twins")
*
********


* identify funds with keep_other_fund==0 (which means keep_id==1) and append with batch4
use batch3
keep if keep_other_fund==0
keep id div_corr

append using batch4.dta

bysort id: gen counter=_n
keep if counter==1
keep id
*gen drop_corr=1

save highcorr_set.dta, replace

clear


*********
*
* dropcorr_set
* set of "twin" funds to be dropped
*
********

use batch3
keep id
bysort id: gen counter=_n
keep if counter==1
drop counter
merge 1:1 id using highcorr_set

drop if _merge==3
drop _merge
keep id

save dropcorr_set.dta, replace

clear

********************
*
**DEFINE THE TEST SET
*
********************

use potential_treat2_cat.dta

merge m:1 id using dropcorr_set

g intheset = 1
replace intheset = 0 if crisis==1
replace intheset = 0 if fund_closedxcrisis
replace intheset = 0 if min_mydate>562
replace intheset = 0 if _merge==3
drop _merge 
*drop drop_corr

drop if intheset==0

bysort id: gen counter=_n
egen maxcounter=max(counter), by(id)

replace intheset = 0 if maxcounter<12

drop if intheset==0

keep id mydate intheset

save intheset.dta, replace


clear

*************************************
*
* bring in all pairwise correlations
* note that the label "other_fund" means a fund has a simultaneous fund in the same firm
*
*************************************

clear

use complete_catcorr
keep companyid div_cons1 div_cons2 cat_corr
rename div_cons2 id
rename div_cons1 other_fund
sort companyid id other_fund

append using batch1.dta

replace corr_eps=. if corr_eps==-999

save cat_integrate2.dta, replace

clear

*************************************
*
* identify funds w/div_corr that were closed during the crisis
*
*************************************

use potential_treat2_cat.dta
keep id fund_closedxcrisis
keep if fund_closedxcrisis==1
bysort id: gen counter=_n
keep if counter==1
keep id

*merge closed fund with list of funds w/div_corr to find the "real" treatments
merge 1:m id using cat_integrate2.dta
keep if _merge==3
drop _merge


g treatment = 0
replace treatment = 1 if cat_corr==1

rename id treated_id
rename other_fund id

sort companyid id

save cat_integrate3.dta, replace

merge m:m companyid id using potential_treat2.dta

******************
*
**DIV_CORR<0.985**
*
******************

replace closedxcrisis = 0 if _merge !=3
g closedxcrisis2 = closedxcrisis
g closedxcrisis3 = closedxcrisis
g closedxcrisis4 = closedxcrisis
replace closedxcrisis = 0 if div_corr>=0.985  
drop fund_closedxcrisis
egen fund_closedxcrisis = max(closedxcrisis), by(id)
replace fund_closedxcrisis = 0 if div_corr>=0.985  

*instantaneous and constant FIRM measures of closure during the crisis
egen firm_closedxcrisis = max(closedxcrisis), by(companyid mydate)
egen max_firm_closedxcrisis = max(closedxcrisis), by(companyid)

*a fund cannot be treated if it started within one year of the financial crisis
replace max_firm_closedxcrisis = 0 if min_mydate>562
replace max_firm_closedxcrisis = 0 if div_corr>=0.985 

**crisis_treat24 equals one for two years after the end of the crisis
g crisis_treat24 = 0
replace crisis_treat24 = 1 if max_firm_closedxcrisis==1 & mydate>=595 & mydate<=619

******************
*
**DIV_CORR<0.895**
*
******************

replace closedxcrisis2 = 0 if div_corr>=0.895  
egen fund_closedxcrisis2 = max(closedxcrisis2), by(id)
replace fund_closedxcrisis2 = 0 if div_corr>=0.895  

*instantaneous and constant FIRM measures of closure during the crisis
egen firm_closedxcrisis2 = max(closedxcrisis2), by(companyid mydate)
egen max_firm_closedxcrisis2 = max(closedxcrisis2), by(companyid)

*a fund cannot be treated if it started within one year of the financial crisis
replace max_firm_closedxcrisis2 = 0 if min_mydate>562
replace max_firm_closedxcrisis2 = 0 if div_corr>=0.895 

**crisis_treat24 equals one for two years after the end of the crisis
g crisis_treat24_90 = 0
replace crisis_treat24_90 = 1 if max_firm_closedxcrisis2==1 & mydate>=595 & mydate<=619

******************
*
**CORR_EPS <0.985**
*
******************

replace closedxcrisis3 = 0 if corr_eps>=0.985  
egen fund_closedxcrisis3 = max(closedxcrisis3), by(id)
replace fund_closedxcrisis3 = 0 if corr_eps>=0.985  

*instantaneous and constant FIRM measures of closure during the crisis
egen firm_closedxcrisis3 = max(closedxcrisis3), by(companyid mydate)
egen max_firm_closedxcrisis3 = max(closedxcrisis3), by(companyid)

*a fund cannot be treated if it started within one year of the financial crisis
replace max_firm_closedxcrisis3 = 0 if min_mydate>562
replace max_firm_closedxcrisis3 = 0 if div_corr>=0.985 

**crisis_treat24 equals one for two years after the end of the crisis
g crisis_treat24_99eps = 0
replace crisis_treat24_99eps = 1 if max_firm_closedxcrisis3==1 & mydate>=595 & mydate<=619


******************
*
**CORR_EPS <0.895**
*
******************

replace closedxcrisis4 = 0 if corr_eps>=0.895  
egen fund_closedxcrisis4 = max(closedxcrisis4), by(id)
replace fund_closedxcrisis4 = 0 if corr_eps>=0.895  

*instantaneous and constant FIRM measures of closure during the crisis
egen firm_closedxcrisis4 = max(closedxcrisis4), by(companyid mydate)
egen max_firm_closedxcrisis4 = max(closedxcrisis4), by(companyid)

*a fund cannot be treated if it started within one year of the financial crisis
replace max_firm_closedxcrisis4 = 0 if min_mydate>562
replace max_firm_closedxcrisis4 = 0 if div_corr>=0.895 

**crisis_treat24 equals one for two years after the end of the crisis
g crisis_treat24_90eps = 0
replace crisis_treat24_90eps = 1 if max_firm_closedxcrisis4==1 & mydate>=595 & mydate<=619

drop div_corr
rename cat_corr div_corr

save integrate4.dta, replace


****CLEAN UP****

erase batch1.dta
erase batch3.dta
erase batch4.dta
erase potential_treat1_cat.dta
erase cat_integrate2.dta
erase highcorr_set.dta









