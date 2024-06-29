
*************************************
*
**CREATE THE DATABASE FROM RAW DATA**
*
*************************************

*STEP 1: IN + AR1
***Brings in data, breaks data into pre-crisis, crisis and post-crisis, performs AR1 adjustment by periods.  Periods defined by NBER.
***NBER: Great Recession: 12/07-6/09 inclusive, [mydates: 575-593]
***IN: TASS data from 2015, mydate_converter.csv. 
***OUT: tass4_pre, tass4_crisis, tass4_post, mydate_converter.dta

*do makehfdata1.do


*STEP 2: ASSET PRICING
***Asset pricing, reintegrate periods, first attempt at defining "treated" 
***The key explanatory variable: closedxcrisis defined based on max_mydate [573-594] and saved in potential_treat0
***IN: factors, tass4_*.  
***OUT: tass5, potential_divcorr (the full set of funds from firms that closed a fund during the crisis), potential_treat0.dta (see above), diag3.dta (used in reg1.do)

*do makehfdata2.do


**CAR
** IN: tass5.dta
** OUT: car36.dta

*do car36.do


**ALL CLOSURES
***IN: tass5
***OUT: (starts), spreadsheets with starts/closures data, all_close_treat

*do all_closures.do


********************************************************
*
**CORRELATIONS, INTEGRATE CORRELATIONS + PREP FOR REGRESSIONS **
*
***************************************************


*STEP 3: PREPARE FOR CORRELATIONS
**IN: potential_divcorr.dta
**OUT: simulcounter.dta, fundcounter.dta, epsilon.dta

*do ret_corr_pairs.do


*STEP 4: BIG LOOP COMPUTING DYADIC CORRELATIONS FOR UP TO 65 FUNDS/FIRM
***A big loop that captures pairwise correlations within firm 
***IN: potential_divcorr + epsilon + simulcounter + fundcounter
***OUT: div_corr_i_j.dta

*do ret_corr_big.do


*STEP 5: BIG INTEGRATION EFFORT
***IN: div_corr_i_j
***OUT: complete_divcorr.dta

*do ret_corr_integrate.do


*STEP 6: FUNDS OPENED PRE-CRISIS: RELATEDNESS CALCS, TEST SET DEFINITION
***IN: complete_divcorr, potential_treat0
***OUT: potential_treat2, intheset, integrate3, integrate4, dropcorr_set, true_integrate4
3
*do ret_corr_integrate2.do


**CATEGORICAL APPROACH TO MEASURING SIMILARITY BETWEEN FUNDS

**explore how many funds are categorically different from their sister funds**
*do cat.do


*do cat_corr_big.do
*do cat_corr_integrate.do
*do cat_corr_integrate2.do


******************************
*
**REGRESSIONS ON FUNDS OPENED PRE-CRISIS**
*
******************************

*STEP 8: OLS REGRESSIONS ON FUNDS OPENED PRE-CRISIS
***IN: integrate4, tass5, diag3, intheset, car36
***OUT: tass9, tass12

do reg1.do


*CAPTURE PERFORMANCE DATA ON FUNDS THAT CLOSED TO BE USED IN PSCORE MATCHING
**IN: tass12.dta
**OUT: bridge.dta, closed_perf.dta

do closed_perf.do


*STEP 9: PROPENSITY SCORE MATCHING: FINDING "TWINS" OF TREATED FUNDS (FUNDS IN FIRMS THAT CLOSED A FUND), WHERE TWINS ARE MATCHED JUST BEFORE THE CRISIS
*** IN: tass12, car36, bridge.dta, closed_perf.dta
*** OUT: match.dta, matched_set.dta
do pscore.do





******************************
*
**REGRESSIONS ON FUNDS OPENED POST-CRISIS
*
******************************

*STEP 7: FUNDS OPENED POST-CRISIS: RELATEDNESS CALCS, TEST SET DEFINITION
***IN: potential_treat2, integrate3
***OUT: intheset_expost, integrate4_expost
***observations are "in the set" if born at mydate 594, until mydate 617, with at least 12 returns

*do ret_corr_integrate3.do


*STEP 10: OLS REGRESSIONS ON FUNDS OPENED POST-CRISIS
***IN: integrate4_expost (step 7), intheset_expost (step 7), tass9, dropcorr_set
***OUT: tass7_expost, tass8_expost

*do reg1_expost.do



*STEP 11: PROPENSITY SCORE MATCHING: FINDING "TWINS" OF FUNDS IN FIRMS THAT CLOSED A FUND DURING THE CRISIS AND OPENED A FUND POST-CRISIS
*** IN: tass7_expost, tass8_expost
*** OUT: expost_match, expost_match2

*do pscore2.do









