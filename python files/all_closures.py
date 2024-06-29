import pandas as pd
import numpy as np

# Load the mydate converter
mydate_converter = pd.read_csv('mydate_converter.csv', header=None, names=['year', 'month', 'mydate'], skiprows=[0])

# Load the tass5 dataset
tass5 = pd.read_csv('tass5.csv')

# Calculate min and max mydate for each fund
tass5['min_mydate'] = tass5.groupby('id')['mydate'].transform('min')
tass5['max_mydate'] = tass5.groupby('id')['mydate'].transform('max')

# Generate the starts data
starts = tass5[['id', 'min_mydate']].drop_duplicates()
starts = starts.groupby('min_mydate').size().reset_index(name='starts')
starts.rename(columns={'min_mydate': 'mydate'}, inplace=True)

# Generate the closures data
closures = tass5[['id', 'max_mydate']].drop_duplicates()
closures = closures.groupby('max_mydate').size().reset_index(name='closures')
closures.rename(columns={'max_mydate': 'mydate'}, inplace=True)

# Merge starts and closures data
open_close = pd.merge(starts, closures, on='mydate', how='outer').fillna(0)

# Merge with mydate converter
open_close = pd.merge(open_close, mydate_converter, on='mydate', how='left')

# Save the open_close data to Excel
open_close.to_excel('open_close_TASS2015.xlsx', index=False)

# Aggregate data by year
open_close_year = open_close.groupby('year').sum().reset_index()
open_close_year = open_close_year[['year', 'starts', 'closures']]

# Save the open_close_year data to Excel
open_close_year.to_excel('open_close_TASS2015_year.xlsx', index=False)

# Generate the all_close_treat data
tass5 = tass5[['id', 'companyid', 'mydate', 'min_mydate', 'max_mydate']].drop_duplicates()
tass5['closed'] = np.where((tass5['mydate'] == tass5['max_mydate']) & (tass5['max_mydate'] <= 653), 1, 0)
tass5['opened'] = np.where((tass5['mydate'] == tass5['min_mydate']) & (tass5['min_mydate'] >= 409), 1, 0)

# Collapse data by companyid and mydate
collapsed_data = tass5.groupby(['companyid', 'mydate']).sum().reset_index()

# Create lagged closed variables
for i in range(1, 31):
    collapsed_data[f'L{i}closed'] = collapsed_data.groupby('companyid')['closed'].shift(i).fillna(0)

# Calculate net openings and closings
collapsed_data['net'] = collapsed_data['opened'] - collapsed_data[[f'L{i}closed' for i in range(1, 13)]].sum(axis=1)

# Create open_close and all_close_treat variables
collapsed_data['open_close'] = np.where((collapsed_data['opened'] == 1) & (collapsed_data['net'] <= 0), 1, 0)
collapsed_data['all_close_treat'] = collapsed_data[[f'L{i}closed' for i in range(1, 31)]].max(axis=1)
collapsed_data['time_treat_all'] = np.argmax(collapsed_data[[f'L{i}closed' for i in range(1, 31)]].values >= 1, axis=1) + 1
collapsed_data['time_treat_all'] = np.where(collapsed_data['all_close_treat'] >= 1, collapsed_data['time_treat_all'], 0)

# Keep necessary columns and sort
collapsed_data = collapsed_data[['companyid', 'mydate', 'all_close_treat', 'time_treat_all']].sort_values(by=['companyid', 'mydate'])

# Save the all_close_treat data
collapsed_data.to_csv('all_close_treat.csv', index=False)
