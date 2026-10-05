# Machine-learning and retrieval pipeline

## Classifier

ScamShield trains one word-level TF-IDF / Logistic Regression classifier for
text. Image OCR, email parsing, PDF extraction, and audio transcription feed
extracted text to the same classifier.

- Active model: `scamshield-classifier-v5`
- Training source: `ml/data/raw/scamshield_dataset.csv`
- Dataset version: `scamshield-dataset-8424-v10.1`
- Train / validation / test rows: 5,916 / 1,249 / 1,259
- Split isolation: stratified by label and language, grouped by `pattern_id`
- TF-IDF: word 1- and 2-grams, maximum 10,000 features, sublinear term
  frequency
- Classifier: balanced Logistic Regression, `random_state=42`, `max_iter=1000`

The active model metadata is
[`ml/models/classifier/model_metadata.json`](../ml/models/classifier/model_metadata.json);
versioned artifacts are under
[`ml/models/classifier/scamshield-classifier-v5/`](../ml/models/classifier/scamshield-classifier-v5).

On the current grouped split, validation accuracy was 99.92% and held-out test
accuracy was 100% (1,259/1,259). These are offline metrics for this particular
template-style corpus, not expected or guaranteed real-world accuracy.
Independent, campaign-separated and future-message testing is still needed.

## Canonical knowledge base and RAG

The sole KB source is
[`ml/data/raw/knowledge_base.json`](../ml/data/raw/knowledge_base.json), V10.1:

- 324 total knowledge articles: 195 scam patterns, 105 genuine patterns, and
  24 external guidance articles
- External guidance is kept as supporting evidence, not as training examples
- English, Hindi, and Telugu variants for every article and external document

The ingestion validates the schema, synchronizes one SQL knowledge entry per
article/source, and indexes each language variant separately in the Chroma
collection `scamshield_knowledge` (972 localized documents). Outdated
curated/audited SQL entries are retired and their managed vectors removed;
manual/admin knowledge entries are retained.

Analysis passes its detected or selected language to retrieval. RAG searches
that language first, uses another language only to fill a short result set,
and includes external guidance only as supporting evidence. Localized safe
actions are passed to the analysis and stored with its evidence so analysis
history keeps the original language-specific guidance.

The embedding model is `paraphrase-multilingual-MiniLM-L12-v2`; the collection
uses cosine distance, top-k 5, and minimum similarity 0.3. RAG evaluation is
an exploratory benchmark over dataset-derived held-out examples and is not an
independent human-labeled benchmark. The 50-query report currently records
Hit@1 48%, Hit@3 62%, Hit@5 62%, MRR 0.540, and evidence coverage 100%.
Exact scam-category coverage on the held-out scam rows is 624/624. Because the
KB and test examples share dataset-derived category structure, these scores
should not be treated as independent real-world retrieval quality.

## Sync and evaluation

From the repository root:

```powershell
backend\venv\Scripts\python.exe ml\scripts\clean_knowledgebase.py
backend\venv\Scripts\python.exe ml\scripts\build_vector_db.py
backend\venv\Scripts\python.exe ml\scripts\evaluate_rag.py
```

The knowledge validator does not rewrite the supplied KB. The sync script is
idempotent and preserves unrelated/manual knowledge records. Apply the backend
Alembic migration (`202610060001`) before deploying the evidence-language
columns:

```powershell
Set-Location backend
..\backend\venv\Scripts\python.exe -m alembic -c alembic.ini upgrade head
```

## Risk score

The application risk score combines scam probability with deterministic
heuristics; it is not a calibrated probability.

| Risk score | Level |
| ---: | --- |
| 0–29 | LOW |
| 30–59 | MEDIUM |
| 60–79 | HIGH |
| 80–100 | CRITICAL |

Thresholds are defined in
[`backend/app/services/risk_engine.py`](../backend/app/services/risk_engine.py).
