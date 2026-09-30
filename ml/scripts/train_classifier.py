import pandas as pd
import json
import joblib
from datetime import datetime
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report
import os

def main():
    print("Loading datasets...")
    train = pd.read_csv('../data/processed/train.csv')
    val = pd.read_csv('../data/processed/val.csv')
    
    # Fill NaN just in case
    train['processed_text'] = train['processed_text'].fillna("")
    val['processed_text'] = val['processed_text'].fillna("")
    
    # We will use char word n-grams (1-2) which are robust for multilingual and short texts.
    print("Initializing TF-IDF Vectorizer...")
    vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        max_features=10000,
        sublinear_tf=True
    )
    
    print("Training TF-IDF Vectorizer...")
    X_train = vectorizer.fit_transform(train['processed_text'])
    y_train = train['label']
    
    X_val = vectorizer.transform(val['processed_text'])
    y_val = val['label']
    
    print("Training Logistic Regression classifier...")
    clf = LogisticRegression(random_state=42, class_weight='balanced', max_iter=1000)
    clf.fit(X_train, y_train)
    
    print("Evaluating on Validation Set...")
    y_val_pred = clf.predict(X_val)
    print("Validation Accuracy:", accuracy_score(y_val, y_val_pred))
    print(classification_report(y_val, y_val_pred))
    
    # Save Models
    print("Saving models...")
    os.makedirs('../models/classifier', exist_ok=True)
    
    clf_path = '../models/classifier/scam_classifier.joblib'
    vec_path = '../models/classifier/tfidf_vectorizer.joblib'
    meta_path = '../models/classifier/model_metadata.json'
    
    joblib.dump(clf, clf_path)
    joblib.dump(vectorizer, vec_path)
    
    metadata = {
        "model_name": "ScamShield Logistic Regression",
        "model_version": "scamshield-classifier-v1",
        "training_date": datetime.utcnow().isoformat(),
        "dataset_version": "scamshield_dataset_2000_cleaned.csv",
        "dataset_size": 2000,
        "feature_configuration": {
            "ngram_range": [1, 2],
            "max_features": 10000,
            "sublinear_tf": True
        },
        "train_split": len(train),
        "validation_split": len(val),
        "test_split": 300,  # from known length
        "classes": list(clf.classes_)
    }
    
    with open(meta_path, 'w') as f:
        json.dump(metadata, f, indent=4)
        
    print("Training complete and models saved to ml/models/classifier/")

if __name__ == "__main__":
    main()
