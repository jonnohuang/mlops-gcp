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
# ==============================================================================

# 1. Automatically load project variables from env.common.sh
source "$(dirname "$0")/../env.common.sh"

# 2. Parse key=value args from command line
for arg in "$@"; do
  case "$arg" in
    *=*) export "${arg}" ;;
  esac
done

# 3. Validate required arguments
: "${name_base:?missing name_base}"
: "${lab_dir:?missing lab_dir}"
: "${service:?missing service}"
: "${ar_repo:?missing ar_repo}"
: "${image:?missing image}"

pr_target="${pr_target:-main}"

# 4. Construct 2nd Gen Resource Paths (Logic Layer)
REPO_RESOURCE="projects/$PROJECT_ID/locations/$REGION/connections/$CONNECTION_NAME/repositories/$REPO_NAME"

# FIX: For 2nd Gen, we use the Compute Engine Default SA in FULL RESOURCE FORMAT
CB_SA_EMAIL="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
CB_SA_RESOURCE="projects/${PROJECT_ID}/serviceAccounts/${CB_SA_EMAIL}"

gcloud config set project "$PROJECT_ID" >/dev/null

DEPLOY_YAML="$lab_dir/cloudbuild.deploy.yaml"
PR_YAML="$lab_dir/cloudbuild.pr.yaml"

# Shared substitutions
COMMON_SUBS="_REGION=${REGION},_AR_REPO=${ar_repo},_IMAGE=${image}"

delete_trigger_if_exists() {
  local trig_name="$1"
  # 2nd Gen triggers are regional
  if gcloud builds triggers describe "$trig_name" --region="$REGION" &>/dev/null; then
    echo "Deleting existing trigger '$trig_name'..."
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
    --build-config="$DEPLOY_YAML" \
    --service-account="$CB_SA_RESOURCE" \
    --substitutions="${COMMON_SUBS},_SERVICE=${svc},_RUNTIME_SA=${RUNTIME_SA},_MODEL_GCS_BUCKET=${MODEL_GCS_BUCKET},_MODEL_GCS_BLOB=${MODEL_GCS_BLOB}"
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
    --service-account="$CB_SA_RESOURCE" \
    --substitutions="_MODEL_GCS_BUCKET=${MODEL_GCS_BUCKET},_MODEL_GCS_BLOB=${MODEL_GCS_BLOB}"
}

# 5. Run the creation process
create_pr_trigger "${name_base}-pr"
create_push_trigger "${name_base}-dev" "^dev$" "${service}-dev"
create_push_trigger "${name_base}-main" "^main$" "${service}"

echo "Successfully configured 2nd Gen triggers for $REPO_NAME in $REGION."