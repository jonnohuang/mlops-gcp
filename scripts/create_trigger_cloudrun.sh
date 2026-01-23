#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# FULL EXECUTION EXAMPLE:
#
# ./scripts/create_trigger_cloudrun.sh \
#   name_base=coupon-reco \
#   lab_dir=Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations \
#   service=coupon-recommendations \
#   ar_repo=python-apps \
#   image=coupon-reco
#
# Note: REPO_NAME and CONNECTION_NAME are pulled from env.common.sh
# ==============================================================================

source "$(dirname "$0")/../env.common.sh"

# Parse key=value args
for arg in "$@"; do
  case "$arg" in
    *=*) export "${arg}" ;;
    *) echo "Invalid arg: $arg (expected key=value)"; exit 1 ;;
  esac
done

# Validation
: "${name_base:?missing name_base}"
: "${lab_dir:?missing lab_dir}"
: "${service:?missing service}"
: "${ar_repo:?missing ar_repo}"
: "${image:?missing image}"

pr_target="${pr_target:-main}"

# 2nd Gen Repository Resource Path
REPO_RESOURCE="projects/$PROJECT_ID/locations/$REGION/connections/$CONNECTION_NAME/repositories/$REPO_NAME"

gcloud config set project "$PROJECT_ID" >/dev/null

DEPLOY_YAML="$lab_dir/cloudbuild.deploy.yaml"
PR_YAML="$lab_dir/cloudbuild.pr.yaml"
FALLBACK_YAML="$lab_dir/cloudbuild.yaml"

# Determine which build config to use
if [[ -f "$DEPLOY_YAML" ]]; then
  build_yaml="$DEPLOY_YAML"
elif [[ -f "$FALLBACK_YAML" ]]; then
  build_yaml="$FALLBACK_YAML"
else
  echo "ERROR: No cloudbuild yaml found in $lab_dir"
  exit 1
fi

COMMON_SUBS="_REGION=${REGION},_AR_REPO=${ar_repo},_IMAGE=${image}"

# Helper to delete existing regional trigger
delete_trigger_if_exists() {
  local trig_name="$1"
  if gcloud builds triggers describe "$trig_name" --region="$REGION" &>/dev/null; then
    echo "Deleting existing trigger '$trig_name' in $REGION..."
    gcloud builds triggers delete "$trig_name" --region="$REGION" --quiet
  fi
}

create_push_trigger() {
  local trig_name="$1"
  local branch_regex="$2"
  local svc="$3"

  delete_trigger_if_exists "$trig_name"

  echo "Creating Push Trigger: $trig_name (2nd Gen)"
  gcloud builds triggers create github \
    --name="$trig_name" \
    --region="$REGION" \
    --repository="$REPO_RESOURCE" \
    --branch-pattern="$branch_regex" \
    --build-config="$build_yaml" \
    --service-account="projects/$PROJECT_ID/serviceAccounts/$CLOUDBUILD_SA" \
    --substitutions="${COMMON_SUBS},_SERVICE=${svc}"
}

create_pr_trigger() {
  local trig_name="$1"
  if [[ ! -f "$PR_YAML" ]]; then return 0; fi

  delete_trigger_if_exists "$trig_name"

  echo "Creating PR Trigger: $trig_name (2nd Gen)"
  gcloud builds triggers create github \
    --name="$trig_name" \
    --region="$REGION" \
    --repository="$REPO_RESOURCE" \
    --pull-request-pattern="^${pr_target}$" \
    --build-config="$PR_YAML" \
    --service-account="projects/$PROJECT_ID/serviceAccounts/$CLOUDBUILD_SA" \
    --substitutions="_MODEL_GCS_BUCKET=${MODEL_GCS_BUCKET},_MODEL_GCS_BLOB=${MODEL_GCS_BLOB}"
}

# Execute creation
create_pr_trigger "${name_base}-pr"
create_push_trigger "${name_base}-dev" "^dev$" "${service}-dev"
create_push_trigger "${name_base}-main" "^main$" "${service}"

echo "Successfully configured 2nd Gen triggers for $REPO_NAME"