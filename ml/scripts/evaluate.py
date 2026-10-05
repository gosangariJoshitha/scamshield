import json
from datetime import datetime, timezone
from pathlib import Path

import joblib
import pandas as pd
import sklearn
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PROCESSED_DIR = ROOT / "ml" / "data" / "processed"
MODEL_DIR = ROOT / "ml" / "models" / "classifier"
REPORT_DIR = ROOT / "ml" / "reports"
MIN_CATEGORY_SAMPLES = 5


def main():
    model_metadata = json.loads(
        (MODEL_DIR / "model_metadata.json").read_text(encoding="utf-8")
    )
    processed_dir = ROOT / model_metadata.get(
        "processed_directory",
        str(DEFAULT_PROCESSED_DIR.relative_to(ROOT)),
    )
    split_metadata = json.loads(
        (processed_dir / "split_metadata.json").read_text(encoding="utf-8")
    )
    if model_metadata["dataset_version"] != split_metadata["dataset_version"]:
        raise ValueError("Active model and split metadata refer to different datasets.")

    test = pd.read_csv(processed_dir / "test.csv", keep_default_na=False)
    if len(test) != split_metadata["splits"]["test"]["row_count"]:
        raise ValueError("Test split size does not match split_metadata.json.")
    if test["processed_text"].str.strip().eq("").any():
        raise ValueError("Test split contains empty processed text.")

    artifact_paths = model_metadata["artifact_paths"]
    classifier_path = MODEL_DIR / artifact_paths["classifier"]
    vectorizer_path = MODEL_DIR / artifact_paths["vectorizer"]
    classifier = joblib.load(classifier_path)
    vectorizer = joblib.load(vectorizer_path)
    predictions = classifier.predict(vectorizer.transform(test["processed_text"]))
    expected = test["label"]

    report = classification_report(
        expected,
        predictions,
        output_dict=True,
        zero_division=0,
    )
    report_text = classification_report(
        expected,
        predictions,
        zero_division=0,
    )
    labels = list(classifier.classes_)
    matrix = confusion_matrix(expected, predictions, labels=labels)
    scam_precision = precision_score(
        expected, predictions, pos_label="scam", zero_division=0
    )
    scam_recall = recall_score(
        expected, predictions, pos_label="scam", zero_division=0
    )
    scam_f1 = f1_score(expected, predictions, pos_label="scam", zero_division=0)

    language_metrics = []
    for language in sorted(test["language"].unique()):
        mask = test["language"].eq(language)
        language_expected = expected[mask]
        language_predictions = predictions[mask]
        language_metrics.append({
            "language": language,
            "samples": int(mask.sum()),
            "accuracy": float(accuracy_score(language_expected, language_predictions)),
            "scam_precision": float(precision_score(
                language_expected, language_predictions, pos_label="scam", zero_division=0
            )),
            "scam_recall": float(recall_score(
                language_expected, language_predictions, pos_label="scam", zero_division=0
            )),
            "scam_f1": float(f1_score(
                language_expected, language_predictions, pos_label="scam", zero_division=0
            )),
        })

    category_metrics = []
    excluded_categories = 0
    for category, indexes in test.groupby("scam_category").groups.items():
        category_expected = expected.loc[indexes]
        category_predictions = pd.Series(predictions, index=test.index).loc[indexes]
        samples = len(indexes)
        if samples < MIN_CATEGORY_SAMPLES:
            excluded_categories += 1
            continue
        category_metrics.append({
            "category": category,
            "samples": samples,
            "accuracy": float(accuracy_score(category_expected, category_predictions)),
        })

    false_positives = int(((expected == "genuine") & (predictions == "scam")).sum())
    false_negatives = int(((expected == "scam") & (predictions == "genuine")).sum())
    metrics = {
        "accuracy": float(accuracy_score(expected, predictions)),
        "scam_precision": float(scam_precision),
        "scam_recall": float(scam_recall),
        "scam_f1": float(scam_f1),
        "classification_report": report,
        "confusion_matrix": {
            "classes": labels,
            "matrix": matrix.tolist(),
        },
        "error_analysis": {
            "false_positives": false_positives,
            "false_negatives": false_negatives,
        },
        "language_evaluation": language_metrics,
        "category_evaluation": {
            "minimum_samples": MIN_CATEGORY_SAMPLES,
            "included_categories": category_metrics,
            "excluded_below_minimum": excluded_categories,
        },
        "metadata": {
            "dataset_version": model_metadata["dataset_version"],
            "model_version": model_metadata["model_version"],
            "test_size": len(test),
            "evaluation_timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "algorithm": model_metadata["algorithm"],
            "scikit_learn_version": sklearn.__version__,
            "scope": "Offline benchmark on the project test split; not real-world accuracy.",
        },
    }

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    metrics_path = REPORT_DIR / "metrics.json"
    metrics_path.write_text(
        json.dumps(metrics, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    report_path = REPORT_DIR / "classification_report.txt"
    report_path.write_text(
        "Offline Classification Report on the Held-Out Test Split\n"
        "========================================================\n"
        f"Dataset: {metrics['metadata']['dataset_version']}\n"
        f"Model: {metrics['metadata']['model_version']}\n"
        f"Test rows: {len(test)}\n"
        "This is an offline benchmark, not real-world accuracy.\n\n"
        f"{report_text}",
        encoding="utf-8",
    )

    print(f"Model: {model_metadata['model_version']}")
    print(f"Dataset: {model_metadata['dataset_version']}")
    print(f"Test rows: {len(test)}")
    print(report_text)
    print(f"Metrics saved to {metrics_path}")


if __name__ == "__main__":
    main()
