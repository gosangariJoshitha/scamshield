import json
import itertools
import sys
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
from sklearn.model_selection import StratifiedGroupKFold, train_test_split


ROOT = Path(__file__).resolve().parents[2]
RAW_PATH = ROOT / "ml" / "data" / "raw" / "scamshield_dataset.csv"
DATASET_VERSION = "scamshield-dataset-8424-v10.1"
PROCESSED_DIR = ROOT / "ml" / "data" / "processed" / DATASET_VERSION
RANDOM_SEED = 42
EXPECTED_SEVERITIES = {"LOW", "MEDIUM", "HIGH", "CRITICAL"}
EXPECTED_PRIORITIES = {"P1", "P2", "P3", "P4"}

sys.path.insert(0, str(ROOT))
from backend.app.services.text_service import preprocess_text


def _normalize_categorical_values(df):
    replacements = {}
    normalizers = {
        "severity": str.upper,
        "priority": str.upper,
        "label": str.lower,
        "language": str.lower,
    }
    for column, normalize in normalizers.items():
        original = df[column].astype(str)
        normalized = original.map(lambda value: normalize(value.strip()))
        replacements[column] = int(original.ne(normalized).sum())
        df[column] = normalized

    genuine_rows = df["label"].eq("genuine")
    replacements["genuine_severity_to_LOW"] = int(
        (genuine_rows & df["severity"].ne("LOW")).sum()
    )
    replacements["genuine_priority_to_P4"] = int(
        (genuine_rows & df["priority"].ne("P4")).sum()
    )
    df.loc[genuine_rows, "severity"] = "LOW"
    df.loc[genuine_rows, "priority"] = "P4"

    invalid_severity = sorted(set(df["severity"]) - EXPECTED_SEVERITIES)
    invalid_priority = sorted(set(df["priority"]) - EXPECTED_PRIORITIES)
    invalid_labels = sorted(set(df["label"]) - {"scam", "genuine"})
    invalid_languages = sorted(set(df["language"]) - {"en", "hi", "te"})
    invalid_values = {
        "severity": invalid_severity,
        "priority": invalid_priority,
        "label": invalid_labels,
        "language": invalid_languages,
    }
    invalid_values = {key: value for key, value in invalid_values.items() if value}
    if invalid_values:
        raise ValueError(f"Unexpected categorical values after normalization: {invalid_values}")
    return replacements


def _trim_string_fields(df):
    replacements = {}
    for column in df.select_dtypes(include="object").columns:
        original = df[column].astype(str)
        trimmed = original.str.strip()
        replacements[column] = int(original.ne(trimmed).sum())
        df[column] = trimmed
    return replacements


def _replace_empty_advisory_fields(df):
    replacements = {}
    for column in ("indicators", "expected_action", "resolution_steps"):
        values = df[column].astype(str)
        empty = values.str.strip().eq("") | values.str.strip().str.casefold().eq("none")
        replacements[column] = int(empty.sum())
        df.loc[empty, column] = "None"
    return replacements


def _distribution(frame, column):
    return {
        str(key): int(value)
        for key, value in frame[column].value_counts().sort_index().items()
    }


def _joint_distribution(frame):
    counts = frame.groupby(["label", "language"], sort=True).size()
    return {
        f"{label}:{language}": int(count)
        for (label, language), count in counts.items()
    }


def _score_fold_selection(df, indexes, target_size, strata):
    selected = df.iloc[sorted(indexes)]
    target_per_stratum = target_size / len(strata)
    counts = selected.groupby(["label", "language"]).size().to_dict()
    score = ((len(selected) - target_size) / target_size) ** 2
    score += sum(
        ((counts.get(stratum, 0) - target_per_stratum) / target_per_stratum) ** 2
        for stratum in strata
    )
    return score


def _grouped_splits(df, stratify_key):
    fold_count = 20
    held_out_fold_count = 3
    strata = sorted(
        (label, language)
        for label in df["label"].unique()
        for language in df["language"].unique()
    )
    folds = [
        set(test_indexes.tolist())
        for _, test_indexes in StratifiedGroupKFold(
            n_splits=fold_count,
            shuffle=True,
            random_state=RANDOM_SEED,
        ).split(df, stratify_key, groups=df["pattern_id"])
    ]
    all_folds = range(fold_count)
    target_size = len(df) * 0.15
    test_choice = min(
        itertools.combinations(all_folds, held_out_fold_count),
        key=lambda choice: _score_fold_selection(
            df,
            set().union(*(folds[index] for index in choice)),
            target_size,
            strata,
        ),
    )
    remaining_folds = [
        index for index in all_folds if index not in set(test_choice)
    ]
    validation_choice = min(
        itertools.combinations(remaining_folds, held_out_fold_count),
        key=lambda choice: _score_fold_selection(
            df,
            set().union(*(folds[index] for index in choice)),
            target_size,
            strata,
        ),
    )

    test_indexes = set().union(*(folds[index] for index in test_choice))
    validation_indexes = set().union(
        *(folds[index] for index in validation_choice)
    )
    train_indexes = set(range(len(df))) - test_indexes - validation_indexes
    return {
        "train": df.iloc[sorted(train_indexes)].copy(),
        "validation": df.iloc[sorted(validation_indexes)].copy(),
        "test": df.iloc[sorted(test_indexes)].copy(),
    }


def main():
    print(f"Loading {RAW_PATH}")
    df = pd.read_csv(RAW_PATH, encoding="utf-8", keep_default_na=False)
    if "scam_category" not in df.columns and "category" in df.columns:
        df["scam_category"] = df["category"]
    if "source" not in df.columns:
        df["source"] = "User-provided audited dataset"
    if "data_origin" not in df.columns:
        df["data_origin"] = "user_provided_audited_dataset"
    if df.empty:
        raise ValueError("The raw dataset is empty.")
    required_columns = {
        "sample_id", "text", "label", "language", "severity", "priority",
        "indicators", "expected_action", "resolution_steps",
    }
    missing_columns = sorted(required_columns - set(df.columns))
    if missing_columns:
        raise ValueError(f"Required raw columns are missing: {missing_columns}")

    whitespace_replacements = _trim_string_fields(df)
    category_replacements = _normalize_categorical_values(df)
    empty_replacements = _replace_empty_advisory_fields(df)
    if df["sample_id"].duplicated().any():
        duplicates = df.loc[df["sample_id"].duplicated(keep=False), "sample_id"].tolist()
        raise ValueError(f"Duplicate sample_id values found: {duplicates[:20]}")
    if df["text"].astype(str).str.strip().eq("").any():
        raise ValueError("The raw dataset contains empty text.")

    print("Preprocessing text with backend.app.services.text_service.preprocess_text")
    df["processed_text"] = df["text"].map(preprocess_text)
    duplicate_texts = df["processed_text"].duplicated(keep=False)
    if duplicate_texts.any():
        duplicate_ids = df.loc[duplicate_texts, "sample_id"].tolist()
        raise ValueError(
            "Duplicate processed_text values found; refusing to drop records: "
            f"{duplicate_ids[:20]}"
        )
    if df["processed_text"].astype(str).str.strip().eq("").any():
        raise ValueError("Text preprocessing produced an empty processed_text value.")

    df["stratify_key"] = df["label"] + "_" + df["language"]
    strata_counts = df["stratify_key"].value_counts()
    if strata_counts.empty or strata_counts.min() < 2:
        raise ValueError(
            "Label-language stratification requires at least two rows per stratum: "
            f"{strata_counts.to_dict()}"
        )

    row_count = len(df)
    if "pattern_id" in df.columns:
        splits = _grouped_splits(df, df["stratify_key"])
        split_strategy = (
            "canonical pattern_id-grouped stratified 70/15/15; 20 stratified group folds, "
            "3 held-out folds each for validation and test"
        )
        group_field = "pattern_id"
    else:
        train_count = round(row_count * 0.70)
        validation_count = int(row_count * 0.15)
        test_count = row_count - train_count - validation_count
        train_validation, test = train_test_split(
            df,
            test_size=test_count,
            random_state=RANDOM_SEED,
            stratify=df["stratify_key"],
        )
        train, validation = train_test_split(
            train_validation,
            test_size=validation_count,
            random_state=RANDOM_SEED,
            stratify=train_validation["stratify_key"],
        )
        splits = {
            "train": train,
            "validation": validation,
            "test": test,
        }
        split_strategy = "stratified by label and language; 70/15/15"
        group_field = None

    for name, frame in splits.items():
        splits[name] = frame.drop(
            columns=["stratify_key"],
            errors="ignore",
        ).reset_index(drop=True)

    for left_name, left in splits.items():
        for right_name, right in splits.items():
            if left_name >= right_name:
                continue
            shared_ids = set(left["sample_id"]) & set(right["sample_id"])
            shared_text = set(left["processed_text"]) & set(right["processed_text"])
            if shared_ids or shared_text:
                raise ValueError(
                    f"Split leakage between {left_name} and {right_name}: "
                    f"{len(shared_ids)} shared IDs, {len(shared_text)} shared texts."
                )
            if group_field and set(left[group_field]) & set(right[group_field]):
                raise ValueError(
                    f"Pattern-group leakage between {left_name} and {right_name}."
                )

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    for name, frame in splits.items():
        frame["processed_text"] = frame["text"].map(preprocess_text)
        if frame["processed_text"].str.strip().eq("").any():
            raise ValueError(f"{name} split contains empty processed text.")
        filename = "val.csv" if name == "validation" else f"{name}.csv"
        output_path = PROCESSED_DIR / filename
        tmp_path = output_path.with_suffix(output_path.suffix + ".tmp")
        frame.to_csv(tmp_path, index=False, encoding="utf-8")
        tmp_path.replace(output_path)

    metadata = {
        "dataset_version": DATASET_VERSION,
        "source_dataset": str(RAW_PATH.relative_to(ROOT)).replace("\\", "/"),
        "canonical_source": "ml/data/raw/scamshield_dataset.csv",
        "source_dataset_rows": row_count,
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "random_seed": RANDOM_SEED,
        "split_strategy": split_strategy,
        "group_field": group_field,
        "row_count": row_count,
        "columns": list(splits["train"].columns),
        "normalizer": "backend.app.services.text_service.preprocess_text",
        "replacements": {
            **whitespace_replacements,
            **category_replacements,
            **empty_replacements,
        },
        "splits": {
            name: {
                "file": "val.csv" if name == "validation" else f"{name}.csv",
                "row_count": len(frame),
                "label_distribution": _distribution(frame, "label"),
                "language_distribution": _distribution(frame, "language"),
                "label_language_distribution": _joint_distribution(frame),
            }
            for name, frame in splits.items()
        },
    }
    metadata_path = PROCESSED_DIR / "split_metadata.json"
    metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"Dataset version: {DATASET_VERSION}")
    print(f"Rows retained: {row_count}")
    print(f"Whitespace replacements: {whitespace_replacements}")
    print(f"Category casing replacements: {category_replacements}")
    print(f"Empty advisory-field replacements: {empty_replacements}")
    for name, split in metadata["splits"].items():
        print(
            f"{name}: {split['row_count']} rows; "
            f"labels={split['label_distribution']}; "
            f"languages={split['language_distribution']}"
        )
    print(f"Processed data saved to {PROCESSED_DIR}")
    print(f"Split metadata saved to {metadata_path}")


if __name__ == "__main__":
    main()
