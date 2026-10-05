import json
import os
import platform
import re
from datetime import datetime, timezone
from pathlib import Path

import joblib
import pandas as pd
import sklearn
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report


ROOT = Path(__file__).resolve().parents[2]
DATASET_VERSION = "scamshield-dataset-8424-v10.1"
PROCESSED_DIR = ROOT / "ml" / "data" / "processed" / DATASET_VERSION
MODEL_DIR = ROOT / "ml" / "models" / "classifier"
MODEL_VERSION = os.getenv(
    "SCAMSHIELD_MODEL_VERSION",
    "scamshield-classifier-v5",
)
if not re.fullmatch(r"[A-Za-z0-9._-]+", MODEL_VERSION):
    raise ValueError("SCAMSHIELD_MODEL_VERSION contains invalid path characters.")
VERSION_DIR = MODEL_DIR / MODEL_VERSION
RANDOM_SEED = 42


def main():
    metadata_path = PROCESSED_DIR / "split_metadata.json"
    split_metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    dataset_version = split_metadata["dataset_version"]

    train = pd.read_csv(PROCESSED_DIR / "train.csv", keep_default_na=False)
    validation = pd.read_csv(PROCESSED_DIR / "val.csv", keep_default_na=False)
    expected_sizes = {
        "train": split_metadata["splits"]["train"]["row_count"],
        "validation": split_metadata["splits"]["validation"]["row_count"],
    }
    if len(train) != expected_sizes["train"] or len(validation) != expected_sizes["validation"]:
        raise ValueError("Processed split sizes do not match split_metadata.json.")
    if train["processed_text"].str.strip().eq("").any() or validation["processed_text"].str.strip().eq("").any():
        raise ValueError("Train or validation data contains empty processed text.")
    if set(train["label"]) != {"scam", "genuine"} or set(validation["label"]) != {"scam", "genuine"}:
        raise ValueError("Train and validation splits must both contain scam and genuine labels.")
    if set(train["sample_id"]) & set(validation["sample_id"]):
        raise ValueError("Train and validation splits contain overlapping sample IDs.")

    vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        max_features=10000,
        sublinear_tf=True,
    )
    train_features = vectorizer.fit_transform(train["processed_text"])
    validation_features = vectorizer.transform(validation["processed_text"])

    classifier = LogisticRegression(
        random_state=RANDOM_SEED,
        class_weight="balanced",
        max_iter=1000,
    )
    classifier.fit(train_features, train["label"])
    validation_predictions = classifier.predict(validation_features)
    validation_report = classification_report(
        validation["label"],
        validation_predictions,
        output_dict=True,
        zero_division=0,
    )

    if VERSION_DIR.exists():
        raise FileExistsError(
            f"{MODEL_VERSION} already exists; refusing to overwrite a versioned model."
        )
    VERSION_DIR.mkdir(parents=True)
    classifier_path = VERSION_DIR / "scam_classifier.joblib"
    vectorizer_path = VERSION_DIR / "tfidf_vectorizer.joblib"
    joblib.dump(classifier, classifier_path)
    joblib.dump(vectorizer, vectorizer_path)

    model_metadata = {
        "model_name": "ScamShield Logistic Regression",
        "model_version": MODEL_VERSION,
        "training_timestamp": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "dataset_version": dataset_version,
        "processed_directory": str(PROCESSED_DIR.relative_to(ROOT)).replace("\\", "/"),
        "dataset_rows": split_metadata["row_count"],
        "train_rows": len(train),
        "validation_rows": len(validation),
        "test_rows": split_metadata["splits"]["test"]["row_count"],
        "random_state": RANDOM_SEED,
        "algorithm": "Logistic Regression",
        "feature_type": "word-level TF-IDF",
        "feature_configuration": {
            "ngram_range": [1, 2],
            "max_features": 10000,
            "sublinear_tf": True,
        },
        "validation_accuracy": accuracy_score(validation["label"], validation_predictions),
        "validation_classification_report": validation_report,
        "classes": list(classifier.classes_),
        "scikit_learn_version": sklearn.__version__,
        "python_version": platform.python_version(),
        "artifact_paths": {
            "classifier": f"{MODEL_VERSION}/scam_classifier.joblib",
            "vectorizer": f"{MODEL_VERSION}/tfidf_vectorizer.joblib",
        },
    }

    version_metadata_path = VERSION_DIR / "model_metadata.json"
    version_metadata_path.write_text(
        json.dumps(model_metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    active_metadata_path = MODEL_DIR / "model_metadata.json"
    active_tmp_path = active_metadata_path.with_suffix(".json.tmp")
    active_tmp_path.write_text(
        json.dumps(model_metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    active_tmp_path.replace(active_metadata_path)

    print(f"Model version: {MODEL_VERSION}")
    print(f"Dataset version: {dataset_version}")
    print(f"Rows: train={len(train)}, validation={len(validation)}, "
          f"test={model_metadata['test_rows']}")
    print(f"Validation accuracy: {model_metadata['validation_accuracy']:.4f}")
    print(f"Artifacts saved in {VERSION_DIR}")


if __name__ == "__main__":
    main()
