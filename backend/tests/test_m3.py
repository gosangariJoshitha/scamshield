import pytest
import os
import sys

# Add backend to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../')))

from app.services.text_service import preprocess_text
from app.services.classifier_service import ClassifierService
from app.services.risk_engine import calculate_risk
from app.pipeline.analysis_pipeline import run_text_analysis_pipeline

def test_preprocessing():
    text = "  Please share your OTP \n\n 12345 "
    processed = preprocess_text(text)
    # Check normalization
    assert processed == "please share your otp 12345"
    
def test_classifier_service():
    service = ClassifierService()
    if not service.clf or not service.vectorizer:
        pytest.skip("Models not found, skipping inference test.")
    
    # Test scam
    res = service.predict("urgent! your account is blocked. click here and send OTP")
    assert res['classification'] in ['SCAM', 'GENUINE']
    assert 0 <= res['ml_probability'] <= 1.0

def test_risk_score_between_0_and_100():
    res1 = calculate_risk(0.9, "urgent otp", "SCAM")
    assert 0 <= res1['risk_score'] <= 100
    assert res1['risk_level'] in ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
    
    res2 = calculate_risk(0.1, "hello mom", "GENUINE")
    assert 0 <= res2['risk_score'] <= 100

def test_genuine_message_handling():
    res = calculate_risk(0.1, "hello mom how are you", "GENUINE")
    assert res['risk_level'] == 'LOW'

def test_risk_level_thresholds():
    # Force scores by mocking ml_probability
    assert calculate_risk(0.1, "", "GENUINE")['risk_level'] == 'LOW'
    assert calculate_risk(0.5, "", "SCAM")['risk_level'] == 'MEDIUM'
    assert calculate_risk(0.7, "", "SCAM")['risk_level'] == 'HIGH'
    assert calculate_risk(0.9, "", "SCAM")['risk_level'] == 'CRITICAL'
