import sys
from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
SOURCE_PATH = ROOT / "ml" / "data" / "raw" / "scamshield_dataset.csv"
EXPECTED_ROW_COUNT = 8424
REQUIRED_COLUMNS = {
    "sample_id",
    "text",
    "label",
    "category",
    "pattern_id",
    "language",
    "indicators",
    "expected_action",
    "resolution_steps",
    "severity",
    "priority",
    "input_channel",
    "category_type",
}

sys.path.insert(0, str(ROOT))
from backend.app.services.text_service import preprocess_text


def prepare_dataset() -> pd.DataFrame:
    if not SOURCE_PATH.is_file():
        raise FileNotFoundError(f"Canonical dataset not found: {SOURCE_PATH}")

    frame = pd.read_csv(SOURCE_PATH, encoding="utf-8", keep_default_na=False)
    missing_columns = sorted(REQUIRED_COLUMNS - set(frame.columns))
    if missing_columns:
        raise ValueError(f"Audited dataset is missing required columns: {missing_columns}")
    if len(frame) != EXPECTED_ROW_COUNT:
        raise ValueError(
            f"Expected {EXPECTED_ROW_COUNT} canonical records; found {len(frame)}."
        )

    for column in frame.select_dtypes(include="object").columns:
        frame[column] = frame[column].astype(str).str.strip()

    frame["label"] = frame["label"].str.lower()
    frame["language"] = frame["language"].str.lower()
    frame["severity"] = frame["severity"].str.upper()
    frame["priority"] = frame["priority"].str.upper()
    frame["scam_category"] = frame["category"]
    frame["source"] = "User-provided audited dataset"
    frame["data_origin"] = "user_provided_audited_dataset"
    frame.loc[frame["label"].eq("genuine"), "severity"] = "LOW"
    frame.loc[frame["label"].eq("genuine"), "priority"] = "P4"

    required_values = (
        "sample_id",
        "text",
        "label",
        "scam_category",
        "pattern_id",
        "language",
        "indicators",
        "expected_action",
        "resolution_steps",
        "severity",
        "priority",
    )
    for column in required_values:
        if frame[column].eq("").any():
            raise ValueError(f"Audited dataset contains blank values in {column}.")

    allowed = {
        "label": {"scam", "genuine"},
        "language": {"en", "hi", "te"},
        "severity": {"LOW", "MEDIUM", "HIGH", "CRITICAL"},
        "priority": {"P1", "P2", "P3", "P4"},
    }
    for column, accepted in allowed.items():
        unexpected = sorted(set(frame[column]) - accepted)
        if unexpected:
            raise ValueError(f"Unexpected {column} values: {unexpected}")

    if frame["sample_id"].duplicated().any():
        raise ValueError("Canonical dataset contains duplicate sample IDs.")
    normalized_text = frame["text"].map(preprocess_text)
    if normalized_text.str.strip().eq("").any():
        raise ValueError("Text normalization produced empty records.")
    if normalized_text.duplicated().any():
        raise ValueError("Canonical dataset contains duplicate normalized text.")

    if not frame["category_type"].eq(frame["label"]).all():
        raise ValueError("category_type values do not agree with label.")
    genuine = frame["label"].eq("genuine")
    if (genuine & frame["severity"].ne("LOW")).any():
        raise ValueError("Genuine records must have LOW severity.")
    if (genuine & frame["priority"].ne("P4")).any():
        raise ValueError("Genuine records must have P4 priority.")
    return frame


def main() -> None:
    frame = prepare_dataset()
    print(f"Validated canonical dataset: {SOURCE_PATH}")
    print(f"Rows: {len(frame)}")
    print(f"Labels: {frame['label'].value_counts().sort_index().to_dict()}")
    print(f"Languages: {frame['language'].value_counts().sort_index().to_dict()}")
    print(f"Categories: {frame['scam_category'].nunique()}")
    print(f"Pattern IDs: {frame['pattern_id'].nunique()}")


if __name__ == "__main__":
    main()
