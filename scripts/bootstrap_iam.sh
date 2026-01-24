#!/usr/bin/env bash
set -euo pipefail

# This script ensures the Cloud Build and Cloud Run service accounts
# have the necessary permissions for 2nd Gen triggers and MLOps workflows.

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  echo "This script should not be sourced."
  return 1
fi

source "$(dirname "$0")/../env.common.sh"

echo "Setting project to $PROJECT_ID..."
gcloud config set project "$PROJECT_ID" >/dev/null

# ---------------------------------------------------------
# 1. CLOUD BUILD 2ND GEN & SECRET MANAGER
# ---------------------------------------------------------

echo "Granting Secret Manager Access to Cloud Build Service Agent..."
# The Service Agent handles the background connection to GitHub
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin"

echo "Granting Secret Manager Access to Cloud Build SA..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/secretmanager.secretAccessor"

# ---------------------------------------------------------
# 2. DEPLOYMENT & TRIGGER EXECUTION (ActAs)
# ---------------------------------------------------------

echo "Allowing Cloud Build to actAs Compute Engine SA (Required for 2nd Gen)"
# This allows the trigger to execute using the user-managed service account
gcloud iam service-accounts add-iam-policy-binding "${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/iam.serviceAccountUser"

echo "Granting Cloud Build deploy and smoke test permissions"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/run.admin"

# Required to run 'gcloud run services describe' in automated smoke tests
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/run.viewer"

echo "Granting Cloud Build push permissions (Artifact Registry)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/artifactregistry.writer"

echo "Allowing Cloud Build to actAs runtime SA for Cloud Run deployments"
gcloud iam service-accounts add-iam-policy-binding "${RUNTIME_SA}" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/iam.serviceAccountUser"

# ---------------------------------------------------------
# 3. STORAGE & LOGGING (ML MODELS & TELEMETRY)
# ---------------------------------------------------------

echo "Granting read access to model bucket: gs://${MODEL_GCS_BUCKET}"
# Access for the running app on Cloud Run
gcloud storage buckets add-iam-policy-binding "gs://${MODEL_GCS_BUCKET}" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/storage.objectViewer"

# Access for Cloud Build to run CI/CD unit tests (pytest)
gcloud storage buckets add-iam-policy-binding "gs://${MODEL_GCS_BUCKET}" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/storage.objectViewer"

echo "Granting logging permissions for user-managed service account"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/logging.logWriter"

echo "----------------------------------------------------"
echo "IAM Bootstrapping Complete for Project: $PROJECT_ID"
echo "----------------------------------------------------"