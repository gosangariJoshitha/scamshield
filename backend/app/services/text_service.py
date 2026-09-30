import re
import unicodedata

def normalize_text(text: str) -> str:
    """Normalizes Unicode and whitespace."""
    if not isinstance(text, str):
        return ""
    # Normalize unicode characters (e.g. smart quotes, em dashes)
    text = unicodedata.normalize('NFKC', text)
    # Replace newlines and tabs with space
    text = re.sub(r'[\r\n\t]+', ' ', text)
    # Remove multiple spaces
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def preprocess_text(text: str) -> str:
    """
    Cleans text for ML without destroying scam indicators.
    We convert to lowercase, but preserve URLs, numbers, OTPs, etc.
    """
    text = normalize_text(text)
    # Lowercase everything for standard ML features
    text = text.lower()
    
    # We deliberately DO NOT remove punctuation or numbers entirely,
    # as things like '!!!', '$', '₹', '1000' are strong scam indicators.
    # We DO NOT remove stop words heavily because phrases like "your account has been" are important.
    
    # However, we can optionally mask some highly variable entities if we want,
    # but the prompt states "Preserve important information... Do NOT remove URLs or numbers blindly."
    # So we leave them as is, just normalized.
    return text
