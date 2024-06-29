# Thesis Hendrik van den Broek Repository
Welcome to the code that I have been using for my thesis.
In this repo is a combination of results, data, python and stata. All of these files are explained further.

File explanation:
Folders:
Factors folder -> consists of Factors used to create the information ratio
Results folder -> General results and outputs
Summary Statistics folder -> Contains summary statistics
Table2 results folder -> Consists of results used to recreate table 2
python files folder-> consists of seperate python files that mirror code output -> I have worked in jupyter notebooks so all of this code can also be found in the ipynb files
    Order in which it should be run:
      - makehfdata
      - car36
      - all_closures
      - ret_corr_pairs
      - ret_corr_big_ret_corr_integrate
      - ret_corr_integrate2
      - reg1
      - closed_perf
      - pscore
      
stata folder -> Contains the stata code used in the original research.




I have created this code in jupyter notebooks these are split in the following:
Data Preparation.ipynb -> This is the largest file and contains all of the code used to create necessary variables and filters
Regression.ipynb -> Contains the code that makes the first regressions used in Table 2
Pscore&ClosedPerf.ipynb -> Contains code that creates Pscores
CausalRegression.ipynb -> This code is the causal inference model and does not replicate any stata codes.


TODO:
- Add log_firm_aum
- Year fixed effects
- 
