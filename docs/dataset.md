# Canonical dataset

The one active training-data source is
[`ml/data/raw/scamshield_dataset.csv`](../ml/data/raw/scamshield_dataset.csv).
The 8,424-row file is balanced across scam/genuine labels and English, Hindi,
and Telugu. It contains text examples; image OCR, email/PDF extraction, and
audio transcription convert their inputs to text before using this same
classifier.

| Property | Value |
| --- | ---: |
| Rows | 8,424 |
| Scam / genuine | 4,212 / 4,212 |
| English / Hindi / Telugu | 2,808 / 2,808 / 2,808 |
| Categories | 100 |
| Pattern IDs | 300 |

The canonical raw CSV is validated in place. The split script maps `category`
to `scam_category` in memory, normalizes labels/languages/severity, and records
dataset provenance in the processed splits. The canonical source file is never
modified.

## Grouped splits

The active split metadata lives at
[`ml/data/processed/scamshield-dataset-8424-v10.1/split_metadata.json`](../ml/data/processed/scamshield-dataset-8424-v10.1/split_metadata.json).
Splits are stratified by label and language and grouped by `pattern_id` so a
pattern cannot occur in more than one split.

| Split | Rows | Genuine | Scam |
| --- | ---: | ---: | ---: |
| Train | 5,916 | 2,952 | 2,964 |
| Validation | 1,249 | 625 | 624 |
| Test | 1,259 | 635 | 624 |

Validation confirms every source ID appears exactly once, processed text does
not leak between splits, and pattern groups are disjoint. The source contains
template-style pattern variants, so even a grouped split is not a substitute
for independent real-world evaluation.

## Model evaluation

The currently trained `scamshield-classifier-v5` achieved 99.92% validation
accuracy and 100% (1,259/1,259) on this held-out test split. This is a measured
offline result for this dataset and split only, not a claim of 100% real-world
accuracy. The template-like examples and limited independent campaign coverage
can make held-out results unusually high.

## Rebuild and validate

From the repository root, using the backend virtual environment:

```powershell
backend\venv\Scripts\python.exe ml\scripts\validate_canonical_dataset.py
backend\venv\Scripts\python.exe ml\scripts\split_dataset.py
backend\venv\Scripts\python.exe ml\scripts\validate_dataset.py
backend\venv\Scripts\python.exe ml\scripts\train_classifier.py
backend\venv\Scripts\python.exe ml\scripts\evaluate.py
```

Choose a new unused `SCAMSHIELD_MODEL_VERSION` before retraining; versioned
model directories are not overwritten. Do not create additional raw training
copies or augment this canonical corpus in place.
