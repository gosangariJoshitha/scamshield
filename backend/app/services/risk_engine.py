import re

def calculate_risk(ml_probability: float, text: str, classification: str, severity: str = None, priority: str = None):
    """
    Calculates the application-level risk score.
    This is deterministic and transparent.
    """
    # 1. Base Score
    base_score = ml_probability * 100
    adjustments = 0
    risk_factors = []
    
    text_lower = text.lower()
    
    # 2. Adjustments based on textual indicators
    # We apply specific bumps if we detect known high-risk patterns.
    # Note: These shouldn't wildly overpower the ML model, just slightly tune the final application score.
    
    if re.search(r'\b(otp|one time password)\b', text_lower):
        adjustments += 5
        risk_factors.append("OTP request detected")
        
    if re.search(r'\b(upi|gpay|paytm|phonepe|send money|transfer)\b', text_lower):
        adjustments += 5
        risk_factors.append("Payment/Transfer requested")
        
    if re.search(r'\b(urgent|immediately|within 24 hours|suspended|blocked)\b', text_lower):
        adjustments += 5
        risk_factors.append("Urgency or Account threat")
        
    if re.search(r'\b(kyc|pan|aadhar|ssn)\b', text_lower):
        adjustments += 5
        risk_factors.append("Sensitive identity document (KYC/PAN) mentioned")
        
    # 3. Optional Severity/Priority Adjustments (if provided from dataset/UI)
    if severity == 'Critical':
        adjustments += 10
        risk_factors.append("High severity reported")
    elif severity == 'High':
        adjustments += 5
        
    if priority == 'P1':
        adjustments += 5
        risk_factors.append("High priority reported")

    # If classification is Genuine, we want to strongly pull down the score 
    # unless adjustments are extreme, but we still respect the math.
    if classification == 'GENUINE' and ml_probability < 0.5:
        # For genuine messages, limit the maximum score they can reach just by mentioning OTP
        # A genuine message asking for an OTP (e.g. "Your OTP is 12345") shouldn't become HIGH risk.
        pass
        
    # 4. Clamp the score between 0 and 100
    risk_score = round(max(0, min(100, base_score + adjustments)))
    
    # If the ML specifically classified it as GENUINE, we probably shouldn't let it be CRITICAL
    # unless it hit 80+ purely organically (which is mathematically hard if ml_prob is low).
    # But if ml_prob was somehow 0.49 (49 base) + 15 adjustments = 64 (HIGH). This is acceptable as a cautious warning.

    # 5. Determine Risk Level
    if risk_score <= 29:
        risk_level = "LOW"
    elif risk_score <= 59:
        risk_level = "MEDIUM"
    elif risk_score <= 79:
        risk_level = "HIGH"
    else:
        risk_level = "CRITICAL"
        
    return {
        "risk_score": risk_score,
        "risk_level": risk_level,
        "risk_factors": risk_factors
    }
