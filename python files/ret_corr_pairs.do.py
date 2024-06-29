import pandas as pd

# Load the potential_divcorr dataset
potential_divcorr = pd.read_csv('potential_divcorr.csv')

# Step 1: Count the number of funds per firm at any given point in time (simulcounter)
potential_divcorr['simulcounter'] = potential_divcorr.groupby(['companyid', 'mydate']).cumcount() + 1
potential_divcorr['maxsimulcounter'] = potential_divcorr.groupby('companyid')['simulcounter'].transform('max')
simulcounter_df = potential_divcorr.drop_duplicates(subset=['companyid']).copy()
simulcounter_df = simulcounter_df[['companyid', 'maxsimulcounter']].rename(columns={'maxsimulcounter': 'simulcounter'})
# Save simulcounter data
simulcounter_df.to_csv('simulcounter.csv', index=False)
# Step 2: Count the number of funds per firm and filter firms with at least two funds simultaneously
potential_divcorr = pd.merge(potential_divcorr, simulcounter_df, on='companyid', how='inner')
potential_divcorr['simulcounter'] = potential_divcorr['simulcounter_y']
potential_divcorr = potential_divcorr[potential_divcorr['simulcounter'] > 1]

# Step 3: Create a sequential fund identifier within the firm (fundcounter)
fundcounter_df = potential_divcorr.groupby('id').agg({'companyid': 'max', 'mydate': 'min'}).reset_index()
fundcounter_df = fundcounter_df.sort_values(by=['companyid', 'mydate', 'id'])
fundcounter_df['fund_counter'] = fundcounter_df.groupby('companyid').cumcount() + 1
fundcounter_df = fundcounter_df[['companyid', 'id', 'fund_counter']]

# Save fundcounter data
fundcounter_df.to_csv('fundcounter.csv', index=False)

# Step 4: Create a database of error terms from the 7-factor regressions
potential_divcorr['epsilon'] = potential_divcorr['excess_ret'] - potential_divcorr['alpha']
epsilon_df = potential_divcorr[['id', 'mydate', 'epsilon']]

# Save epsilon data
epsilon_df.to_csv('epsilon.csv', index=False)
potential_divcorr.to_csv('potential_divcorr.csv', index=False)