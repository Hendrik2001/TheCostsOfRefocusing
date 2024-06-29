
clear
set more off

*log using ret_corr_pairs.log, replace


************************************************************************************
*
*count number of funds per firm at any given point in time and call it simulcounter
*
*************************************************************************************

use potential_divcorr.dta

*simulcounter is the maximum number of funds in a firm
bysort companyid mydate: gen simulcounter=_n
egen maxsimulcounter=max(simulcounter), by(companyid)
bysort companyid: gen counter=_n
keep if counter==1
keep companyid maxsimulcounter
rename maxsimulcounter simulcounter
sort companyid
save simulcounter.dta, replace

clear

******************************************************************************************************
*
* count number of funds per firm, 
*
********************************************************************************************************

use potential_divcorr.dta

sort companyid
merge m:1 companyid using simulcounter
drop if _merge !=3
drop _merge

*we are only interested in tracking funds in firms when there are at least two funds (simultaneously)

drop if simulcounter==1



***********************************************************************************
*
*create a sequential fund identifier within firm index it with the variable "fundcounter"
*
***********************************************************************************

collapse (max) companyid (min) mydate, by(id)
sort companyid mydate id
bysort companyid: gen fund_counter=_n
drop mydate
sort companyid id
save fundcounter.dta, replace


****************************************
*
* create db of error terms from the 7-factor regressions
*
***************************************

clear

use potential_divcorr.dta
keep id mydate excess alpha
g epsilon = excess - alpha
keep id mydate epsilon
save epsilon.dta, replace



*****clean-up******
*log off
*log close




