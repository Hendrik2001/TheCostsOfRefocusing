import pandas as pd
import numpy as np

# Load datasets
tass12 = pd.read_csv('tass12.csv')
car36 = pd.read_csv('car36.csv')

# Create the bridge dataset
bridge = tass12[['id', 'companyid']].drop_duplicates()
bridge.to_csv('bridge.csv', index=False)

# Create the closed_set dataset
closed_set = tass12[tass12['fund_closedxcrisis'] == 1][['mydate', 'companyid', 'id']]
closed_set.to_csv('closed_set.csv', index=False)

# Process car36 dataset
car36_filtered = car36[car36['mydate'] == 572][['id', 'avgCAR36', 'stdv_ex_move']]
car36_filtered = car36_filtered.rename(columns={'avgCAR36': 'avgCAR'})
car36_filtered = car36_filtered.sort_values(by='id')

# Merge with bridge
car36_merged = car36_filtered.merge(bridge, on='id', how='inner')

# Calculate closed_IR
car36_merged['closed_IR'] = car36_merged['avgCAR'] / car36_merged['stdv_ex_move']
car36_merged = car36_merged.drop(columns=['avgCAR', 'stdv_ex_move'])

# Calculate min_perf
car36_merged['min_perf'] = car36_merged.groupby('companyid')['closed_IR'].transform('min')

# Keep rows with min_perf
car36_merged = car36_merged[car36_merged['closed_IR'] == car36_merged['min_perf']]
car36_merged = car36_merged.drop_duplicates(subset=['companyid'])

# Create closed_IR quartiles
car36_merged['closed_IR_q1'] = (car36_merged['closed_IR'] <= car36_merged['closed_IR'].quantile(0.25)).astype(int)
car36_merged['closed_IR_q2'] = ((car36_merged['closed_IR'] > car36_merged['closed_IR'].quantile(0.25)) & (car36_merged['closed_IR'] <= car36_merged['closed_IR'].quantile(0.50))).astype(int)
car36_merged['closed_IR_q3'] = ((car36_merged['closed_IR'] > car36_merged['closed_IR'].quantile(0.50)) & (car36_merged['closed_IR'] <= car36_merged['closed_IR'].quantile(0.75))).astype(int)
car36_merged['closed_IR_q4'] = (car36_merged['closed_IR'] > car36_merged['closed_IR'].quantile(0.75)).astype(int)

car36_merged = car36_merged.drop(columns=['closed_IR'])

# Save the final closed_perf dataset
car36_merged = car36_merged.sort_values(by='companyid')
car36_merged.to_csv('closed_perf.csv', index=False)
