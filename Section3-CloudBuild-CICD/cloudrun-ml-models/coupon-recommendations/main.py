import os
import pickle
from typing import Any, Dict, List, Optional

import pandas as pd
from flask import Flask, jsonify, request
from category_encoders import HashingEncoder
from google.cloud import storage

app = Flask(__name__)

# -----------------------------
# Config (env vars)
# -----------------------------
# If these are set, load model from GCS (Cloud Run). Otherwise load local artifact.
MODEL_GCS_BUCKET = os.getenv("MODEL_GCS_BUCKET")  # e.g. "ml-ops-on-gcp-data"
MODEL_GCS_BLOB = os.getenv("MODEL_GCS_BLOB")      # e.g. "ml-artifacts/xgboost_coupon_recommendation.pkl"

MODEL_LOCAL_PATH = os.getenv("MODEL_LOCAL_PATH", "artifacts/xgboost_coupon_recommendation.pkl")

# -----------------------------
# Model cache
# -----------------------------
_model = None
_expected_features: Optional[List[str]] = None


def _download_model_from_gcs(bucket_name: str, blob_name: str, local_path: str) -> None:
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename(local_path)


def load_model():
    """
    Loads and caches the model, and caches the expected feature names/order.
    """
    global _model, _expected_features

    if _model is not None and _expected_features is not None:
        return _model

    # Option A: Load from GCS (Cloud Run)
    if MODEL_GCS_BUCKET and MODEL_GCS_BLOB:
        local_tmp = "/tmp/xgboost_coupon_recommendation.pkl"
        _download_model_from_gcs(MODEL_GCS_BUCKET, MODEL_GCS_BLOB, local_tmp)
        with open(local_tmp, "rb") as f:
            _model = pickle.load(f)
    else:
        # Option B: Load from local file
        if not os.path.exists(MODEL_LOCAL_PATH):
            raise FileNotFoundError(
                f"Model artifact not found at {MODEL_LOCAL_PATH}. "
                "Set MODEL_LOCAL_PATH or provide the artifacts file."
            )
        with open(MODEL_LOCAL_PATH, "rb") as f:
            _model = pickle.load(f)

    # Expected feature order from training
    try:
        booster = _model.get_booster()
        _expected_features = booster.feature_names or []
    except Exception:
        _expected_features = []

    if not _expected_features:
        raise ValueError(
            "Model has no feature_names; cannot safely align inference features. "
            "Retrain/export model with feature names or save schema alongside the model."
        )

    return _model


def preprocess_data(df: pd.DataFrame) -> pd.DataFrame:
    df = df.fillna(df.mode().iloc[0])
    df = df.drop_duplicates()

    df_dummy = df.copy()

    age_mapping = {
        "below21": "<21",
        "21": "21-30",
        "26": "21-30",
        "31": "31-40",
        "36": "31-40",
        "41": "41-50",
        "46": "41-50",
    }
    df_dummy["age"] = [age_mapping.get(v, ">50") for v in df_dummy["age"]]

    df_dummy["passanger_destination"] = (
        df_dummy["passanger"].astype(str) + "-" + df_dummy["destination"].astype(str)
    )
    df_dummy["marital_hasChildren"] = (
        df_dummy["maritalStatus"].astype(str) + "-" + df_dummy["has_children"].astype(str)
    )
    df_dummy["temperature_weather"] = (
        df_dummy["temperature"].astype(str) + "-" + df_dummy["weather"].astype(str)
    )

    df_dummy = df_dummy.drop(
        columns=[
            "passanger",
            "destination",
            "maritalStatus",
            "has_children",
            "temperature",
            "weather",
        ]
    )

    # Drop columns removed in training
    df_dummy = df_dummy.drop(columns=["gender", "RestaurantLessThan20"])

    df_le = df_dummy.replace(
        {
            "expiration": {"2h": 0, "1d": 1},
            "age": {"<21": 0, "21-30": 1, "31-40": 2, "41-50": 3, ">50": 4},
            "education": {
                "Some High School": 0,
                "High School Graduate": 1,
                "Some college - no degree": 2,
                "Associates degree": 3,
                "Bachelors degree": 4,
                "Graduate degree (Masters or Doctorate)": 5,
            },
            "Bar": {"never": 0, "less1": 1, "1~3": 2, "4~8": 3, "gt8": 4},
            "CoffeeHouse": {"never": 0, "less1": 1, "1~3": 2, "4~8": 3, "gt8": 4},
            "CarryAway": {"never": 0, "less1": 1, "1~3": 2, "4~8": 3, "gt8": 4},
            "Restaurant20To50": {"never": 0, "less1": 1, "1~3": 2, "4~8": 3, "gt8": 4},
            "income": {
                "Less than $12500": 0,
                "$12500 - $24999": 1,
                "$25000 - $37499": 2,
                "$37500 - $49999": 3,
                "$50000 - $62499": 4,
                "$62500 - $74999": 5,
                "$75000 - $87499": 6,
                "$87500 - $99999": 7,
                "$100000 or More": 8,
            },
            "time": {"7AM": 0, "10AM": 1, "2PM": 2, "6PM": 3, "10PM": 4},
        }
    )

    return df_le


def encode_features(x: pd.DataFrame, n_components: int = 27) -> pd.DataFrame:
    cat_cols = [
        "passanger_destination",
        "marital_hasChildren",
        "occupation",
        "coupon",
        "temperature_weather",
    ]
    enc = HashingEncoder(cols=cat_cols, n_components=n_components)
    x_encoded = enc.fit_transform(x)

    # Drop original categorical cols if still present
    for c in cat_cols:
        if c in x_encoded.columns:
            x_encoded = x_encoded.drop(columns=[c])

    return x_encoded


def _normalize_single_row_payload(payload: Dict[str, Any]) -> Dict[str, Any]:
    # Reject list values (this endpoint is single-row only)
    for k, v in payload.items():
        if isinstance(v, list):
            raise ValueError(
                f"Field '{k}' must be a single value (not a list). "
                "This endpoint supports single-row predictions only."
            )
    return payload


def preprocess(payload: Dict[str, Any]) -> pd.DataFrame:
    """
    Returns a 1-row DataFrame:
    - numeric values only
    - aligned to model feature names + order
    """
    load_model()  # ensures _expected_features is populated

    payload = _normalize_single_row_payload(payload)
    df = pd.DataFrame([payload])

    x = preprocess_data(df)
    x_encoded = encode_features(x)

    # Ensure numeric
    bad = [c for c in x_encoded.columns if x_encoded[c].dtype == "object"]
    if bad:
        for c in bad:
            x_encoded[c] = pd.to_numeric(x_encoded[c], errors="coerce")
        still_bad = [c for c in x_encoded.columns if x_encoded[c].dtype == "object"]
        if still_bad:
            raise ValueError(f"Non-numeric columns remain: {still_bad}")

    x_encoded = x_encoded.fillna(0)

    # Align to model schema (names + order)
    assert _expected_features is not None
    for c in _expected_features:
        if c not in x_encoded.columns:
            x_encoded[c] = 0

    x_encoded = x_encoded.reindex(columns=_expected_features)
    return x_encoded


@app.route("/predict", methods=["POST"])
def predict():
    try:
        m = load_model()
        payload = request.get_json(silent=True)

        if not isinstance(payload, dict):
            return jsonify({"error": "Request body must be a JSON object."}), 400

        X = preprocess(payload)
        y = m.predict(X)

        preds = [int(v) for v in y]  # converts np.int64 -> int
        return jsonify({"predictions": preds}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route("/healthz", methods=["GET"])
def healthz():
    return {"status": "ok"}, 200


@app.route("/readyz", methods=["GET"])
def readyz():
    try:
        load_model()
        return {"status": "ready"}, 200
    except Exception as e:
        return {"status": "not_ready", "error": str(e)}, 500


if __name__ == "__main__":
    # For curl, debug=True returns HTML tracebacks; FLASK_DEBUG=0 gives JSON errors.
    debug = os.getenv("FLASK_DEBUG", "0") == "1"
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)), debug=debug)
