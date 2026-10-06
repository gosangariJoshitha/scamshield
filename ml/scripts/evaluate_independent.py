"""Evaluate the active classifier on an independently sourced CSV, without retraining."""
import argparse
import json
from pathlib import Path
import sys
from datetime import datetime, timezone

import joblib
import pandas as pd
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)


ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "ml" / "models" / "classifier"
PROCESSED_DIR = ROOT / "ml" / "data" / "processed"
CANONICAL_DATASET = ROOT / "ml" / "data" / "raw" / "scamshield_dataset.csv"
MIN_LANGUAGE_SAMPLES = 30
MIN_CATEGORY_SAMPLES = 5


def _is_forbidden_project_split(path: Path) -> bool:
    resolved = path.resolve()
    if resolved == CANONICAL_DATASET.resolve():
        return True
    try:
        resolved.relative_to(PROCESSED_DIR.resolve())
        return True
    except ValueError:
        return False


def evaluate(dataset_path: Path, source_description: str) -> dict:
    if _is_forbidden_project_split(dataset_path):
        raise ValueError(
            "Independent evaluation cannot use the canonical dataset or project split files."
        )
    if not source_description.strip():
        raise ValueError("A source description is required to record evaluation provenance.")

    metadata = json.loads(
        (MODEL_DIR / "model_metadata.json").read_text(encoding="utf-8")
    )
    if metadata.get("model_version") != "scamshield-classifier-v5":
        raise ValueError("The active classifier is not scamshield-classifier-v5.")
    dataset = pd.read_csv(dataset_path, keep_default_na=False)
    required_columns = {"text", "label"}
    missing_columns = required_columns - set(dataset.columns)
    if missing_columns:
        raise ValueError(
            "Evaluation CSV must contain text and label columns."
        )
    if dataset.empty or dataset["text"].astype(str).str.strip().eq("").any():
        raise ValueError("Evaluation CSV must contain non-empty examples.")
    labels = dataset["label"].astype(str).str.strip().str.lower()
    if not labels.isin({"scam", "genuine"}).all():
        raise ValueError("Evaluation labels must be scam or genuine.")

    sys.path.insert(0, str(ROOT / "backend"))
    from app.services.text_service import preprocess_text

    artifact_paths = metadata["artifact_paths"]
    classifier = joblib.load(MODEL_DIR / artifact_paths["classifier"])
    vectorizer = joblib.load(MODEL_DIR / artifact_paths["vectorizer"])
    normalized_text = dataset["text"].astype(str).map(preprocess_text)
    if normalized_text.str.strip().eq("").any():
        raise ValueError("Preprocessing produced empty evaluation examples.")
    predictions = classifier.predict(vectorizer.transform(normalized_text))
    predictions = pd.Series(predictions, index=dataset.index)
    classes = ["genuine", "scam"]
    matrix = confusion_matrix(labels, predictions, labels=classes)
    language_metrics = []
    if "language" in dataset.columns:
        for language in sorted(dataset["language"].astype(str).unique()):
            mask = dataset["language"].astype(str).eq(language)
            if int(mask.sum()) < MIN_LANGUAGE_SAMPLES:
                continue
            language_metrics.append({
                "language": language,
                "samples": int(mask.sum()),
                "accuracy": float(accuracy_score(labels[mask], predictions[mask])),
                "scam_precision": float(precision_score(
                    labels[mask], predictions[mask], pos_label="scam", zero_division=0
                )),
                "scam_recall": float(recall_score(
                    labels[mask], predictions[mask], pos_label="scam", zero_division=0
                )),
                "scam_f1": float(f1_score(
                    labels[mask], predictions[mask], pos_label="scam", zero_division=0
                )),
            })

    category_metrics = []
    if "scam_category" in dataset.columns:
        for category in sorted(dataset["scam_category"].astype(str).unique()):
            mask = dataset["scam_category"].astype(str).eq(category)
            if int(mask.sum()) < MIN_CATEGORY_SAMPLES:
                continue
            category_metrics.append({
                "category": category,
                "samples": int(mask.sum()),
                "accuracy": float(accuracy_score(labels[mask], predictions[mask])),
            })

    return {
        "status": "COMPLETED",
        "scope": "Independent evaluation; no fitting or threshold tuning performed.",
        "model_version": metadata["model_version"],
        "source_description": source_description.strip(),
        "sample_count": len(dataset),
        "accuracy": float(accuracy_score(labels, predictions)),
        "scam_precision": float(precision_score(
            labels, predictions, pos_label="scam", zero_division=0
        )),
        "scam_recall": float(recall_score(
            labels, predictions, pos_label="scam", zero_division=0
        )),
        "scam_f1": float(f1_score(labels, predictions, pos_label="scam", zero_division=0)),
        "confusion_matrix": {
            "class_order": classes,
            "matrix": matrix.tolist(),
        },
        "false_positives": int(((labels == "genuine") & (predictions == "scam")).sum()),
        "false_negatives": int(((labels == "scam") & (predictions == "genuine")).sum()),
        "language_metrics": language_metrics,
        "category_metrics": category_metrics,
        "timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "limitations": (
            "Independence and labeling quality depend on the supplied source; "
            "the source description and data provenance must be reviewed."
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset", required=True, type=Path)
    parser.add_argument("--source-description", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = evaluate(args.dataset, args.source_description)
    output = json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False)
    if args.output:
        args.output.write_text(output + "\n", encoding="utf-8")
        print(f"Independent evaluation report saved to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
