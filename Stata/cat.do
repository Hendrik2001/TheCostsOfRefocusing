use potential_divcorr

keep companyid id cat mydate

*create unique companyid-cat pairs within mydate*

bysort companyid cat mydate: gen counter=_n

drop if counter>=2

drop counter


*count how many unique companyid-cat pairs 

bysort companyid mydate: gen counter=_n

egen max_counter = max(counter), by(companyid mydate)

g div=0

replace div=1 if max_counter >=2

drop counter max_counter

save cat.dta, replace





