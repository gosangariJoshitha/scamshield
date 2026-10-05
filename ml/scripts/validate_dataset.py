import json
import sys
from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
DATASET_VERSION = "scamshield-dataset-8424-v10.1"
RAW_PATH = ROOT / "ml" / "data" / "raw" / "scamshield_dataset.csv"
PROCESSED_DIR = ROOT / "ml" / "data" / "processed" / DATASET_VERSION
sys.path.insert(0, str(ROOT))
from backend.app.services.text_service import preprocess_text


def _distribution(frame, column):
    return {
        str(key): int(value)
        for key, value in frame[column].value_counts().sort_index().items()
    }


def validate_dataset():
    errors = []
    raw = pd.read_csv(RAW_PATH, encoding="utf-8", keep_default_na=False)
    for column in ("label", "language"):
        if column in raw:
            raw[column] = raw[column].astype(str).str.strip().str.lower()
    for column in ("severity", "priority"):
        if column in raw:
            raw[column] = raw[column].astype(str).str.strip().str.upper()
    metadata_path = PROCESSED_DIR / "split_metadata.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    required = {
        "sample_id", "text", "label", "language", "severity", "priority",
        "indicators", "expected_action", "resolution_steps",
    }
    missing_columns = sorted(required - set(raw.columns))
    if "scam_category" not in raw.columns and "category" in raw.columns:
        raw["scam_category"] = raw["category"]
    if missing_columns:
        errors.append(f"Missing required columns: {missing_columns}")

    if len(raw) != metadata["row_count"]:
        errors.append(
            f"Raw row count {len(raw)} differs from split metadata "
            f"{metadata['row_count']}."
        )
    if raw["sample_id"].astype(str).str.strip().eq("").any():
        errors.append("Dataset contains empty sample IDs.")
    if raw["sample_id"].duplicated().any():
        errors.append("Dataset contains duplicate sample IDs.")
    if raw["text"].astype(str).str.strip().eq("").any():
        errors.append("Dataset contains empty text.")
    normalized_text = raw["text"].map(preprocess_text)
    if normalized_text.duplicated().any():
        errors.append("Dataset contains duplicate normalized text.")

    expected_values = {
        "label": {"scam", "genuine"},
        "language": {"en", "hi", "te"},
        "severity": {"LOW", "MEDIUM", "HIGH", "CRITICAL"},
        "priority": {"P1", "P2", "P3", "P4"},
    }
    for column, allowed in expected_values.items():
        invalid = sorted(set(raw[column].astype(str)) - allowed)
        if invalid:
            errors.append(f"Invalid {column} values: {invalid}")

    for column in ("indicators", "expected_action", "resolution_steps"):
        empty = raw[column].astype(str).str.strip().eq("")
        if empty.any():
            errors.append(f"{column} has {int(empty.sum())} empty values.")
    genuine = raw["label"].eq("genuine")
    if (genuine & (raw["severity"] != "LOW")).any():
        errors.append("Genuine records must have LOW severity.")
    if (genuine & (raw["priority"] != "P4")).any():
        errors.append("Genuine records must have P4 priority.")

    splits = {}
    for name, filename in (("train", "train.csv"), ("validation", "val.csv"), ("test", "test.csv")):
        split_path = PROCESSED_DIR / filename
        if not split_path.is_file():
            errors.append(f"Missing split file: {filename}")
            continue
        split = pd.read_csv(split_path, encoding="utf-8", keep_default_na=False)
        splits[name] = split
        expected_size = metadata["splits"][name]["row_count"]
        if len(split) != expected_size:
            errors.append(f"{filename} has {len(split)} rows; metadata says {expected_size}.")
        if split["processed_text"].astype(str).str.strip().eq("").any():
            errors.append(f"{filename} contains empty processed_text.")

    if len(splits) == 3:
        raw_ids = set(raw["sample_id"])
        split_ids = set()
        for name, frame in splits.items():
            current_ids = set(frame["sample_id"])
            if split_ids & current_ids:
                errors.append(f"Duplicate sample IDs across processed splits ({name}).")
            split_ids.update(current_ids)
        if split_ids != raw_ids:
            errors.append(
                f"Split ID union differs from raw dataset: "
                f"{len(raw_ids - split_ids)} missing, {len(split_ids - raw_ids)} unexpected."
            )
        group_field = metadata.get("group_field")
        if group_field:
            group_sets = {
                name: set(frame[group_field])
                for name, frame in splits.items()
            }
            for left_name, left_groups in group_sets.items():
                for right_name, right_groups in group_sets.items():
                    if left_name < right_name and left_groups & right_groups:
                        errors.append(
                            f"Pattern group leakage between {left_name} and {right_name}."
                        )
        for left_name, left in splits.items():
            for right_name, right in splits.items():
                if left_name >= right_name:
                    continue
                if set(left["processed_text"]) & set(right["processed_text"]):
                    errors.append(f"Normalized-text leakage between {left_name} and {right_name}.")

    if metadata.get("dataset_version") != DATASET_VERSION:
        errors.append(
            f"Split metadata version {metadata.get('dataset_version')!r} "
            f"does not match expected {DATASET_VERSION!r}."
        )
    print(f"Dataset version: {metadata['dataset_version']}")
    print(f"Rows: {len(raw)}")
    print(f"Labels: {_distribution(raw, 'label')}")
    print(f"Languages: {_distribution(raw, 'language')}")
    print(f"Categories: {raw['scam_category'].nunique() if 'scam_category' in raw else 'unavailable'}")
    print(f"Severity: {_distribution(raw, 'severity')}")
    print(f"Priority: {_distribution(raw, 'priority')}")
    for name, frame in splits.items():
        print(f"{name}: {len(frame)} rows")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        raise SystemExit(1)
    print("Dataset and split validation passed.")


if __name__ == "__main__":
    validate_dataset()
