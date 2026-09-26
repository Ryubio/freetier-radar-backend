import pytest
from fastapi.testclient import TestClient
from main import app
import os

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_services_list():
    response = client.get("/api/v1/services")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert isinstance(data["items"], list)

def test_sync_endpoint_auth_missing():
    response = client.post("/api/v1/sync")
    assert response.status_code in (401, 403)

def test_sync_endpoint_auth_invalid():
    response = client.post("/api/v1/sync", headers={"X-Sync-Token": "wrong-token"})
    assert response.status_code == 403
    assert response.json() == {"detail": "Invalid or missing sync token"}

def test_sync_endpoint_auth_valid(monkeypatch):
    test_token = "test-secret-key"
    monkeypatch.setenv("SYNC_SECRET_KEY", test_token)
    
    # Reload token from env in the module (workaround for module-level variables in tests)
    import main
    monkeypatch.setattr(main, "SYNC_SECRET_KEY", test_token)
    
    response = client.post("/api/v1/sync", headers={"X-Sync-Token": test_token})
    assert response.status_code == 202
    data = response.json()
    assert data["status"] == "accepted"
    assert data["message"] == "Scrape and sync cycle triggered in background"
    assert "timestamp" in data
