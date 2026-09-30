import pandas as pd
from sklearn.model_selection import train_test_split
import sys
import os

# Add backend to path to import text_service
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))
from backend.app.services.text_service import preprocess_text

def main():
    print("Loading dataset...")
    df = pd.read_csv('../data/raw/scamshield_dataset_2000_cleaned.csv')
    
    # Preprocess text
    print("Preprocessing text...")
    df['processed_text'] = df['text'].apply(preprocess_text)
    
    # Drop duplicates to prevent leakage
    initial_len = len(df)
    df = df.drop_duplicates(subset=['processed_text'])
    print(f"Dropped {initial_len - len(df)} duplicate rows based on processed text.")
    
    # Create combined stratification key
    df['stratify_key'] = df['label'] + "_" + df['language']
    
    # Check if any stratify_key has only 1 sample, which will break stratification
    counts = df['stratify_key'].value_counts()
    valid_keys = counts[counts > 1].index
    
    # We'll just drop or duplicate the singletons if they exist, but we know our dataset is well balanced.
    
    print("Splitting dataset (70% Train, 15% Val, 15% Test)...")
    train_val, test = train_test_split(
        df, 
        test_size=0.15, 
        random_state=42, 
        stratify=df['stratify_key']
    )
    
    # remaining for train and val is 85%. We want 15% of total for val.
    # 15 / 85 = 0.17647
    train, val = train_test_split(
        train_val,
        test_size=0.17647,
        random_state=42,
        stratify=train_val['stratify_key']
    )
    
    # Drop the temporary key
    for d in [train, val, test]:
        d.drop(columns=['stratify_key'], inplace=True)
        
    print(f"Train size: {len(train)}")
    print(f"Val size: {len(val)}")
    print(f"Test size: {len(test)}")
    
    # Save
    os.makedirs('../data/processed', exist_ok=True)
    train.to_csv('../data/processed/train.csv', index=False)
    val.to_csv('../data/processed/val.csv', index=False)
    test.to_csv('../data/processed/test.csv', index=False)
    print("Splits saved to ml/data/processed/")

if __name__ == '__main__':
    main()
