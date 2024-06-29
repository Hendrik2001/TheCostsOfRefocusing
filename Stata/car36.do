clear all

use tass5.dta

tsset, clear
tsset id mydate

gen moveave_ex = (excess + L1.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess)/12
gen sum_sq_ex = (excess-moveave_ex)*(excess-moveave_ex) + (L1.excess-moveave_ex)*(L1.excess-moveave_ex) + (L2.excess-moveave_ex)*(L2.excess-moveave_ex) + (L3.excess-moveave_ex)*(L3.excess-moveave_ex) + (L4.excess-moveave_ex)*(L4.excess-moveave_ex) + (L5.excess-moveave_ex)*(L5.excess-moveave_ex) + (L6.excess - moveave_ex)*(L6.excess - moveave_ex)  + (L7.excess-moveave_ex)*(L7.excess-moveave_ex) + (L8.excess-moveave_ex)*(L8.excess-moveave_ex) + (L9.excess-moveave_ex)*(L9.excess-moveave_ex) + (L10.excess-moveave_ex)*(L10.excess-moveave_ex) + (L11.excess-moveave_ex)*(L11.excess-moveave_ex)
gen var_ex_move = sum_sq_ex/12
gen stdv_ex_move = sqrt(var_ex_move)
drop sum_sq_ex var_ex_move

bysort id: gen counter=_n

gen retdum = 0
replace retdum = 1 if excess !=.

gen retcounter36 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum+ L28.retdum+ L29.retdum+ L30.retdum+ L31.retdum+ L32.retdum+ L33.retdum+ L34.retdum+ L35.retdum+ L36.retdum
gen retcounter35 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum+ L28.retdum+ L29.retdum+ L30.retdum+ L31.retdum+ L32.retdum+ L33.retdum+ L34.retdum+ L35.retdum
gen retcounter34 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum+ L28.retdum+ L29.retdum+ L30.retdum+ L31.retdum+ L32.retdum+ L33.retdum+ L34.retdum
gen retcounter33 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum+ L28.retdum+ L29.retdum+ L30.retdum+ L31.retdum+ L32.retdum+ L33.retdum
gen retcounter32 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum+ L28.retdum+ L29.retdum+ L30.retdum+ L31.retdum+ L32.retdum
gen retcounter31 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum+ L28.retdum+ L29.retdum+ L30.retdum+ L31.retdum
gen retcounter30 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum+ L28.retdum+ L29.retdum+ L30.retdum
gen retcounter29 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum+ L28.retdum+ L29.retdum
gen retcounter28 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum+ L28.retdum
gen retcounter27 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum+ L27.retdum
gen retcounter26 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum+ L26.retdum
gen retcounter25 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum+L25.retdum
gen retcounter24 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum + L24.retdum
gen retcounter23 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum + L23.retdum
gen retcounter22 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum + L22.retdum
gen retcounter21 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum + L21.retdum
gen retcounter20 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum + L20.retdum
gen retcounter19 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum + L19.retdum
gen retcounter18 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum + L18.retdum
gen retcounter17 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum + L17.retdum
gen retcounter16 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum + L16.retdum
gen retcounter15 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum + L15.retdum
gen retcounter14 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum + L14.retdum
gen retcounter13 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum + L13.retdum
gen retcounter12 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum + L12.retdum
gen retcounter11 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum + L11.retdum
gen retcounter10 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum + L10.retdum
gen retcounter9 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum + L9.retdum
gen retcounter8 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum + L8.retdum
gen retcounter7 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum + L7.retdum
gen retcounter6 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum + L6.retdum
gen retcounter5 = L.retdum + L2.retdum + L3.retdum + L4.retdum + L5.retdum
gen retcounter4 = L.retdum + L2.retdum + L3.retdum + L4.retdum
gen retcounter3 = L.retdum + L2.retdum + L3.retdum
gen retcounter2 = L.retdum + L2.retdum
gen retcounter1 = L.retdum

gen retcounter = 0
forvalues i=1/36 {
replace retcounter = `i' if retcounter`i'==`i'
}

sort id mydate

g CAR36 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess+ L28.excess+ L29.excess+ L30.excess+ L31.excess+ L32.excess+ L33.excess+ L34.excess+ L35.excess+ L36.excess) if retcounter>=36
g CAR35 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess+ L28.excess+ L29.excess+ L30.excess+ L31.excess+ L32.excess+ L33.excess+ L34.excess+ L35.excess) if retcounter>=35
g CAR34 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess+ L28.excess+ L29.excess+ L30.excess+ L31.excess+ L32.excess+ L33.excess+ L34.excess) if retcounter>=34
g CAR33 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess+ L28.excess+ L29.excess+ L30.excess+ L31.excess+ L32.excess+ L33.excess) if retcounter>=33
g CAR32 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess+ L28.excess+ L29.excess+ L30.excess+ L31.excess+ L32.excess) if retcounter>=32
g CAR31 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess+ L28.excess+ L29.excess+ L30.excess+ L31.excess) if retcounter>=31
g CAR30 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess+ L28.excess+ L29.excess+ L30.excess) if retcounter>=30
g CAR29 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess+ L28.excess+ L29.excess) if retcounter>=29
g CAR28 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess+ L28.excess) if retcounter>=28
g CAR27 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess+ L27.excess) if retcounter>=27
g CAR26 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess+ L26.excess) if retcounter>=26
g CAR25 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess+ L25.excess) if retcounter>=25
g CAR24 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess + L24.excess) if retcounter>=24
g CAR23 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess + L23.excess) if retcounter>=23
g CAR22 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess + L22.excess) if retcounter>=22
g CAR21 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess + L21.excess) if retcounter>=21
g CAR20 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess + L20.excess) if retcounter>=20
g CAR19 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess + L19.excess) if retcounter>=19
g CAR18 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess + L18.excess) if retcounter>=18
g CAR17 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess + L17.excess) if retcounter>=17
g CAR16 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess + L16.excess) if retcounter>=16
g CAR15 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess + L15.excess) if retcounter>=15
g CAR14 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess + L14.excess) if retcounter>=14
g CAR13 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess + L13.excess) if retcounter>=13
g CAR12 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess + L12.excess) if retcounter>=12
g CAR11 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess + L11.excess) if retcounter>=11
g CAR10 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess + L10.excess) if retcounter>=10
g CAR9 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess + L9.excess) if retcounter>=9
g CAR8 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess + L8.excess) if retcounter>=8
g CAR7 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess + L7.excess) if retcounter>=7
g CAR6 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess + L6.excess) if retcounter>=6
g CAR5 = (L.excess + L2.excess + L3.excess + L4.excess + L5.excess) if retcounter>=5
g CAR4 = (L.excess + L2.excess + L3.excess + L4.excess) if retcounter>=4
g CAR3 = (L.excess + L2.excess + L3.excess) if retcounter>=3
g CAR2 = (L.excess + L2.excess) if retcounter>=2
g CAR1 = (L.excess) if retcounter>=1

g CARstar = .
forvalues i=1/36 {
replace CARstar = CAR`i' if retcounter>=`i'
}

replace retcounter=36 if retcounter>36 & retcounter !=.

gen avgCAR36 = .
replace avgCAR36 = CARstar/retcounter


save car36a.dta, replace

drop if excess==.

keep id mydate avgCAR36 stdv_ex_move

sort id mydate

save car36.dta, replace





