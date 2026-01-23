#!/usr/bin/env bash

export PROJECT_ID="ml-ops-on-gcp"
export PROJECT_NUMBER="79824532858"
export REGION="us-central1"

export CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
export RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
export CLOUDBUILD_SA_RESOURCE="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA}"

# ---- ML model artifact location (GCS) ----
# NOTE: Cloud Build does NOT automatically source env.common.sh.
# For Cloud Build/Cloud Run, these are typically injected via cloudbuild YAML (--set-env-vars)
export MODEL_GCS_BUCKET="ml-ops-on-gcp-data"
export MODEL_GCS_BLOB="ml-artifacts/xgboost_coupon_recommendation.pkl"

# ---- Local fallback model path (used when MODEL_GCS_* are not set) ----
export MODEL_LOCAL_PATH="artifacts/xgboost_coupon_recommendation.pkl"
