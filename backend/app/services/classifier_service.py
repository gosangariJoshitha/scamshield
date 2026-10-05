import os
import json
import logging

import joblib
from app.services.text_service import preprocess_text

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
MODEL_DIR = os.path.join(BASE_DIR, 'ml', 'models', 'classifier')
METADATA_PATH = os.path.join(MODEL_DIR, 'model_metadata.json')
LEGACY_CLF_PATH = os.path.join(MODEL_DIR, 'scam_classifier.joblib')
LEGACY_VEC_PATH = os.path.join(MODEL_DIR, 'tfidf_vectorizer.joblib')
logger = logging.getLogger(__name__)

class ClassifierService:
    def __init__(self):
        self.clf = None
        self.vectorizer = None
        self.model_version = "scamshield-classifier-v1"
        self.load_error = None
        self._load_models()

    def _load_models(self):
        try:
            metadata = {}
            if os.path.isfile(METADATA_PATH):
                with open(METADATA_PATH, encoding="utf-8") as metadata_file:
                    metadata = json.load(metadata_file)
            self.model_version = metadata.get("model_version", self.model_version)

            artifact_paths = metadata.get("artifact_paths", {})
            classifier_path = os.path.join(
                MODEL_DIR,
                artifact_paths.get("classifier", "scam_classifier.joblib"),
            )
            vectorizer_path = os.path.join(
                MODEL_DIR,
                artifact_paths.get("vectorizer", "tfidf_vectorizer.joblib"),
            )
            if not os.path.isfile(classifier_path) or not os.path.isfile(vectorizer_path):
                raise FileNotFoundError("Configured classifier artifacts are unavailable.")

            self.clf = joblib.load(classifier_path)
            self.vectorizer = joblib.load(vectorizer_path)
        except Exception as e:
            self.load_error = e
            logger.exception("Unable to load the configured classifier artifacts.")

    def predict(self, text: str):
        return self.predict_processed(preprocess_text(text))

    def predict_processed(self, processed_text: str):
        if self.clf is None or self.vectorizer is None:
            raise RuntimeError("ML model is currently unavailable.") from self.load_error

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
