# GCP SETUP GUIDE (ONE-TIME)

This document covers the one-time Google Cloud setup to run and deploy labs in this repository.
It supports Cloud Run, Cloud Build (CI/CD), Artifact Registry, and optional Vertex AI / Composer labs.

================================================================
FAST PATH (MOST USERS)
================================================================
Run the following from the repo root:

source env.common.sh
gcloud config set project "$PROJECT_ID"
gcloud services enable \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    iam.googleapis.com

bash scripts/bootstrap_iam.sh
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

# If running Vertex AI labs:
gcloud services enable aiplatform.googleapis.com

# If running Composer labs:
gcloud services enable composer.googleapis.com

================================================================
COMMON PROJECT CONFIGURATION
================================================================
All labs assume the following values defined in env.common.sh:

PROJECT_ID="ml-ops-on-gcp"
PROJECT_NUMBER="79824532858"
REGION="us-central1"

CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

================================================================
LOCAL PREREQUISITES (macOS)
================================================================
Required tools: Google Cloud CLI (gcloud), Docker Desktop, Git

Verify installations:
gcloud version && docker version && git --version

================================================================
AUTHENTICATE WITH GCP
================================================================
gcloud auth login
gcloud auth application-default login
gcloud config set project "$PROJECT_ID"
gcloud config set run/region "$REGION"

================================================================
IAM & ARTIFACT REGISTRY SETUP
================================================================
# Centralized IAM bootstrap
bash scripts/bootstrap_iam.sh

# Create Docker repository
gcloud artifacts repositories create python-apps \
    --repository-format=docker \
    --location="$REGION" \
    --description="Docker images for Cloud Run ML services" || true

# Configure Docker authentication
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

================================================================
VERIFY & TROUBLESHOOT
================================================================
# Test Deployment
bash scripts/deploy_lab.sh Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations-v2
gcloud run services list --region "$REGION"

# Troubleshooting
- Confirm project: gcloud config set project "$PROJECT_ID"
- Re-run IAM: bash scripts/bootstrap_iam.sh
- Apple Silicon: See docs/LOCAL_MAC_M2.md