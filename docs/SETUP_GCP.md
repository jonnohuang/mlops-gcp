GCP SETUP GUIDE (ONE-TIME)

This document covers the one-time Google Cloud setup to run and deploy labs in this repository.
It supports Cloud Run, Cloud Build (CI/CD), Artifact Registry, and optional Vertex AI / Composer labs.

================================================================
FAST PATH (MOST USERS)

Run the following from the repo root:

source env.common.sh
gcloud config set project "$PROJECT_ID"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com iam.googleapis.com
bash scripts/bootstrap_iam.sh
gcloud auth configure-docker "${REGION}-docker.pkg.dev"

If you will run Vertex AI labs later:

gcloud services enable aiplatform.googleapis.com

If you will run Composer labs:

gcloud services enable composer.googleapis.com

================================================================
COMMON PROJECT CONFIGURATION

All labs assume the following values defined in env.common.sh:

PROJECT_ID="ml-ops-on-gcp"
PROJECT_NUMBER="79824532858"
REGION="us-central1"

CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
"

================================================================
LOCAL PREREQUISITES (macOS)

Required tools:

Google Cloud CLI (gcloud)

Docker Desktop

Git

Verify installations:

gcloud version
docker version
git --version

================================================================
AUTHENTICATE WITH GCP

Login:

gcloud auth login

Set application default credentials (for local runs):

gcloud auth application-default login

Set default project and region:

gcloud config set project "$PROJECT_ID"
gcloud config set run/region "$REGION"

================================================================
ENABLE REQUIRED APIS

Required for Section 3 (Cloud Run + Cloud Build):

gcloud services enable
run.googleapis.com
cloudbuild.googleapis.com
artifactregistry.googleapis.com
iam.googleapis.com

Optional APIs:

gcloud services enable aiplatform.googleapis.com (Vertex AI, Section 5–7)
gcloud services enable composer.googleapis.com (Composer, Section 4)

================================================================
IAM BOOTSTRAP (RECOMMENDED)

All IAM bindings are centralized in one script:

scripts/bootstrap_iam.sh

Run once per project:

bash scripts/bootstrap_iam.sh

Notes:

Older labs may include gcloud-permission-commands.sh files.

In this repo, those scripts are wrappers that delegate to bootstrap_iam.sh.

================================================================
ARTIFACT REGISTRY SETUP

Create the Artifact Registry repository if it does not exist
(example repository name: python-apps):

gcloud artifacts repositories create python-apps
--repository-format=docker
--location="$REGION"
--description="Docker images for Cloud Run ML services" || true

Configure Docker authentication:

gcloud auth configure-docker "${REGION}-docker.pkg.dev"

================================================================
VERIFY SETUP

Manual deploy test (example):

bash scripts/deploy_lab.sh Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations-v2

List Cloud Run services:

gcloud run services list --region "$REGION"

================================================================
TROUBLESHOOTING

If you encounter permission or deployment errors:

Confirm the active project:
gcloud config set project "$PROJECT_ID"

Re-run IAM bootstrap:
bash scripts/bootstrap_iam.sh

For Apple Silicon Docker issues:
See docs/LOCAL_MAC_M2.md

================================================================
SUMMARY

After completing this setup, you should be able to:

Run services locally

Build and test Docker images

Deploy via Cloud Build

Maintain dev vs main deployments safely

This setup reflects real-world MLOps infrastructure rather than course-only demos.