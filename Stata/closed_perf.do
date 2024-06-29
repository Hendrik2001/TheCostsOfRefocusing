clear
set more off

use tass12.dta

drop counter
keep id companyid 
bysort id companyid: gen counter=_n
keep if counter==1
drop counter
save bridge.dta, replace

clear

use tass12.dta

keep if fund_closedxcrisis==1
keep mydate companyid id

save closed_set.dta, replace

clear

use car36.dta
keep if mydate==572
keep id avgCAR36 stdv_ex_move
rename avgCAR36 avgCAR
sort id
merge 1:1 id using bridge
keep if _merge==3
drop _merge

drop if stdv_ex_move==.

g closed_IR = avgCAR/stdv_ex_move

drop id avgCAR stdv_ex_move

egen min_perf = min(closed_IR), by(companyid)

keep if closed_IR==min_perf

bysort companyid: gen counter=_n
keep if counter==1
drop counter min_perf

g closed_IR_q1=0
g closed_IR_q2=0
g closed_IR_q3=0
g closed_IR_q4=0

sum closed_IR, d

replace closed_IR_q1 = 1 if closed_IR<=r(p25)
replace closed_IR_q2 = 1 if closed_IR<=r(p50) & closed_IR>r(p25)
replace closed_IR_q3 = 1 if closed_IR<=r(p75) & closed_IR>r(p50)
replace closed_IR_q4 = 1 if closed_IR>r(p75)

drop closed_IR

sort companyid

save closed_perf.dta, replace
