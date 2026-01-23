#!/usr/bin/env bash
set -euo pipefail

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  echo "This script should not be sourced."
  return 1
fi

source "$(dirname "$0")/../env.common.sh"

gcloud config set project "$PROJECT_ID"

# ---------------------------------------------------------
# 1. CLOUD BUILD 2ND GEN & SECRET MANAGER
# ---------------------------------------------------------

echo "Granting Secret Manager Access to Cloud Build Service Agent (Required for 2nd Gen Connection)"
# This is the Google-managed agent that handles the GitHub connection
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin"

echo "Granting Secret Manager Access to Cloud Build SA (For accessing keys during build)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/secretmanager.secretAccessor"

# ---------------------------------------------------------
# 2. DEPLOYMENT & RUNTIME PERMISSIONS
# ---------------------------------------------------------

echo "Grant Cloud Build deploy permissions (Cloud Run)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/run.admin"

echo "Grant Cloud Build push permissions (Artifact Registry)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/artifactregistry.writer"

echo "Allow Cloud Build to actAs runtime service account (For Cloud Run deployment)"
gcloud iam service-accounts add-iam-policy-binding "${RUNTIME_SA}" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/iam.serviceAccountUser"

echo "Allow Cloud Build to use itself (Required for 2nd Gen trigger execution)"
gcloud iam service-accounts add-iam-policy-binding "${CLOUDBUILD_SA}" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/iam.serviceAccountUser"

# ---------------------------------------------------------
# 3. GCS PERMISSIONS (ML MODELS)
# ---------------------------------------------------------

echo "Grant Cloud Run runtime SA read access to model bucket (GCS)"
gcloud storage buckets add-iam-policy-binding "gs://${MODEL_GCS_BUCKET}" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/storage.objectViewer"

echo "Grant Cloud Build SA read access to model bucket (GCS) for CI tests"
gcloud storage buckets add-iam-policy-binding "gs://${MODEL_GCS_BUCKET}" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/storage.objectViewer"

echo "IAM Bootstrapping Complete."