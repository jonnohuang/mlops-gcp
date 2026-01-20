import pandas as pd
from flask import Flask, request, jsonify
import joblib
import os
from google.cloud import storage

app = Flask(__name__)
model = None

def load_model():
    model = joblib.load("model.joblib")
    return model

def load_model_cloud():
    """Download model from GCS if configured."""
    bucket_name = os.environ.get("MODEL_BUCKET", "sid-kubeflow-v1")
    blob_name = os.environ.get("MODEL_BLOB", "bikeshare-model/artifact/model.joblib")
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename("model.joblib")
    return joblib.load("model.joblib")


@app.route('/predict', methods=['POST'])
def predict():
    # Load model: prefer local file in container, or download from GCS if configured.
    use_gcs = os.environ.get("USE_GCS_MODEL", "false").lower() == "true"
    model = load_model_cloud() if use_gcs else load_model()
    try : 
        input_json = request.get_json()
        input_df = pd.DataFrame(input_json, index=[0])
        y_predictions = model.predict(input_df)
        response = {'predictions': y_predictions.tolist()}
        return jsonify(response), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@app.route("/healthz", methods=["GET"])
def healthz():
    return {"status": "ok"}, 200

@app.route("/readyz", methods=["GET"])
def readyz():
    return {"status": "ready"}, 200

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
