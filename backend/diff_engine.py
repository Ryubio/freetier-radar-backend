import hashlib
import difflib
from typing import Optional, Tuple
from models import ServiceItem, DeprecationAlert
import re

def compute_content_hash(text: str) -> str:
    """Computes a SHA-256 hash of normalized text."""
    if not text:
        return ""
    # Normalize whitespace and lowercase
    normalized = re.sub(r'\s+', ' ', text).strip().lower()
    return hashlib.sha256(normalized.encode('utf-8')).hexdigest()

def extract_limits(text: str) -> str:
    """Heuristic to extract numeric limits from a string."""
    matches = re.findall(r'\b\d+(?:,\d+)*(?:\.\d+)?\s*[kKmMbBgGtT]?[bB]?\b', text)
    return ", ".join(matches) if matches else text

def classify_change_and_extract_limits(old_text: str, new_text: str) -> Tuple[str, str, str, str]:
    """
    Classifies a change and attempts to extract the specific old/new limits.
    Returns: (alert_type, summary, old_limit_str, new_limit_str)
    """
    old_text_lower = old_text.lower()
    new_text_lower = new_text.lower()
    
    alert_type = "POLICY_CHANGE"
    summary = "Free tier terms have changed."
    
    # Try to find numeric reductions
    old_numbers = [float(re.sub(r'[^\d.]', '', n)) for n in re.findall(r'\d+(?:\.\d+)?', old_text) if re.sub(r'[^\d.]', '', n)]
    new_numbers = [float(re.sub(r'[^\d.]', '', n)) for n in re.findall(r'\d+(?:\.\d+)?', new_text) if re.sub(r'[^\d.]', '', n)]
    
    old_sum = sum(old_numbers)
    new_sum = sum(new_numbers)
    
    if new_sum < old_sum:
        alert_type = "TIER_DOWNGRADE"
        summary = "Quota reduction or stricter limits detected."
    elif new_sum > old_sum:
        alert_type = "TIER_UPGRADE"
        summary = "Quota increased!"
        
    # Check for keywords
    downgrade_words = ['reduced', 'removed', 'discontinued', 'deprecated', 'no longer free']
    if any(w in new_text_lower and w not in old_text_lower for w in downgrade_words):
        alert_type = "TIER_DOWNGRADE"
        summary = "Service limits reduced or deprecated."
        
    old_limit_extract = extract_limits(old_text)
    new_limit_extract = extract_limits(new_text)
    
    # Fallback to full text if heuristics fail to find numbers
    if not old_limit_extract: old_limit_extract = old_text
    if not new_limit_extract: new_limit_extract = new_text
    
    return alert_type, summary, old_limit_extract, new_limit_extract

def detect_tier_changes(service: ServiceItem, new_description: str) -> Optional[DeprecationAlert]:
    """
    Compares the new description against the existing service.
    If changed, returns a DeprecationAlert.
    """
    new_hash = compute_content_hash(new_description)
    
    # If it's a new service or hash hasn't changed, do nothing
    if not service.content_hash or service.content_hash == new_hash:
        return None
        
    # Content has changed!
    alert_type, summary, old_limit, new_limit = classify_change_and_extract_limits(
        service.free_tier_limits, new_description
    )
    
    alert = DeprecationAlert(
        service_id=service.id,
        service_name=service.name,
        alert_type=alert_type,
        summary=summary,
        old_limit=old_limit,
        new_limit=new_limit,
        previous_hash=service.content_hash,
        current_hash=new_hash
    )
    
    return alert
