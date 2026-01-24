import os
import pytest
import main
from main import app

@pytest.fixture(scope="session", autouse=True)
def ensure_local_artifact_or_skip():
    # Update to .json
    model_path = os.getenv("MODEL_LOCAL_PATH", "artifacts/xgboost_coupon_recommendation.json")
    if not os.path.exists(model_path):
        pytest.skip(f"Missing model artifact at {model_path}")

@pytest.fixture(scope="session", autouse=True)
def force_local_load():
    os.environ.pop("MODEL_GCS_BUCKET", None)
    os.environ.pop("MODEL_GCS_BLOB", None)

@pytest.fixture
def client():
    with app.test_client() as c:
        yield c

def test_readyz(client):
    resp = client.get("/readyz")
    assert resp.status_code == 200

def test_predict_success(client):
    input_data = {"destination": "No Urgent Place", "passanger": "Kid(s)", "weather": "Sunny", "temperature": 80, "time": "10AM", "coupon": "Bar", "expiration": "1d", "gender": "Female", "age": "21", "maritalStatus": "Unmarried partner", "has_children": 1, "education": "Some college - no degree", "occupation": "Unemployed", "income": "$37500 - $49999", "Bar": "never", "CoffeeHouse": "never", "CarryAway": "4~8", "RestaurantLessThan20": "4~8", "Restaurant20To50": "1~3", "toCoupon_GEQ15min": 1, "toCoupon_GEQ25min": 0, "direction_same": 0}
    resp = client.post("/predict", json=input_data)
    assert resp.status_code == 200
    assert "predictions" in resp.json