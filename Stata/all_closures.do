**DIAGNOSTIC ON OPENINGS/CLOSINGS**


clear

*in with mydate converter
insheet using mydate_converter.csv
rename v1 year
rename v2 month
rename v3 mydate
sort year month
save mydate_converter.dta, replace


clear

use tass5.dta

egen min_mydate = min(mydate), by(id)
keep id min_mydate
bysort id: gen counter=_n
keep if counter==1

collapse (sum) counter, by(min_mydate)

rename counter starts
rename min_mydate mydate

save starts.dta, replace

clear

use tass5.dta

egen max_mydate = max(mydate), by(id)
keep id max_mydate
bysort id: gen counter=_n
keep if counter==1

collapse (sum) counter, by(max_mydate)

rename counter closures
rename max_mydate mydate

sort mydate

merge 1:1 mydate using starts.dta
drop _merge

replace closures=0 if closures==.
replace starts=0 if starts==.

merge 1:1 mydate using mydate_converter.dta


outsheet mydate starts closures using open_close_TASS2015.xls, replace

keep year closures starts

collapse (sum) starts closures, by (year)

outsheet year starts closures using open_close_TASS2015_year.xls, replace


clear

use tass5.dta

egen min_mydate = min(mydate), by(id)
egen max_mydate = max(mydate), by(id)
keep id min_mydate max_mydate
bysort id: gen counter=_n
keep if counter==1
drop counter

merge 1:m id using tass5.dta
drop _merge

g closed = 1 if mydate==max_mydate & max_mydate <=653
g opened = 1 if mydate==min_mydate & min_mydate>=409

collapse (sum) closed opened, by(companyid mydate) 

tsset, clear
tsset companyid mydate

g Lclosed = L.closed
replace Lclosed=0 if Lclosed==.
forvalues i=2/30 {
	quietly g L`i'closed = L`i'.closed
	quietly replace L`i'closed = 0 if L`i'closed ==.
	}

g net = opened - Lclosed - L2closed - L3closed - L4closed - L5closed - L6closed - L7closed - L8closed - L9closed -L10closed - L11closed - L12closed

g open_close = 0
replace open_close = 1 if opened==1 & net<=0
*513 openings are in firms that closed a fund in the previous 12 months
tab open_close

g all_close_treat=0
replace all_close_treat = 1 if Lclosed>=1
g time_treat_all = 0
replace time_treat_all=1 if all_close_treat==1

forvalues i=2/30 {
	quietly replace all_close_treat = 1 if L`i'.closed>=1 & L`i'.closed!=.
	quietly replace time_treat_all = `i' if L`i'.closed==1
	}

keep companyid mydate all_close_treat time_treat_all
sort companyid mydate

save all_close_treat.dta, replace

erase starts.dta




