
clear
set mem 5000m
set more off
set matsize 800
set scrollbufsize  100000
pause on

******************
**AR1 Adjustment***
**drop firms with less than 12 months of returns
**drop sporadic reporters in hfcons7v2
******************

*log using makehfdata4.log, replace

use hfr_db.dta

*2004 begins at mydate=528, 2007 ends at my date 575

drop if mydate<528
drop if mydate>574

save hfcons7.dta, replace
*this is the db w/monthly returns and monthly aums/

****************************
***STEP1 : AR1 adjustment***
****************************

*******************************************************
**count the number of returns each fund has reported***
*******************************************************

drop if cons_id==.
drop if ret==.

keep cons_id ret 
	
bysort cons_id: gen ret_dumcounter=_n
egen ret_counter = max(ret_dumcounter), by(cons_id)
keep if ret_counter == ret_dumcounter
keep cons_id ret_counter
sort cons_id

*************************

save retcounter, replace

*************************

clear

***************************
**merge in return counter**
***************************


*********************

use hfcons7.dta

*********************

drop if cons_id==.

sort cons_id

merge cons_id using retcounter

tab _merge

drop if _merge !=3

drop _merge


*****************************************
**figure out who is a sporadic reporter**
*****************************************

gen ret_dum = 0
replace ret_dum = 1 if ret !=.
gen retdumxdate = ret_dum * mydate
egen maxmydate = max(retdumxdate), by(cons_id)
egen minmydate = min(retdumxdate), by(cons_id)

gen sporadic_dum = 0

replace sporadic_dum = 1 if mydate>minmydate & mydate<maxmydate & ret_dum==0

egen max_sporadic = max(sporadic_dum), by(cons_id)

tab max_sporadic

drop if max_sporadic==1

drop ret_dum maxmydate minmydate sporadic_dum max_sporadic

**end of sporadic reporter subroutine**

*drop funds that have reported less than 1 year of returns
drop if ret_counter <12

drop if ret==.

save hfcons7v2, replace


*******************************************************************
**generate unique consecutive identifiers for the remaining funds**
*******************************************************************

bysort cons_id: gen xcounter=_n
egen maxcounter = max(xcounter), by(cons_id)
keep if maxcounter == xcounter

gen unique_id = _n
keep unique_id cons_id
sort cons_id

save uniqueid, replace

clear

use hfcons7v2

sort cons_id
merge cons_id using uniqueid
tab _merge
drop _merge


**********************************************
**AR1 adjustment performed in chunks of 1600**
**********************************************

**note that there is very little autocorrelation in this data DW stat = 1.97**
**use prais command to diagnose autocorrelation**

gen rho = .

sort unique_id mydate

tsset unique_id mydate

save justbeforear1, replace

keep if unique_id>=1 & unique_id<=1600

sort unique_id mydate

foreach num of numlist 1/1600 {
	quietly reg ret L.ret if unique_id==`num'
	mat arcoefs = e(b)
	quietly replace rho = arcoefs[1,1] if unique_id==`num'
}

sort unique_id

save justafterar1_1, replace

clear

**********************************************

use justbeforear1

keep if unique_id>=1601 & unique_id<=3200

sort unique_id mydate

foreach num of numlist 1601/3200 {
	quietly reg ret L.ret if unique_id==`num'
	mat arcoefs = e(b)
	quietly replace rho = arcoefs[1,1] if unique_id==`num'
}

sort unique_id

save justafterar1_2, replace

clear

*******************************************

use justbeforear1

keep if unique_id>=3201 & unique_id<=4800

sort unique_id mydate

foreach num of numlist 3201/4800 {
	quietly reg ret L.ret if unique_id==`num'
	mat arcoefs = e(b)
	quietly replace rho = arcoefs[1,1] if unique_id==`num'
}

sort unique_id

save justafterar1_3, replace

clear

*******************************************

use justbeforear1

keep if unique_id>=4801 & unique_id<=6400

sort unique_id mydate

foreach num of numlist 4801/6400 {
	quietly reg ret L.ret if unique_id==`num'
	mat arcoefs = e(b)
	quietly replace rho = arcoefs[1,1] if unique_id==`num'
}

sort unique_id

save justafterar1_4, replace

clear

*******************************************

use justbeforear1

keep if unique_id>=6401 & unique_id<=8000

sort unique_id mydate

foreach num of numlist 6401/8000 {
	quietly reg ret L.ret if unique_id==`num'
	mat arcoefs = e(b)
	quietly replace rho = arcoefs[1,1] if unique_id==`num'
}

sort unique_id

save justafterar1_5, replace

clear

*******************************************

use justbeforear1

drop if ret==.

keep if unique_id>=8001 & unique_id<=9566

sort unique_id mydate

gen counter=8000

foreach num of numlist 8001/9566 {
	quietly reg ret L.ret if unique_id==`num'
	mat arcoefs = e(b)
	quietly replace rho = arcoefs[1,1] if unique_id==`num'
}


sort unique_id
save justafterar1_8, replace

sort unique_id
append using justafterar1_1

sort unique_id
append using justafterar1_2

sort unique_id
append using justafterar1_3

sort unique_id
append using justafterar1_4

sort unique_id
append using justafterar1_5

save afterall, replace

*******************************************
*****END OF AR1 CHUNKS*******************
*******************************************

**pick up at end of ar1 chunks

use afterall

sum rho

sort unique_id mydate

gen ret_star = (ret - rho*L.ret)/(1-rho)

*sort stratnum mydate

save hfmnth_1.dta, replace



*******************
**merge in detail**
*******************
*sort stratnum mydate
*merge stratnum mydate using hfmnth_1.dta
*tab _merge
*drop _merge


*****************************************
**prepare for merge with common facotrs**
*****************************************

*eliminate observations with missing return data
gen retdum = 0
replace retdum = 1 if ret !=.
gen true_mydate = 9999999
replace true_mydate = retdum * mydate if retdum==1 & mydate !=.
egen minmydate = min(true_mydate), by(cons_id)
drop if mydate<minmydate
drop if minmydate==9999999
drop true_mydate

gen true_mydate = 0
replace true_mydate = retdum * mydate if retdum==1 & mydate !=.
egen maxmydate = max(true_mydate), by(cons_id)
drop if mydate>maxmydate
drop if maxmydate==0
drop retdum true_mydate minmydate maxmydate

gen yearnum = year
gen monthnum = month

sort yearnum monthnum

save hfmnth_3.dta, replace
*this is the db with monthly strat-level returns

clear

***********************
**bring in FF factors**
***********************

insheet using fffactors.csv, n

rename month monthnum
rename year yearnum
destring smb, replace force
sort yearnum monthnum

save fffactors.dta, replace

sort yearnum monthnum
merge yearnum monthnum using hfmnth_3.dta
tab _merge
drop if _merge !=3
drop _merge
sort yearnum monthnum

save dataff.dta, replace

clear


***********************************************
**bring in Fung-Hsieh factors**
***********************************************
insheet using tffac_sadka.csv, d
drop v10 v11 v12 v13 v14
sort yearnum monthnum
merge yearnum monthnum using dataff.dta
tab _merge
drop _merge
sort yearnum monthnum
save dataff2.dta, replace

***********************************************
**bring in Pastor-Stambaugh liquidity factors**
***********************************************
clear
insheet using liq_data_1962_2008.csv, d
rename year yearnum
rename month monthnum
sort yearnum monthnum
merge yearnum monthnum using dataff2.dta
tab _merge
drop if _merge !=3
drop _merge
sort yearnum monthnum
save dataff3.dta, replace
clear

***********************
**bring in MOM factor**
***********************

insheet using carhartmom.csv, n

sort yearnum monthnum
merge yearnum monthnum using dataff3.dta
tab _merge
drop if _merge !=3
drop _merge

*****************************
**prepare for asset pricing**
*****************************

gen ret_star2 = ret_star*100
gen lhs = ret_star2 - rf

*sum ret_strat, d
*replace ret_strat = r(p1) if ret_strat<r(p1) & ret_strat !=.
*replace ret_strat = r(p99) if ret_strat>r(p99) & ret_strat !=.
*gen ret_stratlessrf = ret_strat*100 - rf
*replace ret_strat = ret_stratlessrf

gen excess_4factor = 0
gen beta1 = .
gen beta2 = .
gen beta3 = .
gen beta4 = .
gen alpha_4factor = .
gen stdv = .

sort cons_id

save justbefore, replace

******************

*log off
*log close





