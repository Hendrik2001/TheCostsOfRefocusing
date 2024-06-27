import pandas as pd
import numpy as np

# Load the dataset
df = pd.read_csv('tass5.csv')

# Ensure the dataframe is sorted by 'id' and 'mydate'
df = df.sort_values(by=['id', 'mydate'])

# Calculate the moving average of excess returns over the past 12 months
df['moveave_ex'] = df.groupby('id')['excess_ret'].transform(lambda x: x.rolling(window=12, min_periods=1).mean())

# Calculate the sum of squared deviations from the moving average
def sum_sq_ex(group):
    return ((group['excess_ret'] - group['moveave_ex'])**2).rolling(window=12, min_periods=1).sum()

df['sum_sq_ex'] = df.groupby('id').apply(sum_sq_ex).reset_index(level=0, drop=True)

# Calculate the variance of the moving average and the standard deviation
df['var_ex_move'] = df['sum_sq_ex'] / 12
df['stdv_ex_move'] = np.sqrt(df['var_ex_move'])

# Drop unnecessary columns
df = df.drop(columns=['sum_sq_ex', 'var_ex_move'])

# Generate a counter for each id
df['counter'] = df.groupby('id').cumcount() + 1

# Generate the retdum column
df['retdum'] = np.where(df['excess_ret'].notna(), 1, 0)

# Calculate retcounter for various lengths up to 36
for i in range(1, 37):
    df[f'retcounter{i}'] = df.groupby('id')['retdum'].transform(lambda x: x.shift(i).rolling(window=i, min_periods=1).sum())

# Determine the maximum retcounter value for each row
df['retcounter'] = df[[f'retcounter{i}' for i in range(1, 37)]].bfill(axis=1).iloc[:, 0]

# Calculate the CAR values for various lengths up to 36
for i in range(1, 37):
    df[f'CAR{i}'] = df.groupby('id')['excess_ret'].transform(lambda x: x.shift(i).rolling(window=i, min_periods=1).sum())

# Determine the appropriate CAR value based on retcounter
df['CARstar'] = np.nan
for i in range(1, 37):
    df['CARstar'] = np.where(df['retcounter'] >= i, df[f'CAR{i}'], df['CARstar'])

# Adjust retcounter values greater than 36 to 36
df['retcounter'] = np.where(df['retcounter'] > 36, 36, df['retcounter'])

# Calculate the average CAR over the period
df['avgCAR36'] = df['CARstar'] / df['retcounter']

# Save the intermediate result to a CSV file
df.to_csv('car36a.csv', index=False)

# Filter out rows where excess is missing
df = df[df['excess_ret'].notna()]

# Keep only necessary columns
df = df[['id', 'mydate', 'avgCAR36', 'stdv_ex_move']]

# Save the final result to a CSV file
df.to_csv('car36.csv', index=False)
