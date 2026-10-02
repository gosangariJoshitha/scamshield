import pandas as pd
import json
import joblib
import os
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, classification_report

def main():
    print("Loading test dataset...")
    test = pd.read_csv('../data/processed/test.csv')
    test['processed_text'] = test['processed_text'].fillna("")

    print("Loading models...")
    clf = joblib.load('../models/classifier/scam_classifier.joblib')
    vectorizer = joblib.load('../models/classifier/tfidf_vectorizer.joblib')

    print("Generating features...")
    X_test = vectorizer.transform(test['processed_text'])
    y_test = test['label']

    print("Running inference...")
    y_pred = clf.predict(X_test)
    
    print("Calculating metrics...")
    acc = accuracy_score(y_test, y_pred)
    
    # Calculate precision, recall, F1 specifically for the 'scam' class
    # Classes are 'genuine' and 'scam'. We care most about missing scams.
    pos_label = 'scam'
    prec = precision_score(y_test, y_pred, pos_label=pos_label)
    rec = recall_score(y_test, y_pred, pos_label=pos_label)
    f1 = f1_score(y_test, y_pred, pos_label=pos_label)
    
    report_dict = classification_report(y_test, y_pred, output_dict=True)
    report_str = classification_report(y_test, y_pred)
    
    print("Accuracy:", acc)
    print(report_str)
    
    # Multilingual evaluation
    print("\nMultilingual Evaluation:")
    lang_metrics = []
    if 'language' in test.columns:
        for lang in test['language'].unique():
            lang_mask = test['language'] == lang
            y_test_lang = y_test[lang_mask]
            y_pred_lang = y_pred[lang_mask]
            lang_acc = accuracy_score(y_test_lang, y_pred_lang)
            # handle cases where there are no scams in this split for this language (unlikely but safe)
            if pos_label in y_test_lang.values:
                lang_prec = precision_score(y_test_lang, y_pred_lang, pos_label=pos_label, zero_division=0)
                lang_rec = recall_score(y_test_lang, y_pred_lang, pos_label=pos_label, zero_division=0)
                lang_f1 = f1_score(y_test_lang, y_pred_lang, pos_label=pos_label, zero_division=0)
            else:
                lang_prec = lang_rec = lang_f1 = 0
                
            samples = len(y_test_lang)
            print(f"Language: {lang} | Samples: {samples} | Acc: {lang_acc:.4f} | Prec: {lang_prec:.4f} | Rec: {lang_rec:.4f} | F1: {lang_f1:.4f}")
            lang_metrics.append({
                "language": lang,
                "samples": samples,
                "accuracy": lang_acc,
                "precision": lang_prec,
                "recall": lang_rec,
                "f1": lang_f1
            })

    # Category evaluation
    print("\nCategory Analysis:")
    cat_metrics = []
    if 'scam_category' in test.columns:
        for cat in test['scam_category'].unique():
            cat_mask = test['scam_category'] == cat
            y_test_cat = y_test[cat_mask]
            y_pred_cat = y_pred[cat_mask]
            if len(y_test_cat) > 0:
                cat_acc = accuracy_score(y_test_cat, y_pred_cat)
                cat_metrics.append({
                    "category": cat,
                    "samples": len(y_test_cat),
                    "accuracy": cat_acc
                })
        
        # Print top 5 and bottom 5 categories by accuracy
        cat_df = pd.DataFrame(cat_metrics).sort_values(by='accuracy', ascending=False)
        print("Top 5 Categories:")
        print(cat_df.head(5).to_string(index=False))
        print("\nBottom 5 Categories:")
        print(cat_df.tail(5).to_string(index=False))

    # Generate Confusion Matrix
    cm = confusion_matrix(y_test, y_pred, labels=clf.classes_)

    # False Positive / False Negative Analysis
    fp_mask = (y_test == 'genuine') & (y_pred == 'scam')
    fn_mask = (y_test == 'scam') & (y_pred == 'genuine')

    # We'll extract a few examples (limit to 5 each)
    fp_examples = test[fp_mask][['processed_text', 'label']].head(5).to_dict(orient='records')
    fn_examples = test[fn_mask][['processed_text', 'label']].head(5).to_dict(orient='records')

    print("\nSaving reports...")
    os.makedirs('../reports', exist_ok=True)
    
    # Save metrics JSON
    metrics = {
        "accuracy": acc,
        "scam_precision": prec,
        "scam_recall": rec,
        "scam_f1": f1,
        "classification_report": report_dict,
        "confusion_matrix": {
            "classes": list(clf.classes_),
            "matrix": cm.tolist()
        },
        "error_analysis": {
            "false_positives": len(test[fp_mask]),
            "false_negatives": len(test[fn_mask]),
            "fp_examples": fp_examples,
            "fn_examples": fn_examples
        },
        "language_evaluation": lang_metrics,
        "category_evaluation": cat_metrics,
        "metadata": {
            "dataset": "scamshield_dataset_2000_cleaned.csv",
            "algorithm": "TF-IDF + Logistic Regression"
        }
    }
    with open('../reports/metrics.json', 'w') as f:
        json.dump(metrics, f, indent=4)
        
    # Save classification report text
    with open('../reports/classification_report.txt', 'w') as f:
        f.write("Classification Report on Test Set\n")
        f.write("=================================\n\n")
        f.write(report_str)
        
    # Save confusion matrix plot
    cm = confusion_matrix(y_test, y_pred, labels=clf.classes_)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=clf.classes_, yticklabels=clf.classes_)
    plt.title('Confusion Matrix - ScamShield Test Set')
    plt.ylabel('Actual Label')
    plt.xlabel('Predicted Label')
    plt.tight_layout()
    plt.savefig('../reports/confusion_matrix.png', dpi=300)
    
    print("Evaluation complete. Artifacts saved in ml/reports/")

if __name__ == "__main__":
    main()
