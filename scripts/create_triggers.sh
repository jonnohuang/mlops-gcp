#!/usr/bin/env bash
set -euo pipefail

# Creates TWO Cloud Build triggers for a given lab:
#  - main -> deploys to production service name
#  - dev  -> deploys to a '-dev' service name
#
# Requires a GitHub-connected Cloud Build repo already.
# Usage:
#   bash scripts/create_triggers.sh <trigger_base_name> <repo_owner> <repo_name> <branch_main> <branch_dev> <lab_dir> <service_name> <ar_repo> <image_name>
# Example:
#   bash scripts/create_triggers.sh coupon-reco jonnohuang mlops-gcp main dev Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations coupon-recommendations python-apps coupon-reco

BASE_NAME="${1:-}"
OWNER="${2:-}"
REPO="${3:-}"
BR_MAIN="${4:-main}"
BR_DEV="${5:-dev}"
LAB_DIR="${6:-}"
SERVICE_NAME="${7:-}"
AR_REPO="${8:-python-apps}"
IMAGE_NAME="${9:-}"

if [[ -z "$BASE_NAME" || -z "$OWNER" || -z "$REPO" || -z "$LAB_DIR" || -z "$SERVICE_NAME" || -z "$IMAGE_NAME" ]]; then
  echo "Missing args. See header comment for usage."
  exit 1
fi

source "$(dirname "$0")/../env.common.sh"

gcloud config set project "$PROJECT_ID"

CONFIG_PATH="$LAB_DIR/cloudbuild.yaml"

# Main trigger (prod)
echo "Creating trigger: ${BASE_NAME}-main (branch ${BR_MAIN})"
gcloud builds triggers create github \
  --name="${BASE_NAME}-main" \
  --repo-name="${REPO}" \
  --repo-owner="${OWNER}" \
  --branch-pattern="^${BR_MAIN}$" \
  --build-config="$CONFIG_PATH" \
  --substitutions="_REGION=${REGION},_AR_REPO=${AR_REPO},_SERVICE=${SERVICE_NAME},_IMAGE=${IMAGE_NAME}"

# Dev trigger (staging)
echo "Creating trigger: ${BASE_NAME}-dev (branch ${BR_DEV})"
gcloud builds triggers create github \
  --name="${BASE_NAME}-dev" \
  --repo-name="${REPO}" \
  --repo-owner="${OWNER}" \
  --branch-pattern="^${BR_DEV}$" \
  --build-config="$CONFIG_PATH" \
  --substitutions="_REGION=${REGION},_AR_REPO=${AR_REPO},_SERVICE=${SERVICE_NAME}-dev,_IMAGE=${IMAGE_NAME}"

echo "Done. Push to '${BR_DEV}' to test on GCP without touching main."
