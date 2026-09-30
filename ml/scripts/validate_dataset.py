import pandas as pd
import json

def validate_dataset(filepath):
    print("=" * 50)
    print("DATASET VALIDATION REPORT")
    print("=" * 50)
    
    try:
        df = pd.read_csv(filepath)
    except Exception as e:
        print(f"Error reading file: {e}")
        return

    print(f"\nDataset Shape:")
    print(f"Rows: {df.shape[0]}")
    print(f"Columns: {df.shape[1]}")
    print(f"Column Names: {list(df.columns)}\n")
    
    if 'label' in df.columns:
        print("Labels:")
        print(df['label'].value_counts().to_string())
        print()
    else:
        print("WARNING: 'label' column missing.\n")

    if 'language' in df.columns:
        print("Languages:")
        print(df['language'].value_counts().to_string())
        print()
    else:
        print("WARNING: 'language' column missing.\n")

    if 'label' in df.columns and 'language' in df.columns:
        print("Label x Language Distribution:")
        print(pd.crosstab(df['label'], df['language']).to_string())
        print()

    if 'scam_category' in df.columns:
        print("Scam Categories:")
        print(df['scam_category'].value_counts().to_string())
        print()
        
    if 'severity' in df.columns:
        print("Severity Distribution:")
        print(df['severity'].value_counts().to_string())
        print()
        
    if 'priority' in df.columns:
        print("Priority Distribution:")
        print(df['priority'].value_counts().to_string())
        print()

    print("Missing Values:")
    print(df.isnull().sum().to_string())
    print()

    print("Empty Text Rows:")
    if 'text' in df.columns:
        empty_text_count = df['text'].isna().sum() + (df['text'].str.strip() == '').sum()
        print(f"{empty_text_count}")
    else:
        print("WARNING: 'text' column missing.")
    print()

    print("Empty Labels:")
    if 'label' in df.columns:
        empty_label_count = df['label'].isna().sum() + (df['label'].str.strip() == '').sum()
        print(f"{empty_label_count}")
    print()
    
    print("Duplicate Sample IDs:")
    if 'sample_id' in df.columns:
        dup_ids = df['sample_id'].duplicated().sum()
        print(f"{dup_ids}")
    else:
        print("WARNING: 'sample_id' column missing.")
    print()

    print("Duplicate Text:")
    if 'text' in df.columns:
        dup_text = df['text'].duplicated().sum()
        print(f"{dup_text}")
    print()
    
    print("=" * 50)

if __name__ == "__main__":
    validate_dataset("../data/raw/scamshield_dataset_2000_cleaned.csv")
