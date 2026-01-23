#!/usr/bin/env bash
set -euo pipefail

# Create Cloud Build triggers for a Cloud Run lab:
#  - dev  (push to dev  -> deploys <service>-dev)
#  - main (push to main -> deploys <service>)
#  - pr   (PR checks, targets main by default)
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
# Optional:
#   pr_target=main   (default: main)

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

# default PR target branch
pr_target="${pr_target:-main}"

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

# Build substitutions dynamically depending on what's referenced in the yaml.
COMMON_SUBS="_REGION=${REGION},_AR_REPO=${ar_repo},_IMAGE=${image}"

if grep -q "_RUNTIME_SA" "$build_yaml"; then
  COMMON_SUBS="${COMMON_SUBS},_RUNTIME_SA=${RUNTIME_SA}"
fi

if grep -q "_MODEL_GCS_BUCKET" "$build_yaml"; then
  COMMON_SUBS="${COMMON_SUBS},_MODEL_GCS_BUCKET=${MODEL_GCS_BUCKET}"
fi
if grep -q "_MODEL_GCS_BLOB" "$build_yaml"; then
  COMMON_SUBS="${COMMON_SUBS},_MODEL_GCS_BLOB=${MODEL_GCS_BLOB}"
fi

delete_trigger_if_exists() {
  local trig_name="$1"
  local trig_id
  trig_id="$(gcloud builds triggers list --region="$REGION" --format="value(id,name)" \
    | awk -v n="$trig_name" '$2==n {print $1}' || true)"
  if [[ -n "${trig_id}" ]]; then
    echo "Deleting existing trigger '$trig_name' (id=$trig_id) ..."
    gcloud builds triggers delete "$trig_id" --region="$REGION" --quiet
  fi
}

create_push_trigger() {
  local trig_name="$1"
  local branch_regex="$2"
  local svc="$3"

  delete_trigger_if_exists "$trig_name"

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

  if [[ ! -f "$PR_YAML" ]]; then
    echo "PR config not found, skipping PR trigger: $PR_YAML"
    return 0
  fi

  delete_trigger_if_exists "$trig_name"

  # PR yaml may also reference model vars; pass them if it does.
  local PR_SUBS=""
  if grep -q "_MODEL_GCS_BUCKET" "$PR_YAML"; then
    PR_SUBS="${PR_SUBS},_MODEL_GCS_BUCKET=${MODEL_GCS_BUCKET}"
  fi
  if grep -q "_MODEL_GCS_BLOB" "$PR_YAML"; then
    PR_SUBS="${PR_SUBS},_MODEL_GCS_BLOB=${MODEL_GCS_BLOB}"
  fi
  PR_SUBS="${PR_SUBS#,}"  # strip leading comma

  if [[ -n "$PR_SUBS" ]]; then
    gcloud builds triggers create github \
      --name="$trig_name" \
      --repo-owner="$repo_owner" \
      --repo-name="$repo_name" \
      --pull-request-pattern="^${pr_target}$" \
      --build-config="$PR_YAML" \
      --service-account="$SA_RESOURCE" \
      --substitutions="$PR_SUBS" \
      --region="$REGION"
  else
    gcloud builds triggers create github \
      --name="$trig_name" \
      --repo-owner="$repo_owner" \
      --repo-name="$repo_name" \
      --pull-request-pattern="^${pr_target}$" \
      --build-config="$PR_YAML" \
      --service-account="$SA_RESOURCE" \
      --region="$REGION"
  fi
}

# Create PR trigger (PRs into main by default)
create_pr_trigger "${name_base}-pr"

# Create push triggers
create_push_trigger "${name_base}-dev" "^dev$" "${service}-dev"
create_push_trigger "${name_base}-main" "^main$" "${service}"

echo "Created triggers:"
echo " - ${name_base}-pr   (PR -> ${pr_target})        using $PR_YAML"
echo " - ${name_base}-dev  (dev -> ${service}-dev)     using $build_yaml"
echo " - ${name_base}-main (main -> ${service})        using $build_yaml"
