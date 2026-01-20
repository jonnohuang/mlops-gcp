#!/usr/bin/env bash
set -euo pipefail

# Create two Cloud Build triggers (dev and main) for a Cloud Run lab.
#
# Example:
#   bash scripts/create_trigger_cloudrun.sh \
#     name_base=coupon-reco \
#     repo_owner=jonnohuang \
#     repo_name=mlops-gcp \
#     build_yaml=Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations/cloudbuild.yaml \
#     service=coupon-recommendations \
#     ar_repo=python-apps \
#     image=coupon-reco
#
# Notes:
# - Requires GitHub App connection already set up in Cloud Build
# - Creates triggers that deploy to Cloud Run service `<service>-dev` on dev, and `<service>` on main

source "$(dirname "$0")/../env.common.sh"

# Parse key=value args
for arg in "$@"; do
  case "$arg" in
    *=*) export "${arg}" ;;
    *) echo "Invalid arg: $arg (expected key=value)"; exit 1 ;;
  esac
done

: "${name_base:?missing name_base}"
: "${repo_owner:?missing repo_owner}"
: "${repo_name:?missing repo_name}"
: "${build_yaml:?missing build_yaml}"
: "${service:?missing service}"
: "${ar_repo:?missing ar_repo}"
: "${image:?missing image}"

gcloud config set project "$PROJECT_ID"

create_trigger() {
  local trig_name="$1"
  local branch_regex="$2"
  local svc="$3"

  gcloud builds triggers create github \
    --name="$trig_name" \
    --repo-owner="$repo_owner" \
    --repo-name="$repo_name" \
    --branch-pattern="$branch_regex" \
    --build-config="$build_yaml" \
    --substitutions="_REGION=${REGION},_AR_REPO=${ar_repo},_IMAGE=${image},_SERVICE=${svc}" \
    --region="$REGION"
}

create_trigger "${name_base}-dev" "^dev$" "${service}-dev"
create_trigger "${name_base}-main" "^main$" "${service}"

echo "Created triggers: ${name_base}-dev and ${name_base}-main"
