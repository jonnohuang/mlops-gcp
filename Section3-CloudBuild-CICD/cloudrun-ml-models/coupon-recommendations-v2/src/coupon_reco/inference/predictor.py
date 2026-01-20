from __future__ import annotations

import logging
import os
import pickle
import tempfile
from functools import lru_cache
from typing import Any

from google.cloud import storage

from coupon_reco.config import Settings

logger = logging.getLogger(__name__)


def _download_gcs_blob(gs_uri: str, dst_path: str, project: str | None = None) -> None:
    """Download a GCS object to local file.

    gs_uri: gs://bucket/path
    """
    assert gs_uri.startswith("gs://")
    without_scheme = gs_uri[len("gs://") :]
    bucket_name, _, blob_name = without_scheme.partition("/")
    if not bucket_name or not blob_name:
        raise ValueError(f"Invalid GCS URI: {gs_uri}")

    client = storage.Client(project=project) if project else storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename(dst_path)


@lru_cache(maxsize=1)
def load_model(settings: Settings | None = None) -> Any:
    """Load the trained model once per container.

    The default uses a local artifact path. To load from GCS, set MODEL_URI=gs://...

    NOTE: Cloud Run service account must have GCS read permissions if using GCS.
    """
    settings = settings or Settings()
    uri = settings.MODEL_URI

    if uri.startswith("gs://"):
        logger.info("Loading model from GCS: %s", uri)
        with tempfile.TemporaryDirectory() as td:
            local_path = os.path.join(td, os.path.basename(uri))
            _download_gcs_blob(uri, local_path, project=settings.GCP_PROJECT)
            with open(local_path, "rb") as f:
                return pickle.load(f)

    logger.info("Loading model from local path: %s", uri)
    with open(uri, "rb") as f:
        return pickle.load(f)


def predict(model: Any, features) -> list[int]:
    """Run model prediction and normalize output to a Python list."""
    y = model.predict(features)
    # xgboost/sklearn may return numpy array
    try:
        return y.tolist()  # type: ignore[attr-defined]
    except Exception:
        return [int(v) for v in y]
