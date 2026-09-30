from app.services.classifier_service import classifier_service
from app.services.risk_engine import calculate_risk
from models import Analysis
from sqlalchemy.orm import Session

def run_text_analysis_pipeline(db: Session, text: str, user_id: int):
    # 1. Run ML Classifier
    ml_result = classifier_service.predict(text)
    
    # 2. Run Risk Engine
    risk_result = calculate_risk(
        ml_probability=ml_result["ml_probability"], 
        text=text, 
        classification=ml_result["classification"]
    )
    
    # 3. Compile full response (M3 level)
    # M4/M5 will fill explanation, evidence, recommended_action
    
    # We use empty/None for future milestone fields
    analysis_record = Analysis(
        user_id=user_id,
        content=text,
        risk_score=risk_result["risk_score"],
        risk_level=risk_result["risk_level"],
        classification=ml_result["classification"],
        ml_probability=ml_result["ml_probability"],
        category="Unknown", # Could be updated if we had a multi-class model
        indicators=risk_result["risk_factors"],
        explanation="",
        evidence=[],
        recommended_action=""
    )
    
    # 4. Save to Database
    db.add(analysis_record)
    db.commit()
    db.refresh(analysis_record)
    
    return analysis_record
