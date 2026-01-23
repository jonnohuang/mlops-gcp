# Grants required for:
# - Cloud Build: build, push, and run CI tests that load ML model from GCS
# - Cloud Run: runtime access to ML model stored in GCS

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  echo "This script should not be sourced."
  return 1
fi

#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.common.sh"

gcloud config set project "$PROJECT_ID"

echo "Grant Cloud Build deploy permissions (Cloud Run)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/run.admin"

echo "Grant Cloud Build push permissions (Artifact Registry)"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/artifactregistry.writer"

echo "Allow Cloud Build to actAs runtime service account"
gcloud iam service-accounts add-iam-policy-binding "${RUNTIME_SA}" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/iam.serviceAccountUser"

echo "Grant Cloud Run runtime SA read access to model bucket (GCS)"
gcloud storage buckets add-iam-policy-binding "gs://${MODEL_GCS_BUCKET}" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/storage.objectViewer"

echo "Grant Cloud Build SA read access to model bucket (GCS) for CI tests"
gcloud storage buckets add-iam-policy-binding "gs://${MODEL_GCS_BUCKET}" \
  --member="serviceAccount:${CLOUDBUILD_SA}" \
  --role="roles/storage.objectViewer"

echo "Done."
