# Modelling-Women-s-Labour-Force-Participation
# Women's Labour Force Participation — Probit Analysis

A statistical analysis of the determinants of female labour force participation,
using a probit regression model fitted in R.

## Overview

This project estimates the probability that a woman participates in the labour
force, based on three predictors:

| Variable | Description |
|---|---|
| `inlf` | Outcome — in labour force (1) or not (0) |
| `educ` | Years of education |
| `kidslt6` | Number of children under 6 |
| `nwifeinc` | Other household income, in thousands of dollars |

**Sample size:** 250 observations · 114 in the labour force (45.6%), 136 not (54.4%)

## Why a probit model

The outcome is binary, which rules out ordinary least squares for three reasons:

1. A linear model can produce fitted values outside [0, 1], which are not valid probabilities
2. The errors follow a Bernoulli distribution, not a normal one
3. The variance of a binary outcome is π(1−π), which depends on the mean — so the errors are heteroscedastic by construction

Probit models the outcome as a latent continuous variable (a woman's propensity to
participate) that crosses a threshold, using the standard normal CDF to constrain
predicted probabilities to (0, 1).

## Results

### Fitted model

P(inlf = 1 | X) = Φ(−0.9452 + 0.1395·educ − 0.7533·kidslt6 − 0.0302·nwifeinc)

| Term | Estimate | Std. Error | z | p |
|---|---|---|---|---|
| (Intercept) | −0.9452 | 0.5164 | −1.831 | 0.0672 |
| `educ` | 0.1395 | 0.0417 | 3.345 | 0.0008 |
| `kidslt6` | −0.7533 | 0.1546 | −4.872 | 1.1e−06 |
| `nwifeinc` | −0.0302 | 0.0078 | −3.861 | 0.0001 |

All three predictors are significant at the 0.1% level and carry the expected sign.
Null deviance 344.64 on 249 df → residual deviance 292.13 on 246 df.

### Marginal effects

At a reference case (12 years education, no children under 6, $20,000 other income;
baseline probability 55.0%):

| Change | Effect on predicted probability |
|---|---|
| +1 year of education | +5.5 percentage points |
| +1 child under 6 | −28.5 percentage points |
| +$10,000 other household income | −12.0 percentage points |

### Nonlinearity

The same coefficient produces different probability changes depending on where the
individual sits on the curve — one child under six costs 23.7 points at 9 years of
education, peaks at 29.0 points at 15 years, and falls to 24.9 points at 18 years.
This is why probit coefficients cannot be read directly as changes in probability.

## Key files

| File | Description |
|---|---|
| `labor_participation.csv` | Source dataset (250 observations) |
| `analysis.R` | Full analysis — EDA, model, post hoc, figures |

## Requirements

```r
install.packages(c("ggplot2", "dplyr", "gridExtra", "scales"))
