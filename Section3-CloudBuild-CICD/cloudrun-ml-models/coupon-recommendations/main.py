import os
from typing import Any, Dict, List, Optional
import pandas as pd
import xgboost as xgb
from flask import Flask, jsonify, request
from category_encoders import HashingEncoder
from google.cloud import storage

app = Flask(__name__)

# Config
MODEL_GCS_BUCKET = os.getenv("MODEL_GCS_BUCKET")
MODEL_GCS_BLOB = os.getenv("MODEL_GCS_BLOB", "ml-artifacts/xgboost_coupon_recommendation.json")
MODEL_LOCAL_PATH = os.getenv("MODEL_LOCAL_PATH", "artifacts/xgboost_coupon_recommendation.json")

_model = None
_expected_features: Optional[List[str]] = None

def _download_model_from_gcs(bucket_name: str, blob_name: str, local_path: str) -> None:
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename(local_path)

def load_model():
    global _model, _expected_features
    if _model is not None:
        return _model

    load_path = MODEL_LOCAL_PATH
    if MODEL_GCS_BUCKET and MODEL_GCS_BLOB:
        load_path = "/tmp/model.json"
        _download_model_from_gcs(MODEL_GCS_BUCKET, MODEL_GCS_BLOB, load_path)

    # Native Booster loading to match your save_model logic
    _model = xgb.Booster()
    _model.load_model(load_path)
    
    _expected_features = _model.feature_names
    return _model

def preprocess_data(df: pd.DataFrame) -> pd.DataFrame:
    """Matches the exact feature engineering from your training notebook."""
    # Handle missing values using mode (as per training)
    df = df.fillna(df.mode().iloc[0])
    
    # Age Mapping
    age_mapping = {
        'below21': '<21', '21': '21-30', '26': '21-30',
        '31': '31-40', '36': '31-40', '41': '41-50', '46': '41-50'
    }
    df['age'] = df['age'].map(lambda x: age_mapping.get(str(x), '>50'))

    # Feature Concatenation
    df['passanger_destination'] = df['passanger'].astype(str) + '-' + df['destination'].astype(str)
    df['marital_hasChildren'] = df['maritalStatus'].astype(str) + '-' + df['has_children'].astype(str)
    df['temperature_weather'] = df['temperature'].astype(str) + '-' + df['weather'].astype(str)
    
    # Drop columns that were dropped in training
    drop_cols = ['passanger', 'destination', 'maritalStatus', 'has_children', 
                 'temperature', 'weather', 'gender', 'RestaurantLessThan20']
    df = df.drop(columns=[c for c in drop_cols if c in df.columns])

    # Ordinal Encoding
    encoding_map = {
        'expiration': {'2h': 0, '1d': 1},
        'age': {'<21': 0, '21-30': 1, '31-40': 2, '41-50': 3, '>50': 4},
        'education': {
            'Some High School': 0, 'High School Graduate': 1, 
            'Some college - no degree': 2, 'Associates degree': 3, 
            'Bachelors degree': 4, 'Graduate degree (Masters or Doctorate)': 5
        },
        'Bar': {'never': 0, 'less1': 1, '1~3': 2, '4~8': 3, 'gt8': 4},
        'CoffeeHouse': {'never': 0, 'less1': 1, '1~3': 2, '4~8': 3, 'gt8': 4}, 
        'CarryAway': {'never': 0, 'less1': 1, '1~3': 2, '4~8': 3, 'gt8': 4}, 
        'Restaurant20To50': {'never': 0, 'less1': 1, '1~3': 2, '4~8': 3, 'gt8': 4},
        'income': {
            'Less than $12500': 0, '$12500 - $24999': 1, '$25000 - $37499': 2, 
            '$37500 - $49999': 3, '$50000 - $62499': 4, '$62500 - $74999': 5, 
            '$75000 - $87499': 6, '$87500 - $99999': 7, '$100000 or More': 8
        },
        'time': {'7AM': 0, '10AM': 1, '2PM': 2, '6PM': 3, '10PM': 4}
    }
    df = df.replace(encoding_map)
    return df

def encode_features(x: pd.DataFrame, n_components: int = 27) -> pd.DataFrame:
    cat_cols = ["passanger_destination", "marital_hasChildren", "occupation", "coupon", "temperature_weather"]
    enc = HashingEncoder(cols=cat_cols, n_components=n_components)
    return enc.fit_transform(x)

def preprocess(payload: Dict[str, Any]) -> pd.DataFrame:
    load_model()
    df = pd.DataFrame([payload])
    
    # Execute the engineering steps
    df_cleaned = preprocess_data(df)
    df_encoded = encode_features(df_cleaned)
    
    # Align with Booster feature names
    for c in _expected_features:
        if c not in df_encoded.columns:
            df_encoded[c] = 0
            
    return df_encoded.reindex(columns=_expected_features).fillna(0)

@app.route("/", methods=["GET"])
def index():
    return jsonify({"service": "coupon-recommendation-api", "status": "online