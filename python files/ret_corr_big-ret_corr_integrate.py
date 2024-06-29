import pandas as pd
import numpy as np
from scipy.stats import pearsonr
import glob
import logging
import os

# Initialize the logging functionality
logging.basicConfig(filename='ret_corr_big.log', level=logging.INFO)

# Load datasets
potential_divcorr = pd.read_csv('potential_divcorr.csv')
epsilon = pd.read_csv('epsilon.csv')
simulcounter = pd.read_csv('simulcounter.csv')
fundcounter = pd.read_csv('fundcounter.csv')

# Filter the data and merge necessary information
potential_divcorr = potential_divcorr[['companyid', 'mydate', 'id', 'ret', 'excess_ret', 'alpha']]
potential_divcorr = potential_divcorr.sort_values(by=['id', 'mydate'])
potential_divcorr = potential_divcorr.merge(epsilon, on=['id', 'mydate'], how='left')
potential_divcorr = potential_divcorr.merge(simulcounter, on='companyid', how='inner')

# Filter firms with at least two funds simultaneously
potential_divcorr = potential_divcorr[potential_divcorr['simulcounter'] > 1]

# Pivot data to wide format using actual IDs
df_wide = potential_divcorr.pivot_table(index=["companyid", "mydate"], columns="id", values=["ret", "epsilon"],
                                        aggfunc='first')

# Flatten multi-index columns
df_wide.columns = [f"{col[0]}_{col[1]}" for col in df_wide.columns]
df_wide.reset_index(inplace=True)

# Initialize the parameter `last`
last = 65


# Function to calculate and save correlations using actual IDs
def calculate_and_save_correlations(df_wide, last):
    results = []
    columns = df_wide.columns
    fund_ids = [col.split("_")[1] for col in columns if "ret_" in col]
    unique_fund_ids = sorted(set(fund_ids))

    for idx1 in range(len(unique_fund_ids)):
        fund_id1 = unique_fund_ids[idx1]
        for idx2 in range(idx1 + 1, len(unique_fund_ids)):
            if idx2 - idx1 >= last:
                break
            fund_id2 = unique_fund_ids[idx2]
            relevant_columns = [f"ret_{fund_id1}", f"ret_{fund_id2}", f"epsilon_{fund_id1}", f"epsilon_{fund_id2}"]
            if all(col in df_wide.columns for col in relevant_columns):
                temp_df = df_wide[['companyid', 'mydate'] + relevant_columns].dropna()
                if len(temp_df) >= 12:
                    correlations = temp_df.corr()
                    ret_corr = correlations.loc[f"ret_{fund_id1}", f"ret_{fund_id2}"]
                    epsilon_corr = correlations.loc[f"epsilon_{fund_id1}", f"epsilon_{fund_id2}"]
                    results.append({
                        "companyid": temp_df['companyid'].iloc[0],
                        "div_cons1": fund_id1,
                        "div_cons2": fund_id2,
                        "div_corr": ret_corr,
                        "corr_eps": epsilon_corr
                    })
                    # Save results to CSV, one file per pair
                    result_df = pd.DataFrame([results[-1]])
                    result_df.to_csv(f"div_corr_{fund_id1}_{fund_id2}.csv", index=False)


# Calculate and save correlations
calculate_and_save_correlations(df_wide, last)

# Combine all correlation files into a single DataFrame
complete_divcorr = pd.DataFrame()
correlation_files = glob.glob("div_corr_*.csv")
for file in correlation_files:
    temp_df = pd.read_csv(file)
    complete_divcorr = pd.concat([complete_divcorr, temp_df], ignore_index=True)
    complete_divcorr.sort_values(by=['companyid', 'div_cons1', 'div_cons2'], inplace=True)
    complete_divcorr['div_corr_id'] = range(1, len(complete_divcorr) + 1)
complete_divcorr.to_csv("complete_divcorr.csv", index=False)
for x in range(1, 100000):
    n = x + 1
    try:
        os.remove(glob('div_corr_*.csv'))
    except FileNotFoundError:
        continue