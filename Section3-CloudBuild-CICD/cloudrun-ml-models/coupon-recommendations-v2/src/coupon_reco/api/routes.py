from __future__ import annotations

import logging
from flask import Blueprint, jsonify, request

from coupon_reco.config import Settings
from coupon_reco.inference.features import preprocess_request
from coupon_reco.inference.predictor import load_model, predict

logger = logging.getLogger(__name__)

bp = Blueprint("api", __name__)


@bp.get("/healthz")
def healthz():
    return jsonify({"status": "ok"}), 200


@bp.get("/readyz")
def readyz():
    """Readiness: ensure model can be loaded."""
    try:
        _ = load_model(Settings())
        return jsonify({"status": "ready"}), 200
    except Exception as e:
        logger.exception("Readiness check failed")
        return jsonify({"status": "not_ready", "error": str(e)}), 500


@bp.post("/predict")
def predict_route():
    try:
        payload = request.get_json(force=True, silent=False)
        feats = preprocess_request(payload)
        model = load_model(Settings())
        preds = predict(model, feats)
        return jsonify({"predictions": preds}), 200
    except Exception as e:
        logger.exception("Prediction failed")
        return jsonify({"error": str(e)}), 400
