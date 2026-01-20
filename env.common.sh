#!/usr/bin/env bash
set -euo pipefail

export PROJECT_ID="ml-ops-on-gcp"
export PROJECT_NUMBER="79824532858"
export REGION="us-central1"

export CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
export RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
