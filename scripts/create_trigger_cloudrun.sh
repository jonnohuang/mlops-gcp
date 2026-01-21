#!/usr/bin/env bash
set -euo pipefail

# Create Cloud Build triggers for a Cloud Run lab:
#  - dev  (push to dev -> deploys <service>-dev)
#  - main (push to main -> deploys <service>)
#  - pr   (optional PR checks, if cloudbuild.pr.yaml exists)
#
# Example:
#   ./scripts/create_trigger_cloudrun.sh \
#     name_base=coupon-reco \
#     repo_owner=jonnohuang \
#     repo_name=mlops-gcp \
#     lab_dir=Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations \
#     service=coupon-recommendations \
#     ar_repo=python-apps \
#     image=coupon-reco
#
# Notes:
# - Uses <lab_dir>/cloudbuild.deploy.yaml if present, else falls back to <lab_dir>/cloudbuild.yaml
# - Uses <lab_dir>/cloudbuild.pr.yaml for PR trigger if present
# - For regional triggers, --service-account must be a full resource name:
#   projects/$PROJECT_ID/serviceAccounts/$SA_EMAIL

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
: "${lab_dir:?missing lab_dir}"
: "${service:?missing service}"
: "${ar_repo:?missing ar_repo}"
: "${image:?missing image}"

gcloud config set project "$PROJECT_ID"

DEPLOY_YAML="$lab_dir/cloudbuild.deploy.yaml"
PR_YAML="$lab_dir/cloudbuild.pr.yaml"
FALLBACK_YAML="$lab_dir/cloudbuild.yaml"

if [[ -f "$DEPLOY_YAML" ]]; then
  build_yaml="$DEPLOY_YAML"
elif [[ -f "$FALLBACK_YAML" ]]; then
  build_yaml="$FALLBACK_YAML"
else
  echo "ERROR: No cloudbuild yaml found in $lab_dir (expected cloudbuild.deploy.yaml or cloudbuild.yaml)"
  exit 1
fi

SA_RESOURCE="${CLOUDBUILD_SA_RESOURCE}"

# Some labs may not use _RUNTIME_SA; only pass it if the build YAML mentions it.
COMMON_SUBS="_REGION=${REGION},_AR_REPO=${ar_repo},_IMAGE=${image}"
if grep -q "_RUNTIME_SA" "$build_yaml"; then
  COMMON_SUBS="${COMMON_SUBS},_RUNTIME_SA=${RUNTIME_SA}"
fi

create_push_trigger() {
  local trig_name="$1"
  local branch_regex="$2"
  local svc="$3"

  gcloud builds triggers create github \
    --name="$trig_name" \
    --repo-owner="$repo_owner" \
    --repo-name="$repo_name" \
    --branch-pattern="$branch_regex" \
    --build-config="$build_yaml" \
    --service-account="$SA_RESOURCE" \
    --substitutions="${COMMON_SUBS},_SERVICE=${svc}" \
    --region="$REGION"
}

create_pr_trigger() {
  local trig_name="$1"
  gcloud builds triggers create github \
    --name="$trig_name" \
    --repo-owner="$repo_owner" \
    --repo-name="$repo_name" \
    --pull-request-pattern="^main$" \
    --build-config="$PR_YAML" \
    --service-account="$SA_RESOURCE" \
    --region="$REGION"
}

# Optional PR trigger
if [[ -f "$PR_YAML" ]]; then
  set +e
  create_pr_trigger "${name_base}-pr"
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    echo "Created PR trigger: ${name_base}-pr (config: $PR_YAML)"
  else
    echo "WARNING: PR trigger creation failed (skipping). Use a dev CI trigger instead."
  fi
else
  echo "PR config not found, skipping PR trigger: $PR_YAML"
fi

# Push triggers
create_push_trigger "${name_base}-dev" "^dev$" "${service}-dev"
create_push_trigger "${name_base}-main" "^main$" "${service}"

echo "Created triggers:"
echo " - ${name_base}-dev  (dev -> ${service}-dev) using $build_yaml"
echo " - ${name_base}-main (main -> ${service}) using $build_yaml"
