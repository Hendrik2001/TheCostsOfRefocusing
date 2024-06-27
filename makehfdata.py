import pandas as pd
import statsmodels.api as sm

# Load the merged data
merged_df = pd.read_csv('merged_df.csv', low_memory=False)

# Load the mydate converter data
mydate_converter = pd.read_csv('mydate_converter.csv', names=['year', 'month', 'mydate'], skiprows=[0])

# Remove non-numeric rows from mydate_converter
mydate_converter = mydate_converter[pd.to_numeric(mydate_converter['year'], errors='coerce').notnull()]
mydate_converter['year'] = mydate_converter['year'].astype(int)
mydate_converter['month'] = mydate_converter['month'].astype(int)
mydate_converter['mydate'] = mydate_converter['mydate'].astype(int)

# Extract year and month from the date in merged_df
merged_df['year'] = pd.to_numeric(merged_df['date'].str[:4], errors='coerce')
merged_df['month'] = pd.to_numeric(merged_df['date'].str[5:7], errors='coerce')

# Ensure the year and month columns are of the same data type
merged_df['year'] = merged_df['year'].astype(int)
merged_df['month'] = merged_df['month'].astype(int)

# Merge with mydate converter
merged_df = merged_df.merge(mydate_converter, on=['year', 'month'], how='left')

# Step 2: Filter and Clean the Data
# Keep records from 1994 onwards
merged_df = merged_df[merged_df['year'] >= 1994]

# Generate elapsed time
merged_df['maxmydate'] = pd.to_numeric(merged_df.groupby('id')['mydate'].transform('max'), errors='coerce')
merged_df['minmydate'] = pd.to_numeric(merged_df.groupby('id')['mydate'].transform('min'), errors='coerce')
merged_df['elapsedtime'] = merged_df['maxmydate'] - merged_df['minmydate'] + 1

# Filter out invalid records
merged_df = merged_df[(merged_df['aum'] <= 100000000000) & (merged_df['aum'] >= 1000000)]
merged_df = merged_df[merged_df['ret'] <= 1000]

# Identify sporadic reporters
retcounter = merged_df.groupby('id').size().reset_index(name='ret_counter')

merged_df = merged_df.merge(retcounter, on='id', how='left')
merged_df['sporadic_dum'] = (merged_df['elapsedtime'] > merged_df['ret_counter']).astype(int)
max_sporadic = merged_df.groupby('id')['sporadic_dum'].transform('max')
merged_df = merged_df[max_sporadic == 0]

# Drop funds with fewer than 12 months of data
merged_df = merged_df[merged_df['ret_counter'] >= 12]
merged_df = merged_df[merged_df['ret'].notna()]

# Drop unnecessary columns
merged_df.drop(columns=['elapsedtime', 'ret_counter'], inplace=True)

# Save the cleaned data
merged_df.to_csv('tass2.csv', index=False)

# Step 3: Break Data into Pre-Crisis, Crisis, and Post-Crisis Periods
# Split data into pre-crisis, crisis, and post-crisis periods
tass_pre = merged_df[merged_df['mydate'] < 574]
tass_pre.to_csv('tass2_pre.csv', index=False)

tass_crisis = merged_df[(merged_df['mydate'] >= 574) & (merged_df['mydate'] <= 593)]
tass_crisis.to_csv('tass2_crisis.csv', index=False)

tass_post = merged_df[merged_df['mydate'] > 593]
tass_post.to_csv('tass2_post.csv', index=False)

# Step 4: Perform AR1 Adjustment
def ar1_adjustment(df, period_name):
    df = df.sort_values(by=['id', 'mydate'])
    df['rho'] = 0.0
    unique_ids = df['id'].unique()

    for unique_id in unique_ids:
        sub_df = df[df['id'] == unique_id]
        if len(sub_df) > 1:
            model = sm.OLS(sub_df['ret'].iloc[1:], sm.add_constant(sub_df['ret'].shift(1).iloc[1:])).fit()
            rho = model.params.iloc[1] if len(model.params) > 1 else 0  # Use iloc for positional access
            df.loc[df['id'] == unique_id, 'rho'] = rho

    df['ret_star'] = (df['ret'] - df['rho'] * df['ret'].shift(1)) / (1 - df['rho'])
    df.to_csv(f'tass4_{period_name}.csv', index=False)
    return df

# AR1 adjustment for pre-crisis period
tass_pre_adjusted = ar1_adjustment(tass_pre, 'pre')

# AR1 adjustment for crisis period
tass_crisis_adjusted = ar1_adjustment(tass_crisis, 'crisis')

# AR1 adjustment for post-crisis period
tass_post_adjusted = ar1_adjustment(tass_post, 'post')

import pandas as pd
import statsmodels.api as sm


def load_and_clean_data_with_mydate(file_path, mydate_converter, keep_columns=None, drop_na_columns=None):
    file_ext = file_path.split('.')[-1]
    if file_ext == 'csv':
        df = pd.read_csv(file_path)
    elif file_ext in ['xls', 'xlsx']:
        df = pd.read_excel(file_path)

    # Merge with mydate_converter
    mydate_converter = mydate_converter[pd.to_numeric(mydate_converter['year'], errors='coerce').notnull()]

    mydate_converter['year'] = mydate_converter['year'].astype(int)
    mydate_converter['month'] = mydate_converter['month'].astype(int)
    mydate_converter['mydate'] = mydate_converter['mydate'].astype(int)

    df = df.merge(mydate_converter, on=['year', 'month'], how='left')

    if drop_na_columns:
        df = df.dropna(subset=drop_na_columns)
    if keep_columns:
        df = df[keep_columns]

    df = df.sort_values(by=['year', 'month'])
    return df


# Load the mydate converter data
mydate_converter = pd.read_csv('mydate_converter.csv', names=['year', 'month', 'mydate'], skiprows=[0])

# Load factor files with mydate
df_ff = load_and_clean_data_with_mydate('Factors/Corrected_FF_Research_Data_Factors.csv', mydate_converter,
                                        drop_na_columns=['month'])
df_fung_hsieh = load_and_clean_data_with_mydate('Factors/TF-Fac.xlsx', mydate_converter,
                                                keep_columns=['PTFSBD', 'PTFSFX', 'PTFSCOM', 'year', 'month'],
                                                drop_na_columns=['year'])
df_mom = load_and_clean_data_with_mydate('Factors/Corrected_FF_Momentum_Factor.csv', mydate_converter)
df_bond = load_and_clean_data_with_mydate('Factors/DBAA_Monthly_Averages.csv', mydate_converter)
df_credit = load_and_clean_data_with_mydate('Factors/DGS10_Monthly_Averages.csv', mydate_converter,
                                            drop_na_columns=['year'])
print(df_credit.head())

# Function to perform AR1 adjustment
def ar1_adjustment(df, period_name):
    df = df.copy()
    df['ret_star'] = df['ret']
    unique_ids = df['id'].unique()
    for unique_id in unique_ids:
        subset = df[df['id'] == unique_id]
        if len(subset) > 1:
            subset = subset.sort_values(by='mydate')
            X = sm.add_constant(subset['ret'].shift(1).dropna())
            y = subset['ret'].iloc[1:]
            if len(X) == len(y):  # Ensure X and y have the same length
                try:
                    model = sm.OLS(y, X).fit()
                    rho = model.params.iloc[1] if len(model.params) > 1 else 0  # Default to 0 if model fitting fails
                    df.loc[df['id'] == unique_id, 'ret_star'] = (df['ret'] - rho * df['ret'].shift(1)) / (1 - rho)
                except Exception as e:
                    print(f"Model fitting failed for id {unique_id} with error: {e}")
    df.to_csv(f'tass4_{period_name}.csv', index=False)
    return df

# Load merged data

merged_df['mydate'] = merged_df['mydate'].astype(int)

# Define periods
pre_crisis_period = merged_df[(merged_df['mydate'] >= 0) & (merged_df['mydate'] < 575)]
crisis_period = merged_df[(merged_df['mydate'] >= 575) & (merged_df['mydate'] <= 593)]
post_crisis_period = merged_df[(merged_df['mydate'] > 593)]

# Perform AR1 adjustment
tass4_pre = ar1_adjustment(pre_crisis_period, 'pre')
tass4_crisis = ar1_adjustment(crisis_period, 'crisis')
tass4_post = ar1_adjustment(post_crisis_period, 'post')

# Function to merge factors with TASS data
def merge_factors(df_tass, factors_list):
    for factor_df in factors_list:
        df_tass = pd.merge(df_tass, factor_df, on=['year', 'month'], how='left', indicator=True, suffixes=('','_remove'))
        df_tass.drop([i for i in df_tass.columns if 'remove' in i], axis=1, inplace=True)
        df_tass = df_tass[df_tass['_merge'] == 'both'].drop('_merge', axis=1)
    return df_tass

# Load the adjusted TASS data for each period
df_tass4_pre = pd.read_csv('tass4_pre.csv')
df_tass4_crisis = pd.read_csv('tass4_crisis.csv')
df_tass4_post = pd.read_csv('tass4_post.csv')

# List of factor dataframes
factors_list = [df_ff, df_fung_hsieh, df_mom, df_bond, df_credit]

# Merging factors with TASS data for each period
df_tass4_pre = merge_factors(df_tass4_pre, factors_list)
df_tass4_crisis = merge_factors(df_tass4_crisis, factors_list)
df_tass4_post = merge_factors(df_tass4_post, factors_list)

# Save the merged dataframes to CSV for further use
df_tass4_pre.to_csv('tass4_pre_merged.csv', index=False)
df_tass4_crisis.to_csv('tass4_crisis_merged.csv', index=False)
df_tass4_post.to_csv('tass4_post_merged.csv', index=False)


def asset_pricing(df, period_name):
    df['lhs'] = df['ret_star'] - df['RF']
    df['excess_ret'] = 0
    df['beta1'] = 0.0
    df['beta2'] = 0.0
    df['beta3'] = 0.0
    df['beta4'] = 0.0
    df['beta5'] = 0.0
    df['beta6'] = 0.0
    df['beta7'] = 0.0
    df['alpha'] = 0.0
    df['stdv'] = 0.0
    df['r2'] = 0.0

    df.rename(columns={'mktrf': 'eq_prem'}, inplace=True)
    unique_ids = df['id'].unique()

    for unique_id in unique_ids:
        sub_df = df[df['id'] == unique_id]
        if len(sub_df) > 1:
            model = sm.OLS(sub_df['lhs'], sm.add_constant(sub_df[['Mkt-RF', 'SMB', 'PTFSBD', 'PTFSFX', 'PTFSCOM', 'year', 'DBAA']])).fit()
            df.loc[df['id'] == unique_id, 'r2'] = model.rsquared
            predictions = model.predict(sm.add_constant(sub_df[['Mkt-RF', 'SMB', 'PTFSBD', 'PTFSFX', 'PTFSCOM', 'year', 'DBAA']]))
            if len(model.params) > 1: df.loc[df['id'] == unique_id, 'beta1'] = model.params.iloc[1]
            if len(model.params) > 2: df.loc[df['id'] == unique_id, 'beta2'] = model.params.iloc[2]
            if len(model.params) > 3: df.loc[df['id'] == unique_id, 'beta3'] = model.params.iloc[3]
            if len(model.params) > 4: df.loc[df['id'] == unique_id, 'beta4'] = model.params.iloc[4]
            if len(model.params) > 5: df.loc[df['id'] == unique_id, 'beta5'] = model.params.iloc[5]
            if len(model.params) > 6: df.loc[df['id'] == unique_id, 'beta6'] = model.params.iloc[6]
            if len(model.params) > 7: df.loc[df['id'] == unique_id, 'beta7'] = model.params.iloc[7]
            if len(model.params) > 0: df.loc[df['id'] == unique_id, 'alpha'] = model.params.iloc[0]
            df.loc[df['id'] == unique_id, 'excess_ret'] = df['lhs'] - predictions + df['alpha']
            df.loc[df['id'] == unique_id, 'stdv'] = df['excess_ret'].std()

    df['excess_ret'] = df['excess_ret'].where(df['ret'].notna())
    df['excess_ret'] = df['excess_ret'].where(df['alpha'].notna())
    df.to_csv(f'tass5_{period_name}.csv', index=False)
    return df

# Perform asset pricing analysis for each period
tass5_pre = asset_pricing(df_tass4_pre, 'pre')
tass5_crisis = asset_pricing(df_tass4_crisis, 'crisis')
tass5_post = asset_pricing(df_tass4_post, 'post')

# Combine all periods into a single dataset
tass5 = pd.concat([tass5_pre, tass5_crisis, tass5_post])
tass5.to_csv('tass5.csv', index=False)

# Preliminarily define "closed" funds during the crisis
tass5 = pd.concat([tass5_pre, tass5_crisis, tass5_post])

# Define the crisis and post periods
tass5['crisis'] = 0
tass5.loc[(tass5['mydate'] >= 573) & (tass5['mydate'] <= 594), 'crisis'] = 1

tass5['post'] = 0
tass5.loc[tass5['mydate'] > 594, 'post'] = 1

# Identify the max and min mydate for each fund
tass5['max_mydate'] = tass5.groupby('id')['mydate'].transform('max')
tass5['min_mydate'] = tass5.groupby('id')['mydate'].transform('min')

# Define funds that closed during the crisis
tass5['closedxcrisis'] = 0
tass5.loc[(tass5['max_mydate'] >= 573) & (tass5['max_mydate'] <= 594) & (tass5['mydate'] == tass5['max_mydate']), 'closedxcrisis'] = 1

# Define firms that closed at least one fund during the crisis
tass5['firm_closedxcrisis'] = tass5.groupby('companyid')['closedxcrisis'].transform('max')

# Save the potential treatment dataset
tass5.to_csv('potential_treat0.csv', index=False)

# Create a dataset of firms that closed at least one fund during the crisis
potential_divcorr = tass5[tass5['firm_closedxcrisis'] == 1].drop(columns=['firm_closedxcrisis', 'closedxcrisis'])
potential_divcorr.to_csv('potential_divcorr.csv', index=False)

# Pre-define treatment
diag1 = tass5.groupby('companyid').agg({'firm_closedxcrisis': 'max', 'mydate': 'max'}).reset_index()
diag1.rename(columns={'firm_closedxcrisis': 'treated'}, inplace=True)
diag1['firm_closed'] = 0
diag1.loc[(diag1['mydate'] >= 573) & (diag1['mydate'] <= 593), 'firm_closed'] = 1
diag1.to_csv('diag1.csv', index=False)

diag2 = tass5.merge(diag1, on='companyid', how='left')
diag2['mydate'] = diag2['mydate_x']
diag2['mydate2'] = diag2['mydate']
diag2 = diag2.groupby('id').agg({'firm_closed': 'max', 'closedxcrisis': 'max', 'treated': 'max', 'mydate': 'max', 'mydate2': 'min'}).reset_index()
diag2['pre_treat'] = 0
diag2.loc[(diag2['firm_closed'] == 0) & (diag2['treated'] == 1) & (diag2['closedxcrisis'] == 0) & (diag2['mydate2'] >= 562) & (diag2['mydate'] >= 605), 'pre_treat'] = 1
diag2 = diag2[['id', 'pre_treat']]
diag2.to_csv('diag2.csv', index=False)

potential_treat0 = pd.read_csv('potential_treat0.csv')
diag2 = pd.read_csv('diag2.csv')

potential_treat0 = potential_treat0.merge(diag2, on='id', how='left').fillna(0)
potential_treat0['pre_treat'] = potential_treat0['pre_treat'].astype(int)
diag3 = potential_treat0.groupby('companyid').agg({'pre_treat': 'max'}).reset_index()
diag3.to_csv('diag3.csv', index=False)

# Clean up intermediate files
import os

files_to_delete = [
    'dataff_fffactors.csv', 'dataff_fung_hsieh.csv', 'dataff_mom.csv',
    'dataff_bond.csv', 'dataff_credit.csv', 'tass4_pre.csv',
    'tass4_crisis.csv', 'tass4_post.csv', 'tass5_pre.csv',
    'tass5_crisis.csv', 'tass5_post.csv'
]

for file in files_to_delete:
    if os.path.exists(file):
        os.remove(file)
