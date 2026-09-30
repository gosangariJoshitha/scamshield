# ML Pipeline Architecture

## Overview
ScamShield Milestone 3 implements a robust Machine Learning and Risk Engine pipeline for binary classification of suspicious text content.

## ML Architecture
- **Features**: TF-IDF Vectorization with char/word n-grams (1,2) max 10,000 features.
- **Classifier**: Logistic Regression with balanced class weights.
- **Dataset**: 2,000 multilingual samples (1500 EN, 250 HI, 250 TE), perfectly balanced (1000 Genuine, 1000 Scam).
- **Split Strategy**: 70% Train, 15% Validation, 15% Test. Stratified by label and language.
- **Preprocessing**: Unicodedata normalization, whitespace cleaning. We intentionally do NOT aggressively stem or remove URLs/numbers, as they are strong scam indicators.

## Risk Engine
The application risk score is an application-level heuristic and is not a scientifically validated probability of scam.

**Thresholds:**
- LOW: 0-29
- MEDIUM: 30-59
- HIGH: 60-79
- CRITICAL: 80-100

**Scoring Logic:**
`Base Score = ML Scam Probability * 100`
Heuristic adjustments (+5 to +10) are applied for specific signals like OTP requests, high-urgency keywords, or KYC document mentions.

## Limitations
- Dataset is finite and may not cover emerging zero-day scam techniques.
- Multilingual performance depends on available training examples.
- ML probability is model confidence, not absolute certainty.
- RAG and LLM reasoning are not yet part of M3.
