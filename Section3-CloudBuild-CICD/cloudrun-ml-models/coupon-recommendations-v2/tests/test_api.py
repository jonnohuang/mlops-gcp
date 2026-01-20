import os

import pytest

from coupon_reco.app import create_app


@pytest.fixture(autouse=True)
def _set_model_uri(monkeypatch):
    # Ensure tests use local artifact (no GCP creds required)
    monkeypatch.setenv("MODEL_URI", "artifacts/xgboost_coupon_recommendation.pkl")


@pytest.fixture
def client():
    app = create_app()
    app.testing = True
    with app.test_client() as client:
        yield client


def test_healthz(client):
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.json == {"status": "ok"}


def test_predict_success(client):
    input_data = {
        "destination": "No Urgent Place",
        "passanger": "Kid(s)",
        "weather": "Sunny",
        "temperature": 80,
        "time": "10AM",
        "coupon": "Bar",
        "expiration": "1d",
        "gender": "Female",
        "age": "21",
        "maritalStatus": "Unmarried partner",
        "has_children": 1,
        "education": "Some college - no degree",
        "occupation": "Unemployed",
        "income": "$37500 - $49999",
        "Bar": "never",
        "CoffeeHouse": "never",
        "CarryAway": "4~8",
        "RestaurantLessThan20": "4~8",
        "Restaurant20To50": "1~3",
        "toCoupon_GEQ15min": 1,
        "toCoupon_GEQ25min": 0,
        "direction_same": 0,
    }
    r = client.post("/predict", json=input_data)
    assert r.status_code == 200
    assert "predictions" in r.json
    assert r.json["predictions"][0] in [0, 1]


def test_predict_failure_bad_shape(client):
    # Provide list values where scalars are expected
    input_data = {"destination": ["No Urgent Place"], "passanger": ["Kid(s)"]}
    r = client.post("/predict", json=input_data)
    assert r.status_code == 400
    assert "error" in r.json
