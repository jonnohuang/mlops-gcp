import pandas as pd
import xgboost as xgb
import os

def load_trained_model(model_path):
    """Loads the XGBoost model from a JSON file."""
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"No model found at {model_path}")
    
    # Initialize the booster and load the JSON
    model = xgb.XGBClassifier()
    model.load_model(model_path)
    print(f"✅ Model loaded from {model_path}")
    return model

def run_inference(model, input_data):
    """
    Makes predictions on preprocessed numeric data.
    Note: input_data must have the exact same columns/hashing 
    applied as the training data (27 hashed components + encoded features).
    """
    predictions = model.predict(input_data)
    probabilities = model.predict_proba(input_data)[:, 1]
    
    return predictions, probabilities

# --- Example Usage ---
# Assuming 'x_test_hashing' from your previous script is available:
# model = load_trained_model("artifacts/xgboost_coupon_recommendation.json")
# preds, probs = run_inference(model, x_test_hashing.iloc[:5]) # Predict first 5 rows

# print("Predictions:", preds)
# print("Probabilities:", probs)