#!/usr/bin/env bash
set -euo pipefail

# Example (manual) build/push/deploy commands.
# Prefer Cloud Build trigger using cloudbuild.yaml.

# REGION=us-central1
# PROJECT_ID=your-gcp-project
# AR_REPO=ml-services
# SERVICE=coupon-recommendations
# IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVICE}"
#
# docker build -t "${IMAGE}:local" .
# docker push "${IMAGE}:local"  # requires docker auth for Artifact Registry
# gcloud run deploy "${SERVICE}" --image "${IMAGE}:local" --region "${REGION}" --allow-unauthenticated \
#   --set-env-vars MODEL_URI=gs://your-bucket/path/to/xgboost_coupon_recommendation.pkl

# Smoke test an already deployed service:
SERVICE_URL="${SERVICE_URL:-https://YOUR_CLOUD_RUN_URL}"
./scripts/smoke_test.sh
