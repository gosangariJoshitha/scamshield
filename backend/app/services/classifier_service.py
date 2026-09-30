import os
import joblib
from app.services.text_service import preprocess_text

# Paths relative to this file, or we use absolute based on project root
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
MODEL_DIR = os.path.join(BASE_DIR, 'ml', 'models', 'classifier')
CLF_PATH = os.path.join(MODEL_DIR, 'scam_classifier.joblib')
VEC_PATH = os.path.join(MODEL_DIR, 'tfidf_vectorizer.joblib')

class ClassifierService:
    def __init__(self):
        self.clf = None
        self.vectorizer = None
        self.model_version = "scamshield-classifier-v1"
        self._load_models()

    def _load_models(self):
        """Loads models lazily or on init."""
        try:
            if os.path.exists(CLF_PATH) and os.path.exists(VEC_PATH):
                self.clf = joblib.load(CLF_PATH)
                self.vectorizer = joblib.load(VEC_PATH)
            else:
                print("WARNING: ML model artifacts not found.")
        except Exception as e:
            print(f"Error loading models: {e}")

    def predict(self, text: str):
        if not self.clf or not self.vectorizer:
            raise RuntimeError("ML model is currently unavailable.")

        processed_text = preprocess_text(text)
        if not processed_text.strip():
            # Handle empty/useless text gracefully
            return {
                "classification": "GENUINE",
                "ml_probability": 0.0,
                "model_version": self.model_version
            }

        # Vectorize
        X = self.vectorizer.transform([processed_text])
        
        # Predict
        pred = self.clf.predict(X)[0]  # 'scam' or 'genuine'
        
        # Probability
        probs = self.clf.predict_proba(X)[0]
        # Get index of the predicted class to find its probability
        # Or better, just get probability of 'scam' class explicitly
        classes = list(self.clf.classes_)
        if 'scam' in classes:
            scam_idx = classes.index('scam')
            ml_prob = float(probs[scam_idx])
        else:
            # Fallback
            pred_idx = classes.index(pred)
            ml_prob = float(probs[pred_idx])

        return {
            "classification": pred.upper(),  # 'SCAM' or 'GENUINE'
            "ml_probability": round(ml_prob, 4),
            "model_version": self.model_version
        }

classifier_service = ClassifierService()
