# The Costs of Refocusing

**Bachelor's Thesis — Causal Machine Learning on Institutional Hedge Fund Data**

An empirical study into the performance consequences of hedge funds refocusing their investment strategy, using causal inference methods on a proprietary institutional dataset spanning the entire hedge fund universe.

## Research Question

When a hedge fund shifts its stated investment strategy — changing style, sector focus, or geographic mandate — does that refocusing *cause* worse performance, or do funds simply refocus *because* they are already underperforming? Disentangling causality from selection bias is the core challenge this thesis addresses.

## Approach

Naive regression on observational fund data is confounded: funds that refocus are not a random sample. This thesis applies a two-stage causal inference pipeline to recover unbiased treatment effects:

1. **Propensity Score Estimation** — models the probability of a fund refocusing given observable fund characteristics (AUM, age, past returns, strategy drift), used to control for selection into treatment
2. **Difference-in-Differences (DiD)** — compares performance trajectories of refocusing vs. non-refocusing funds before and after the event, absorbing time-invariant fund heterogeneity
3. **Causal Regression** — extends the DiD framework with doubly-robust estimation, combining the propensity model and outcome model to produce consistent estimates even if one is misspecified

## Data

The analysis uses the **Aurum hedge fund database** — a proprietary institutional dataset covering fund-level returns, AUM, strategy classifications, and fund lifecycle events across the full hedge fund universe. Due to data licensing restrictions, the repository includes a synthetic dataset that replicates the statistical properties of the original for code reproducibility.

## Key Files

| Notebook | Purpose |
|---|---|
| `Data Preparation.ipynb` | Raw data cleaning, variable construction, fund-level filters, strategy classification |
| `Regression.ipynb` | Baseline OLS regressions reproducing Table 2 results |
| `Pscore&ClosedPerf.ipynb` | Propensity score estimation and closed-fund performance analysis |
| `CausalRegression.ipynb` | Doubly-robust causal inference model — main contribution |
| `RegressionDiD.ipynb` | Difference-in-Differences specification |

Supporting outputs in `Factors/`, `Summary Statistics/`, and `TABLE2 Results/`.

## Tech Stack

- Python (pandas, numpy, scikit-learn, statsmodels)
- Jupyter Notebooks
- Causal inference: propensity score matching, DiD, doubly-robust estimation

## Running the Code

Execute notebooks in order:

```
1. Data Preparation.ipynb
2. Regression.ipynb
3. Pscore&ClosedPerf.ipynb
4. CausalRegression.ipynb
```

The included synthetic dataset (`merged_df.csv`) allows the full pipeline to run — regression coefficients will not match the thesis results but the methodology is fully reproducible.
