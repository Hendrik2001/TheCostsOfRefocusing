**TASS 2015**

clear

*in with firms
insheet using firms.csv
keep productreference companyid companytypeid
keep if companytypeid==1
drop companytypeid
rename productreference id
bysort id: gen counter=_n
keep if counter==1
drop counter
sort id companyid
save firms.dta, replace

clear

*in with mydate converter
insheet using mydate_converter.csv
rename v1 year
rename v2 month
rename v3 mydate
sort year month
save mydate_converter.dta, replace

clear

*in with returns and aums
insheet using TASS_fullproduct.csv

keep date rateofreturn estimatedassets productreference name primarycategory managementfee incentivefee

rename rateofreturn ret
rename estimatedassets aum
rename productreference id
rename primarycategory cat

gen year = int(date/10000)
gen month = int((date-year*10000)/100)
drop date

sort year month

*merge everything
merge m:1 year month using mydate_converter
drop if _merge !=3
drop _merge

merge m:1 id using firms.dta
drop if _merge !=3
drop _merge

keep if year>=1994

order id companyid year month ret aum mydate name cat

egen maxmydate = max(mydate), by(id)
egen minmydate = min(mydate), by(id)
g elapsedtime = maxmydate - minmydate + 1
drop maxmydate minmydate

*the world's largest hedge fund has about $80B of AUM
g crazy_sz = 0
replace crazy_sz =1 if aum>100000000000 & aum !=.
replace crazy_sz =1 if aum<1000000 & aum !=.
drop if crazy_sz==1
drop if ret>1000
drop crazy_sz

save tass1.dta, replace
erase firms.dta




*****************************************
**figure out who is a sporadic or limited reporter**
*****************************************

keep id ret 
	
bysort id: gen ret_dumcounter=_n
egen ret_counter = max(ret_dumcounter), by(id)
keep if ret_counter == ret_dumcounter
keep id ret_counter
sort id
save retcounter.dta, replace

clear

use tass1.dta
sort id
merge id using retcounter
drop if _merge !=3
drop _merge
gen sporadic_dum = 0
replace sporadic_dum = 1 if elapsedtime>ret_counter
egen max_sporadic = max(sporadic_dum), by(id)
tab max_sporadic
drop if max_sporadic==1
drop sporadic_dum max_sporadic

*drop funds that have reported less than 12 months
drop if ret_counter <12
drop if ret==.
drop elapsedtime ret_counter

sum

save tass2.dta, replace
erase retcounter.dta

STOP HERE

*************************************************
*
****BREAK DATA INTO PRE-CRISIS, CRISIS AND POST-CRISIS***
*
*************************************************

*pre
keep if mydate<574
save tass2_pre.dta, replace

bysort id: gen ret_dumcounter=_n
egen ret_counter = max(ret_dumcounter), by(id)
keep if ret_counter == ret_dumcounter
keep id ret_counter
sort id
save retcounter_pre.dta, replace

use tass2_pre.dta
sort id
merge id using retcounter_pre.dta
drop if _merge !=3
drop _merge
drop if ret_counter <12
drop if ret==.
drop ret_counter

save tass3_pre.dta, replace
erase tass2_pre.dta
erase retcounter_pre.dta

clear


*crisis
use tass2.dta
keep if mydate<593
keep if mydate>574
save tass2_crisis.dta, replace

bysort id: gen ret_dumcounter=_n
egen ret_counter = max(ret_dumcounter), by(id)
keep if ret_counter == ret_dumcounter
keep id ret_counter
sort id
save retcounter_crisis.dta, replace

use tass2_crisis.dta
sort id
merge id using retcounter_crisis.dta
drop if _merge !=3
drop _merge
drop if ret_counter <12
drop if ret==.
drop ret_counter

save tass3_crisis.dta, replace
erase tass2_crisis.dta
erase retcounter_crisis.dta

clear


*post
use tass2.dta
keep if mydate>593
save tass2_post.dta, replace

bysort id: gen ret_dumcounter=_n
egen ret_counter = max(ret_dumcounter), by(id)
keep if ret_counter == ret_dumcounter
keep id ret_counter
sort id
save retcounter_post.dta, replace

use tass2_post.dta
sort id
merge id using retcounter_post.dta
drop if _merge !=3
drop _merge
drop if ret_counter <12
drop if ret==.
drop ret_counter

save tass3_post.dta, replace
erase tass2_post.dta
erase retcounter_post.dta

clear


*******************
**AR1 adjustment **
*******************

*pre
use tass3_pre.dta

bysort id: gen xcounter=_n
egen maxcounter = max(xcounter), by(id)
keep if maxcounter == xcounter
drop maxcounter xcounter
gen unique_id_pre = _n
keep unique_id_pre id
sort id
save uniqueid_pre.dta, replace

clear

use tass3_pre.dta
sort id
merge id using uniqueid_pre.dta
drop _merge
gen rho = .
egen maxcounter=max(unique_id_pre)
local end = maxcounter
sort unique_id_pre mydate
tsset unique_id_pre mydate
sort unique_id_pre mydate

forvalues t = 1/`end' {
	quietly reg ret L.ret if unique_id_pre==`t'
	mat arcoefs = e(b)
	quietly replace rho = arcoefs[1,1] if unique_id_pre==`t'
}

sort unique_id_pre
sum rho
sort unique_id mydate
gen ret_star = (ret - rho*L.ret)/(1-rho)

drop rho

save tass4_pre.dta, replace


*crisis
use tass3_crisis.dta

bysort id: gen xcounter=_n
egen maxcounter = max(xcounter), by(id)
keep if maxcounter == xcounter
drop maxcounter xcounter
gen unique_id_crisis = _n
keep unique_id_crisis id
sort id
save uniqueid_crisis.dta, replace

clear

use tass3_crisis.dta
sort id
merge id using uniqueid_crisis.dta
drop _merge
gen rho = .
egen maxcounter=max(unique_id_crisis)
local end = maxcounter
sort unique_id_crisis mydate
tsset unique_id_crisis mydate
sort unique_id_crisis mydate

forvalues t = 1/`end' {
	quietly reg ret L.ret if unique_id_crisis==`t'
	mat arcoefs = e(b)
	quietly replace rho = arcoefs[1,1] if unique_id_crisis==`t'
}

sort unique_id_crisis
sum rho
sort unique_id mydate
gen ret_star = (ret - rho*L.ret)/(1-rho)

drop rho

save tass4_crisis.dta, replace





*post
use tass3_post.dta

bysort id: gen xcounter=_n
egen maxcounter = max(xcounter), by(id)
keep if maxcounter == xcounter
drop maxcounter xcounter
gen unique_id_post = _n
keep unique_id_post id
sort id
save uniqueid_post.dta, replace

clear

use tass3_post.dta
sort id
merge id using uniqueid_post.dta
drop _merge
gen rho = .
egen maxcounter=max(unique_id_post)
local end = maxcounter
sort unique_id_post mydate
tsset unique_id_post mydate
sort unique_id_post mydate

forvalues t = 1/`end' {
	quietly reg ret L.ret if unique_id_post==`t'
	mat arcoefs = e(b)
	quietly replace rho = arcoefs[1,1] if unique_id_post==`t'
}

sort unique_id_post
sum rho
sort unique_id mydate
gen ret_star = (ret - rho*L.ret)/(1-rho)

drop rho

save tass4_post.dta, replace



erase tass1.dta
erase tass2.dta
erase tass3_pre.dta
erase tass3_post.dta
erase tass3_crisis.dta
erase uniqueid_pre.dta
erase uniqueid_post.dta 
erase uniqueid_crisis.dta

**use prais command to diagnose autocorrelation**



