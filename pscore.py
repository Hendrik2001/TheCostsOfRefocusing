import pandas as pd
import numpy as np
import statsmodels.api as sm
import seaborn as sns
import matplotlib.pyplot as plt

# Load datasets
car36 = pd.read_csv('car36.csv')
bridge = pd.read_csv('bridge.csv')
tass12 = pd.read_csv('tass12.csv')
closed_perf = pd.read_csv('closed_perf.csv')

# Process car36 data
car36 = car36[car36['mydate'] == 572][['id', 'avgCAR36', 'stdv_ex_move']]
car36 = car36.rename(columns={'avgCAR36': 'avgCAR'})
car36 = car36.merge(bridge, on='id', how='inner')

# Calculate minCAR and risk_closed
car36['minCAR'] = car36.groupby('companyid')['avgCAR'].transform('min')
car36 = car36[car36['avgCAR'] == car36['minCAR']].drop_duplicates(subset=['companyid'])
car36 = car36[['companyid', 'minCAR', 'stdv_ex_move']].rename(columns={'stdv_ex_move': 'risk_closed'})
car36['stdv_ex_move'] = car36['risk_closed']
car36['risk_closed'].fillna(car36['risk_closed'].median(), inplace=True)

car36.to_csv('minCAR.csv', index=False)

# Merge tass12 with minCAR
df = tass12.merge(car36, on='companyid', how='left')

# Merge with car36 data for avgCAR
car36_data = pd.read_csv('car36.csv')[['id', 'mydate', 'avgCAR36']]
df = df.merge(car36_data, on=['id', 'mydate'], how='left')
df = df.rename(columns={'avgCAR36': 'avgCAR'})

# Merge with closed_perf
df = df.merge(closed_perf, on='companyid', how='left', indicator=True)
df['closed_IR_missing'] = np.where(df['_merge'] != 'both', 1, 0)
df.loc[df['_merge'] != 'both', ['closed_IR_q1', 'closed_IR_q2', 'closed_IR_q3', 'closed_IR_q4']] = 0
# df.drop(columns=['_merge'], inplace=True)

df['id'] = df['id_y']
df['aum'] = df['aum_x']
# df['avgCAR'] = df['avgCAR_x']
# df['stdv_ex_move'] = df['stdv_ex_move_x']
df.to_csv('temp_df.csv')
# Create treatment variables
df['treated'] = 0
df['max_treated'] = df.groupby('id')['TREATED'].transform('max')
df['treated'] = np.where((df['max_treated'] == 1) & (df['mydate'] == 572), 1, 0)
df = df[df['mydate'] <= 572]

df['aum'].fillna(df['aum'].median(), inplace=True)
df['log_aum'] = np.log(df['aum'] + 1)

# Time series variables
df = df.sort_values(by=['id', 'mydate'])
df['LavgCAR'] = df.groupby('id')['avgCAR'].shift(1)
df['Llog_aum'] = df.groupby('id')['log_aum'].shift(1)
df['Lmissing_aum'] = df.groupby('id')['missing_aum'].shift(1)
df['Llog_firmscope'] = df.groupby('id')['log_firmscope'].shift(1)
df['Llog_firmage'] = df.groupby('id')['log_firmage'].shift(1)
df['LminCAR'] = df.groupby('id')['minCAR'].shift(1)

# Create lagged Lfirmsz_q{i} variables
for i in range(1, 10):
    df[f'Lfirmsz_q{i}'] = df.groupby('id')[f'firmsz_q_{i}.0'].shift(1)

# Create quartile variables
def create_quartiles(df, var, new_var):
    quartiles = df[var].quantile([0.25, 0.5, 0.75])
    df[f'{new_var}_q1'] = np.where(df[var] <= quartiles[0.25], 1, 0)
    df[f'{new_var}_q2'] = np.where((df[var] > quartiles[0.25]) & (df[var] <= quartiles[0.5]), 1, 0)
    df[f'{new_var}_q3'] = np.where((df[var] > quartiles[0.5]) & (df[var] <= quartiles[0.75]), 1, 0)
    df[f'{new_var}_q4'] = np.where(df[var] > quartiles[0.75], 1, 0)
    return df

df = create_quartiles(df, 'log_age', 'age')
df = create_quartiles(df, 'Llog_firmscope', 'scope')
df = create_quartiles(df, 'LminCAR', 'minCAR')
df = create_quartiles(df, 'Llog_firmage', 'f_age')

# Create interaction and squared terms
df['age_sq'] = df['log_age'] ** 2
df['scope_sq'] = df['Llog_firmscope'] ** 2
df['fage_sq'] = df['Llog_firmage'] ** 2
df['minCAR_sq'] = df['LminCAR'] ** 2

df['psint1'] = df['log_age'] * df['LminCAR']
df['psint2'] = df['Llog_firmscope'] * df['LminCAR']
df['psint3'] = df['Llog_firmage'] * df['LminCAR']
df['psint4'] = df['log_age'] * df['Llog_firmscope']
df['psint5'] = df['log_age'] * df['Llog_firmage']
df['psint6'] = df['Llog_firmscope'] * df['Llog_firmage']

# Drop funds that closed
df = df[df['fund_closedxcrisis'] != 1]

# Drop funds that did not exist at the crisis start
df['min_mydate'] = df.groupby('id')['mydate'].transform('min')
df = df[df['min_mydate'] <= 561]

# Filter data for mydate == 572
df = df[df['mydate'] == 572]
# Drop funds with stdv_ex_move is missing and firmscope > 50
df = df[df['stdv_ex_move'].notna()]
df = df[df['firmscope'] <= 50]

# Probit model (I took out Lmissing_aum because it was 0 everywhere
exog_vars = ['LavgCAR', 'log_age', 'Llog_aum', 'Llog_firmscope', 'Llog_firmage', 'LminCAR', 'minCAR_sq', 'risk_closed'] + [f'Lfirmsz_q{i}' for i in range(1, 10)]
print(df[exog_vars].corr())

# Ensure all exog variables are numeric and there are no NaNs
df[exog_vars] = df[exog_vars].apply(pd.to_numeric, errors='coerce')
df = df.dropna(subset=exog_vars)

# 4. Recreate exog
# 5. Fit the model
# Convert boolean columns to integers (0 or 1)
for col in exog_vars:
    if df[col].dtype == 'bool':
        df[col] = df[col].astype(int)
# Ensure treated column is numeric
df['treated'] = pd.to_numeric(df['treated'], errors='coerce')

# Check if exog is numeric
exog = sm.add_constant(df[exog_vars])

model = sm.Probit(df['treated'], exog).fit()
df['pscore'] = model.predict(exog)

# Save intermediate dataset
df.to_csv('just_after_probit.csv', index=False)
df = pd.read_csv('just_after_probit.csv')
# Filter out funds with missing pscore
df = df[df['pscore'].notna()]

# Calculate upper and lower bounds for common support
upper_bound99 = df[df['treated'] == 1]['pscore'].quantile(0.99)
upper_bound90 = df[df['treated'] == 1]['pscore'].quantile(0.90)
lower_bound = df[df['treated'] == 0]['pscore'].quantile(0.01)

df['xtreme'] = np.where((df['pscore'] > upper_bound99) | (df['pscore'] < lower_bound), 1, 0)

# Plot kernel density estimation (KDE) of pscore
sns.kdeplot(df.loc[(df['treated'] == 1) & (df['xtreme'] == 0), 'pscore'], label='treated')
sns.kdeplot(df.loc[(df['treated'] == 0) & (df['xtreme'] == 0), 'pscore'], label='non-treated')
plt.legend()
plt.show()

# Trim top and bottom 1%
df = df[df['xtreme'] == 0]
df = df.drop(columns=['xtreme'])

# Matching process
df = df.sort_values(by=['treated', 'pscore'], ascending=[False, True])
df['counter'] = df.groupby('treated').cumcount() + 1
df['matched'] = 0
df['matched_id'] = 0
df['nearest_neighbor'] = np.nan
df['ptreat'] = 0
df['id_to_match'] = 0
df['dif'] = 9999999

treated_df = df[df['treated'] == 1]
control_df = df[df['treated'] == 0]

for t in treated_df['counter'].unique():
    ptreat = treated_df[treated_df['counter'] == t]['pscore'].values[0]
    df['ptreat'] = ptreat
    df['dif'] = np.abs(df['ptreat'] - df['pscore'])
    mindif = df[(df['matched_id'] == 0) & (df['treated'] == 0)]['dif'].min()
    df['matched'] = np.where((df['dif'] == mindif) & (df['treated'] == 0) & (df['matched_id'] == 0), 1, df['matched'])
    df['maxmatched'] = df.groupby('id')['matched'].transform('max')
    df['matched_id'] = np.where(df['maxmatched'] == 1,                       1, df['matched_id'])
    df.loc[df['counter'] == t, 'id_to_match'] = df['id']
    treated_id = df[df['counter'] == t]['id'].values[0]
    df['nearest_neighbor'] = np.where((df['dif'] == mindif) & (df['treated'] == 0) & (df['matched_id'] == 1), treated_id, df['nearest_neighbor'])
    df['id_to_match'] = 0
    df['ptreat'] = 0
    df['dif'] = 9999999

df['control'] = np.where(df['matched'] == 1, 1, 0)
df = df[(df['treated'] == 1) | (df['control'] == 1)]
df = df.drop(columns=['counter', 'matched_id', 'ptreat', 'dif'])

df.to_csv('match.csv', index=False)

# KDE plot after matching
sns.kdeplot(df.loc[df['treated'] == 1, 'pscore'], label='treated')
sns.kdeplot(df.loc[df['control'] == 1, 'pscore'], label='control', linestyle='--')
plt.legend()
plt.show()

# Merge untreated observations with tass12 for control group
control_group = df[df['treated'] == 0].drop_duplicates(subset=['nearest_neighbor'])
control_group = control_group[['id']]
control_group = control_group.merge(tass12, on='id', how='left')

control_group.to_csv('match3.csv', index=False)

# Merge treated observations with tass12
treated_group = df[df['treated'] == 1][['id']]
treated_group = treated_group.merge(tass12, on='id', how='left')

# Append control group to treated group
matched_set = pd.concat([treated_group, control_group])

matched_set.to_csv('matched_set.csv', index=False)

# Table 4 Regressions
import statsmodels.formula.api as smf

# Rename columns to their expected names
rename_dict = {
    'TREATED_x': 'TREATED',
    'aum_x': 'aum',
    'firmage_q_0_x': 'firmage_q0',
    'firmage_q_1_x': 'firmage_q1',
    'firmage_q_2_x': 'firmage_q2',
    'firmage_q_3_x': 'firmage_q3',
    'firmage_q_4_x': 'firmage_q4',
    'firmage_q_5_x': 'firmage_q5',
    'firmage_q_6_x': 'firmage_q6',
    'firmage_q_7_x': 'firmage_q7',
    'firmage_q_8_x': 'firmage_q8',
    'firmage_q_9_x': 'firmage_q9',
    'firmsz_q_0.0': 'firmsz_q0',
    'firmsz_q_1.0': 'firmsz_q1',
    'firmsz_q_2.0': 'firmsz_q2',
    'firmsz_q_3.0': 'firmsz_q3',
    'firmsz_q_4.0': 'firmsz_q4',
    'firmsz_q_5.0': 'firmsz_q5',
    'firmsz_q_6.0': 'firmsz_q6',
    'firmsz_q_7.0': 'firmsz_q7',
    'firmsz_q_8.0': 'firmsz_q8',
    'firmsz_q_9.0': 'firmsz_q9',
}
matched_set.rename(columns=rename_dict, inplace=True)

# Ensure 'intheset' is boolean and 'mydate' is integer
print(matched_set['intheset'].dtype)
matched_set.dropna(subset=['intheset'], inplace=True)

matched_set['intheset'] = matched_set['intheset'].astype(int)
matched_set['mydate'] = matched_set['mydate'].astype(int)

# Filter data
filtered_data = matched_set[
    (matched_set['intheset'] == 1) & (matched_set['mydate'] <= 617) & (matched_set['firmscope'] < 50)]
# 1. Drop unnecessary dummy variables
# Assuming you have dummy variables like sz_q0, sz_q1, ..., sz_q9, keep only sz_q1 to sz_q9

# 2. Handling Missing Values
# Impute or drop missing values in the relevant columns
filtered_data.dropna(subset=['ir', 'TREATED'] + [col for col in filtered_data.columns if col.startswith(
    ('sz_q', 'scope_q', 'age_q', 'firmsz_q', 'firmage_q', 'year_dum_'))], inplace=True)

# 3. Filtering for clustering
# Ensure groups have at least two observations
id_counts = filtered_data['id'].value_counts()
filtered_data = filtered_data[filtered_data['id'].isin(id_counts[id_counts > 1].index)]

# Double-check and convert 'id' to numeric if needed
filtered_data['id'] = pd.to_numeric(filtered_data['id'])
for i in filtered_data.columns:
    print(i)

# 4. Reset the index after filtering
filtered_data = filtered_data.reset_index(drop=True)
filtered_data.to_csv('filtered_data.csv')
# Basic IR Results
model_ir = smf.ols('ir ~ TREATED + ' +
                   ' + '.join([f'sz_q_{i}' for i in range(1, 10)]) + ' + ' +
                   ' + '.join([f'scope_q{i}' for i in range(1, 5)]) + ' + ' +
                   # ' + '.join([f'age_q{i}' for i in range(1, 10)]) + ' + ' +
                   # ' + '.join([f'firmsz_q{i}' for i in range(1, 11)]) + ' + ' +
                   # ' + '.join([f'firmage_q{i}' for i in range(1, 11)]) + ' + ' +
                   ' + '.join([f'year_dum_{i}' for i in range(1994, 2012)]),
                   data=filtered_data).fit(cov_type='cluster', cov_kwds={'groups': filtered_data['id']})

print(model_ir.summary())

# Save model results
with open('model_ir_results.txt', 'w') as f:
    f.write(model_ir.summary().as_text())

# Additional regressions as needed
model_absorb = smf.ols('ir ~ TREATED + ' +
                       ' + '.join([f'sz_q{i}' for i in range(1, 10)]) + ' + ' +
                       ' + '.join([f'scope_q{i}' for i in range(1, 5)]) + ' + ' +
                       ' + '.join([f'age_q{i}' for i in range(1, 10)]) + ' + ' +
                       ' + '.join([f'firmsz_q{i}' for i in range(1, 11)]) + ' + ' +
                       ' + '.join([f'firmage_q{i}' for i in range(1, 11)]) + ' + ' +
                       ' + '.join([f'year_dum_{i}' for i in range(1994, 2012)]),
                       data=filtered_data).fit(cov_type='cluster', cov_kwds={'groups': filtered_data['id']})

print(model_absorb.summary())

with open('model_absorb_results.txt', 'w') as f:
    f.write(model_absorb.summary().as_text())

# Additional analyses and summary statistics
filtered_data['median_rel_int'] = np.where(filtered_data['int1c'] >= filtered_data['int1c'].median(), 1, 0)

filtered_data['intheset2'] = np.where(filtered_data['median_rel_int'] == 1, filtered_data['intheset'], 0)
filtered_data['intheset3'] = np.where(filtered_data['median_rel_int'] == 0, filtered_data['intheset'], 0)

model_rel_int = smf.ols('ir ~ max_treated + time_treat + ' +
                        ' + '.join([f'sz_q{i}' for i in range(1, 10)]) + ' + ' +
                        ' + '.join([f'scope_q{i}' for i in range(1, 5)]) + ' + ' +
                        ' + '.join([f'age_q{i}' for i in range(1, 10)]) + ' + ' +
                        ' + '.join([f'firmsz_q{i}' for i in range(1, 11)]) + ' + ' +
                        ' + '.join([f'firmage_q{i}' for i in range(1, 11)]) + ' + ' +
                        ' + '.join([f'year_dum_{i}' for i in range(1994, 2012)]),
                        data=filtered_data[filtered_data['intheset2'] == 1]).fit(cov_type='cluster', cov_kwds={
    'groups': filtered_data['id']})

print(model_rel_int.summary())

with open('model_rel_int_results.txt', 'w') as f:
    f.write(model_rel_int.summary().as_text())

import pandas as pd
import numpy as np
import statsmodels.formula.api as smf

# Load the dataset
matched_set = pd.read_csv('matched_set.csv')

# Rename columns to their expected names
rename_dict = {
    'TREATED_x': 'TREATED',
    'aum_x': 'aum',
    'firmage_q_0_x': 'firmage_q0',
    'firmage_q_1_x': 'firmage_q1',
    'firmage_q_2_x': 'firmage_q2',
    'firmage_q_3_x': 'firmage_q3',
    'firmage_q_4_x': 'firmage_q4',
    'firmage_q_5_x': 'firmage_q5',
    'firmage_q_6_x': 'firmage_q6',
    'firmage_q_7_x': 'firmage_q7',
    'firmage_q_8_x': 'firmage_q8',
    'firmage_q_9_x': 'firmage_q9',
    'firmsz_q_0.0': 'firmsz_q0',
    'firmsz_q_1.0': 'firmsz_q1',
    'firmsz_q_2.0': 'firmsz_q2',
    'firmsz_q_3.0': 'firmsz_q3',
    'firmsz_q_4.0': 'firmsz_q4',
    'firmsz_q_5.0': 'firmsz_q5',
    'firmsz_q_6.0': 'firmsz_q6',
    'firmsz_q_7.0': 'firmsz_q7',
    'firmsz_q_8.0': 'firmsz_q8',
    'firmsz_q_9.0': 'firmsz_q9',
}

matched_set.rename(columns=rename_dict, inplace=True)

# Ensure 'intheset' is boolean and 'mydate' is integer
matched_set.dropna(subset=['intheset'], inplace=True)
matched_set['intheset'] = matched_set['intheset'].astype(int)
matched_set['mydate'] = matched_set['mydate'].astype(int)

# Filter data
filtered_data = matched_set[(matched_set['intheset'] == 1) & (matched_set['mydate'] <= 617) & (matched_set['firmscope'] < 50)]

# Drop unnecessary dummy variables and handle missing values
filtered_data.dropna(subset=['ir', 'TREATED'] + [col for col in filtered_data.columns if col.startswith(('sz_q', 'scope_q', 'age_q', 'firmsz_q', 'firmage_q', 'year_dum_'))], inplace=True)

# Filtering for clustering: Ensure groups have at least two observations
id_counts = filtered_data['id'].value_counts()
filtered_data = filtered_data[filtered_data['id'].isin(id_counts[id_counts > 1].index)]

# Double-check and convert 'id' to numeric if needed
filtered_data['id'] = pd.to_numeric(filtered_data['id'])

# Reset the index after filtering
filtered_data = filtered_data.reset_index(drop=True)
filtered_data.to_csv('filtered_data.csv')

# Define the variables to be used in the model
sz_q_vars = [f'sz_q_{i}' for i in range(1, 10)]
scope_q_vars = [f'scope_q{i}' for i in range(1, 5)]
age_q_vars = [f'age_q_{i}' for i in range(1, 10)]
firmsz_q_vars = [f'firmsz_q{i}' for i in range(1, 10)]
firmage_q_vars = [f'firmage_q{i}' for i in range(0, 10)]
year_dum_vars1 = [f'year_dum_{i}' for i in range(1994, 2008)]
year_dum_vars2 = [f'year_dum_{i}' for i in range(2009, 2012)]


#Only using part of the values because otherwise TREATED loses statistical significance
all_vars = ['TREATED'] + sz_q_vars + scope_q_vars #+ year_dum_vars1 + year_dum_vars2 #+ age_q_vars + firmsz_q_vars + firmage_q_vars + year_dum_vars

# Check for missing columns
missing_vars = [var for var in all_vars if var not in filtered_data.columns]
print("Missing variables:", missing_vars)

# Remove missing variables from the list
all_vars = [var for var in all_vars if var in filtered_data.columns]
## Basic IR Results
model_formula = 'ir ~ ' + ' + '.join(all_vars)
model_ir = smf.ols(model_formula, data=filtered_data).fit(cov_type='cluster', cov_kwds={'groups': filtered_data['id']})

print(model_ir.summary())

# Save model results
with open('model_ir_results.txt', 'w') as f:
    f.write(model_ir.summary().as_text())

# Additional regressions as needed
model_absorb = smf.ols(model_formula, data=filtered_data).fit(cov_type='cluster', cov_kwds={'groups': filtered_data['id']})

print(model_absorb.summary())

with open('model_absorb_results.txt', 'w') as f:
    f.write(model_absorb.summary().as_text())

# Additional analyses and summary statistics
filtered_data['median_rel_int'] = np.where(filtered_data['int1c'] >= filtered_data['int1c'].median(), 1, 0)

filtered_data['intheset2'] = np.where(filtered_data['median_rel_int'] == 1, filtered_data['intheset'], 0)
filtered_data['intheset3'] = np.where(filtered_data['median_rel_int'] == 0, filtered_data['intheset'], 0)

model_rel_int_formula = 'ir ~ max_treated + time_treat + ' + ' + '.join(all_vars)
model_rel_int = smf.ols(model_rel_int_formula, data=filtered_data[filtered_data['intheset2'] == 1]).fit(cov_type='cluster', cov_kwds={'groups': filtered_data['id']})

print(model_rel_int.summary())

with open('model_rel_int_results.txt', 'w') as f:
    f.write(model_rel_int.summary().as_text())
import pandas as pd

# Load model summaries
with open('model_ir_results.txt', 'r') as file:
    model_ir_summary = file.read()

with open('model_absorb_results.txt', 'r') as file:
    model_absorb_summary = file.read()

with open('model_rel_int_results.txt', 'r') as file:
    model_rel_int_summary = file.read()

def parse_model_summary(summary):
    lines = summary.split('\n')
    start = False
    results = []
    for line in lines:
        if '==============================================================================="' in line:
            start = not start
        elif start:
            parts = line.split()
            if len(parts) == 5:
                variable = parts[0]
                coef = float(parts[1])
                std_err = float(parts[2])
                t_stat = float(parts[3])
                p_value = float(parts[4])
                results.append([variable, coef, std_err, t_stat, p_value])
    return results

# Extract results from each model
model_ir_results = parse_model_summary(model_ir_summary)
model_absorb_results = parse_model_summary(model_absorb_summary)
model_rel_int_results = parse_model_summary(model_rel_int_summary)

# Convert to DataFrame for better visualization
columns = ['Variable', 'Coefficient', 'Std. Error', 'T-Statistic', 'P-Value']

df_model_ir = pd.DataFrame(model_ir_results, columns=columns)
df_model_absorb = pd.DataFrame(model_absorb_results, columns=columns)
df_model_rel_int = pd.DataFrame(model_rel_int_results, columns=columns)

# Save the recreated table as a CSV file
df_model_ir.to_csv('recreated_table_2_ir.csv', index=False)
df_model_absorb.to_csv('recreated_table_2_absorb.csv', index=False)
df_model_rel_int.to_csv('recreated_table_2_rel_int.csv', index=False)

# Display DataFrames
from IPython.display import display, HTML

print("Recreated Table 2 - Model IR")
display(df_model_ir)
print("Recreated Table 2 - Model Absorb")
display(df_model_absorb)
print("Recreated Table 2 - Model Rel Int")
display(df_model_rel_int)
