# Independent classifier evaluation

## Current status

**Independent evaluation data is unavailable in this repository.** The active
classifier remains `scamshield-classifier-v5`; no model, threshold, dataset, or
knowledge-base changes are made by this protocol. Existing validation and
project held-out metrics are not independent real-world accuracy.

## Protocol

Run `ml/scripts/evaluate_independent.py` only with a separately sourced and
labelled CSV. The input must contain `text` and `label` (`scam` or `genuine`),
and may include `language` and `scam_category`. The runner rejects the
canonical dataset and every file under `ml/data/processed/`, loads the active
v5 artifacts, applies the production text preprocessor, and only predicts.
It does not fit a model, select hyperparameters, tune thresholds, or write
training data. A source description is mandatory; provenance and labeling
quality still require human review.

Example, after an independently approved corpus is supplied:

```powershell
python ml\scripts\evaluate_independent.py `
  --dataset D:\approved-evaluation\messages.csv `
  --source-description "Campaign-separated, independently labeled corpus" `
  --output ml\reports\independent_evaluation.json
```

The report includes accuracy, scam precision/recall/F1, a confusion matrix,
false-positive and false-negative counts, and language/category metrics when
sample thresholds are met. The output must not be described as representative
of real-world performance unless its sampling and annotation methodology
support that claim.
