# Dataset Information

## Source
The primary dataset used for M3 is `scamshield_dataset_2000_cleaned.csv`.

## Composition
- **Total Samples**: 2,000
- **Languages**: 
  - English: 1,500
  - Hindi: 250
  - Telugu: 250
- **Class Balance**: 
  - Genuine: 1,000
  - Scam: 1,000

## Processing
The dataset was split using a stratified approach based on `label + language`. 
- Train: 1,400 (70%)
- Validation: 300 (15%)
- Test: 300 (15%)

No data leakage occurs between splits. Duplicate text dropping logic is applied prior to splitting.
