#!/usr/bin/env bash

export PROJECT_ID="ml-ops-on-gcp"
export PROJECT_NUMBER="79824532858"
export REGION="us-central1"

# ---- Cloud Build 2nd Gen Info ----
export CONNECTION_NAME="2gen-github-connection"
export REPO_NAME="jonnohuang-mlops-gcp"

export CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
export RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
export CLOUDBUILD_SA_RESOURCE="projects/${PROJECT_ID}/serviceAccounts/${CLOUDBUILD_SA}"

# ---- ML model artifact location (GCS) ----
export MODEL_GCS_BUCKET="ml-ops-on-gcp-data"
export MODEL_GCS_BLOB="ml-artifacts/xgboost_coupon_recommendation.pkl"

# ---- Local fallback model path ----
export MODEL_LOCAL_PATH="artifacts/xgboost_coupon_recommendation.pkl"