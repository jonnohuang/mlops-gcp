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

echo "Done."
