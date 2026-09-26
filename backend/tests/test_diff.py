import pytest
from diff_engine import detect_tier_changes
from models import ServiceItem, ServiceCategory
from datetime import datetime, timezone

def test_diff_engine_alert_downgrade():
    from diff_engine import compute_content_hash
    existing = ServiceItem(
        name="Test Service",
        category=ServiceCategory.OTHER,
        short_description="Testing limits",
        free_tier_limits="100GB bandwidth, 1000 users",
        official_url="https://test.com",
        content_hash=compute_content_hash("100GB bandwidth, 1000 users")
    )
    
    new_limit_str = "50GB bandwidth, 1000 users"
    alert = detect_tier_changes(existing, new_limit_str)
    
    assert alert is not None
    assert alert.alert_type == "TIER_DOWNGRADE"
    assert "100" in alert.old_limit or "100GB" in alert.old_limit
    assert "50" in alert.new_limit or "50GB" in alert.new_limit
    assert alert.service_name == "Test Service"

def test_diff_engine_no_alert_for_same():
    from diff_engine import compute_content_hash
    existing = ServiceItem(
        name="Test Service",
        category=ServiceCategory.OTHER,
        short_description="Testing limits",
        free_tier_limits="100GB bandwidth, 1000 users",
        official_url="https://test.com",
        content_hash=compute_content_hash("100GB bandwidth, 1000 users")
    )
    
    new_limit_str = "100GB bandwidth, 1000 users"
    alert = detect_tier_changes(existing, new_limit_str)
    
    assert alert is None
