import pandas as pd
import numpy as np

# Load necessary datasets
complete_divcorr = pd.read_csv('complete_divcorr.csv')
potential_treat0 = pd.read_csv('potential_treat0.csv')

# Step 1: Make a list of every fund (id) in complete_divcorr and call it potential_treat1
divcorr_id1 = complete_divcorr[['div_cons1']].rename(columns={'div_cons1': 'id'})
divcorr_id2 = complete_divcorr[['div_cons2']].rename(columns={'div_cons2': 'id'})
potential_treat1 = pd.concat([divcorr_id1, divcorr_id2]).drop_duplicates().sort_values(by='id')
potential_treat1.to_csv('potential_treat1.csv', index=False)

# Step 2: Merge in everything from potential_treat0
potential_treat2 = potential_treat0.merge(potential_treat1, on='id', how='left')
potential_treat2['closedxcrisis'].fillna(0, inplace=True)
potential_treat2['closedxcrisis'] = potential_treat2['closedxcrisis'].astype(int)
potential_treat2['fund_closedxcrisis'] = potential_treat2.groupby('id')['closedxcrisis'].transform('max')
potential_treat2.to_csv('potential_treat2.csv', index=False)

# Step 3: Create a file of ids with min_mydate
minmydate = potential_treat2[potential_treat2['mydate'] == potential_treat2['min_mydate']]
minmydate = minmydate[['id', 'min_mydate']]
minmydate.to_csv('minmydate.csv', index=False)

oth_minmydate = minmydate.rename(columns={'id': 'other_fund', 'min_mydate': 'oth_minmydate'})
oth_minmydate.to_csv('oth_minmydate.csv', index=False)

# Step 4: Eliminate "twins"
# Batch 1
batch1 = complete_divcorr[['companyid', 'div_cons1', 'div_cons2', 'div_corr', 'corr_eps']]
batch1 = batch1.rename(columns={'div_cons1': 'id', 'div_cons2': 'other_fund'})
batch1.to_csv('batch1.csv', index=False)

# Batch 2
batch2 = complete_divcorr[['companyid', 'div_cons1', 'div_cons2', 'div_corr', 'corr_eps']]
batch2 = batch2.rename(columns={'div_cons2': 'id', 'div_cons1': 'other_fund'})
batch2 = pd.concat([batch2, batch1]).drop_duplicates().sort_values(by=['companyid', 'id', 'other_fund'])

batch2 = batch2.merge(minmydate, on='id', how='inner').rename(columns={'min_mydate': 'id_minmydate'})
batch2 = batch2.merge(oth_minmydate, on='other_fund', how='inner')
batch2.to_csv('batch2.csv', index=False)

# Batch 3: Focus on (unique) funds with div_corr > 0.985
batch3 = batch2.copy()
batch3['corr_eps'].replace(-999, np.nan, inplace=True)
batch3 = batch3[batch3['div_corr'] > 0.985]
batch3.drop_duplicates(subset=['id', 'other_fund'], inplace=True)

batch3['keep_id'] = np.where(batch3['id_minmydate'] <= batch3['oth_minmydate'], 1, 0)
batch3['keep_other_fund'] = np.where(batch3['oth_minmydate'] < batch3['id_minmydate'], 1, 0)
batch3.to_csv('batch3.csv', index=False)

# Batch 4: Identify other_fund ids when keep_id==0 for an id and rename other_fund id
batch4 = batch3[batch3['keep_id'] == 0][['other_fund', 'div_corr']]
batch4 = batch4.rename(columns={'other_fund': 'id'})
batch4.to_csv('batch4.csv', index=False)

# Highcorr_set: Set of funds to be kept, even though they are highly correlated
highcorr_set = pd.concat([
    batch3[batch3['keep_other_fund'] == 0][['id', 'div_corr']],
    batch4
]).drop_duplicates(subset=['id']).sort_values(by='id')
highcorr_set.to_csv('highcorr_set.csv', index=False)

# Dropcorr_set: Set of "twin" funds to be dropped
dropcorr_set = batch3[['id']].drop_duplicates().sort_values(by='id')
dropcorr_set = dropcorr_set.merge(highcorr_set, on='id', how='left', indicator=True)
dropcorr_set = dropcorr_set[dropcorr_set['_merge'] == 'left_only'].drop(columns=['_merge'])
dropcorr_set.to_csv('dropcorr_set.csv', index=False)

# Define the test set
intheset = potential_treat2.copy()
intheset = intheset.merge(dropcorr_set, on='id', how='left', indicator=True)
intheset['intheset'] = 1
intheset.loc[intheset['crisis'] == 1, 'intheset'] = 0
intheset.loc[intheset['fund_closedxcrisis'] == 1, 'intheset'] = 0
intheset.loc[intheset['min_mydate'] > 562, 'intheset'] = 0
intheset.loc[intheset['_merge'] == 'both', 'intheset'] = 0
intheset.drop(columns=['_merge'], inplace=True)
intheset = intheset[intheset['intheset'] == 1]

intheset['intheset2'] = np.where((intheset['mydate'] <= 625) & (intheset['mydate'] >= 617), 0, intheset['intheset'])
intheset['counter'] = intheset.groupby('id').cumcount() + 1
intheset['maxcounter'] = intheset.groupby('id')['counter'].transform('max')
intheset['intheset'] = np.where(intheset['maxcounter'] < 12, 0, intheset['intheset'])

intheset = intheset[intheset['intheset'] == 1][['id', 'mydate', 'intheset', 'intheset2']]
intheset.to_csv('intheset.csv', index=False)

# Bring in all pairwise correlations
integrate2 = complete_divcorr[['companyid', 'div_cons1', 'div_cons2', 'div_corr', 'corr_eps']]
integrate2 = integrate2.rename(columns={'div_cons2': 'id', 'div_cons1': 'other_fund'})
integrate2 = pd.concat([integrate2, batch1]).drop_duplicates().sort_values(by=['companyid', 'id', 'other_fund'])
integrate2['corr_eps'].replace(-999, np.nan, inplace=True)
integrate2.to_csv('integrate2.csv', index=False)

# Identify funds with div_corr that were closed during the crisis
closed = potential_treat2[potential_treat2['closedxcrisis'] == 1][['id']]
closed.to_csv('closed.csv', index=False)

# Merge closed fund with list of funds w/div_corr to find the "real" treatments
integrate3 = closed.merge(integrate2, on='id', how='inner')
integrate3['treatment99'] = np.where(integrate3['div_corr'] < 0.985, 1, 0)
integrate3['treatment90'] = np.where(integrate3['div_corr'] < 0.895, 1, 0)
integrate3['treatment99_eps'] = np.where((integrate3['corr_eps'] < 0.985) & (integrate3['corr_eps'].notna()), 1, 0)
integrate3['treatment90_eps'] = np.where((integrate3['corr_eps'] < 0.895) & (integrate3['corr_eps'].notna()), 1, 0)

integrate3 = integrate3.rename(columns={'id': 'treated_id', 'other_fund': 'id'}).sort_values(by=['companyid', 'id'])
integrate3.to_csv('integrate3.csv', index=False)

# Merge with potential_treat2
integrate3 = integrate3.merge(potential_treat2, on=['companyid', 'id'], how='outer')

# DIV_CORR < 0.985
integrate3['closedxcrisis2'] = integrate3['closedxcrisis']
integrate3['closedxcrisis3'] = integrate3['closedxcrisis']
integrate3['closedxcrisis4'] = integrate3['closedxcrisis']
integrate3.loc[integrate3['div_corr'] >= 0.985, 'closedxcrisis'] = 0
integrate3['fund_closedxcrisis'] = integrate3.groupby('id')['closedxcrisis'].transform('max')



# Instantaneous and constant FIRM measures of closure during the crisis
integrate3['firm_closedxcrisis'] = integrate3.groupby(['companyid', 'mydate'])['closedxcrisis'].transform('max')
integrate3['max_firm_closedxcrisis'] = integrate3.groupby('companyid')['closedxcrisis'].transform('max')

# A fund cannot be treated if it started within one year of the financial crisis
integrate3.loc[integrate3['min_mydate'] > 562, 'max_firm_closedxcrisis'] = 0
integrate3.loc[integrate3['div_corr'] >= 0.985, 'max_firm_closedxcrisis'] = 0

# crisis_treat24 equals one for two years after the end of the crisis
integrate3['crisis_treat24'] = 0
integrate3.loc[(integrate3['max_firm_closedxcrisis'] == 1) & (integrate3['mydate'] >= 595) & (integrate3['mydate'] <= 619), 'crisis_treat24'] = 1

# DIV_CORR < 0.895
integrate3.loc[integrate3['div_corr'] >= 0.895, 'closedxcrisis2'] = 0
integrate3['fund_closedxcrisis2'] = integrate3.groupby('id')['closedxcrisis2'].transform('max')

# Instantaneous and constant FIRM measures of closure during the crisis
integrate3['firm_closedxcrisis2'] = integrate3.groupby(['companyid', 'mydate'])['closedxcrisis2'].transform('max')
integrate3['max_firm_closedxcrisis2'] = integrate3.groupby('companyid')['closedxcrisis2'].transform('max')

# A fund cannot be treated if it started within one year of the financial crisis
integrate3.loc[integrate3['min_mydate'] > 562, 'max_firm_closedxcrisis2'] = 0
integrate3.loc[integrate3['div_corr'] >= 0.895, 'max_firm_closedxcrisis2'] = 0

# crisis_treat24 equals one for two years after the end of the crisis
integrate3['crisis_treat24_90'] = 0
integrate3.loc[(integrate3['max_firm_closedxcrisis2'] == 1) & (integrate3['mydate'] >= 595) & (integrate3['mydate'] <= 619), 'crisis_treat24_90'] = 1

# CORR_EPS < 0.985
integrate3.loc[integrate3['corr_eps'] >= 0.985, 'closedxcrisis3'] = 0
integrate3['fund_closedxcrisis3'] = integrate3.groupby('id')['closedxcrisis3'].transform('max')

# Instantaneous and constant FIRM measures of closure during the crisis
integrate3['firm_closedxcrisis3'] = integrate3.groupby(['companyid', 'mydate'])['closedxcrisis3'].transform('max')
integrate3['max_firm_closedxcrisis3'] = integrate3.groupby('companyid')['closedxcrisis3'].transform('max')

# A fund cannot be treated if it started within one year of the financial crisis
integrate3.loc[integrate3['min_mydate'] > 562, 'max_firm_closedxcrisis3'] = 0
integrate3.loc[integrate3['div_corr'] >= 0.985, 'max_firm_closedxcrisis3'] = 0

# crisis_treat24 equals one for two years after the end of the crisis
integrate3['crisis_treat24_99eps'] = 0
integrate3.loc[(integrate3['max_firm_closedxcrisis3'] == 1) & (integrate3['mydate'] >= 595) & (integrate3['mydate'] <= 619), 'crisis_treat24_99eps'] = 1

# CORR_EPS < 0.895
integrate3.loc[integrate3['corr_eps'] >= 0.895, 'closedxcrisis4'] = 0
integrate3['fund_closedxcrisis4'] = integrate3.groupby('id')['closedxcrisis4'].transform('max')

# Instantaneous and constant FIRM measures of closure during the crisis
integrate3['firm_closedxcrisis4'] = integrate3.groupby(['companyid', 'mydate'])['closedxcrisis4'].transform('max')
integrate3['max_firm_closedxcrisis4'] = integrate3.groupby('companyid')['closedxcrisis4'].transform('max')

# A fund cannot be treated if it started within one year of the financial crisis
integrate3.loc[integrate3['min_mydate'] > 562, 'max_firm_closedxcrisis4'] = 0
integrate3.loc[integrate3['div_corr'] >= 0.895, 'max_firm_closedxcrisis4'] = 0

# crisis_treat24 equals one for two years after the end of the crisis
integrate3['crisis_treat24_90eps'] = 0
integrate3.loc[(integrate3['max_firm_closedxcrisis4'] == 1) & (integrate3['mydate'] >= 595) & (integrate3['mydate'] <= 619), 'crisis_treat24_90eps'] = 1

integrate3.to_csv('integrate4.csv', index=False)

# Clean up
import os
files_to_erase = [
    'batch1.csv', 'batch3.csv', 'batch4.csv', 'potential_treat1.csv',
    'integrate2.csv', 'highcorr_set.csv'
]

for file in files_to_erase:
    if os.path.exists(file):
        os.remove(file)

print("Integration completed and temporary files cleaned up.")
