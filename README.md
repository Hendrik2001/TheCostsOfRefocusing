# Thesis Hendrik van den Broek Repository

Welcome to the repository for my thesis. This repository contains a combination of results, data, Python, and Stata code used throughout my research. Below is an explanation of the contents and structure of the repository.

## Repository Structure

### Folders

- **Factors**: Contains factors used to create the information ratio.
- **Results**: General results and outputs from the analysis.
- **Summary Statistics**: Contains summary statistics.
- **Table2 Results**: Includes results used to recreate Table 2.
- **Python Files**: Consists of separate Python files that mirror code output. All of this code can also be found in the Jupyter notebooks. The order in which the files should be run is:
  1. `makehfdata`
  2. `car36`
  3. `all_closures`
  4. `ret_corr_pairs`
  5. `ret_corr_big_ret_corr_integrate`
  6. `ret_corr_integrate2`
  7. `reg1`
  8. `closed_perf`
  9. `pscore`

- **Stata**: Contains the Stata code used in the original research.

### Data

- `merged_df.csv`: An AI-generated dataset that replicates properties of the Aurum dataset. Regression results and other outputs are meaningless when using this dataset, but it provides an idea of the inner workings of the code.
- `mydate_converter.csv`: Dataset that is used to convert the date format to the format used in the original research.

### Jupyter Notebooks

I originally wrote my code in Jupyter notebooks. These are split into the following:

- **Data Preparation.ipynb**: This is the largest file and contains all of the code used to create necessary variables and filters.
- **Regression.ipynb**: Contains the code that performs the first regressions used in Table 2.
- **Pscore&ClosedPerf.ipynb**: Contains code that creates propensity scores.
- **CausalRegression.ipynb**: This code implements the causal inference model and does not replicate any Stata codes.

## Usage

To replicate the analysis, follow the order of execution for the Python files listed above. (I would recommend to just run the ipynb files.)

## Contact

For any questions or further information, please contact me at hendrikharrypaul@gmail.com.

Thank you for exploring my thesis repository!


TODO:
- Add log_firm_aum
- Year fixed effects
- 
