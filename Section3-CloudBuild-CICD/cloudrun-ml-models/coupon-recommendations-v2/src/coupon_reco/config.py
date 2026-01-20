import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    """Runtime configuration loaded from environment variables."""

    # Where to load the model artifact from.
    # Supported:
    #   - local file path (default)
    #   - gs://bucket/path/to/model.pkl
    MODEL_URI: str = os.getenv("MODEL_URI", "artifacts/xgboost_coupon_recommendation.pkl")

    # Flask/Gunicorn/Cloud Run listens on this port.
    PORT: int = int(os.getenv("PORT", "8080"))

    # Optional: GCP project override for local usage.
    GCP_PROJECT: str | None = os.getenv("GCP_PROJECT")

    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
