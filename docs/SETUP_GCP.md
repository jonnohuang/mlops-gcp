# GCP Project & IAM Setup

This document describes the one-time Google Cloud setup required to run the labs
and CI/CD pipelines in this repository.

Operational setup details are intentionally separated from the root README to keep
the repository portfolio-focused and reviewer-friendly.

============================================================
Required APIs
============================================================

Ensure the following APIs are enabled in the GCP project:

- Cloud Build
- Cloud Run
- Artifact Registry
- IAM

Optional (required only for specific sections or labs):

- Vertex AI
- Cloud Composer


============================================================
IAM Bootstrap (One-Time Setup)
============================================================

A helper script is provided to grant the minimum required IAM roles to the service
accounts used by Cloud Build and Cloud Run.

Run once per project:

    bash scripts/bootstrap_iam.sh

This script assigns permissions required for:

- building and pushing container images
- deploying Cloud Run services
- accessing Artifact Registry


============================================================
Common Project Configuration
============================================================

All labs in this repository assume the following base configuration, defined in
`env.common.sh`:

    PROJECT_ID="ml-ops-on-gcp"
    PROJECT_NUMBER="79824532858"
    REGION="us-central1"

    CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
    RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"


============================================================
Notes
============================================================

- IAM configuration is intentionally centralized to avoid repeating permissions
  across individual labs.
- Individual lab folders may include an `env.project.sh` file to define service
  names and Artifact Registry repositories.
- No additional manual IAM configuration is required after this step unless new
  GCP services are introduced.


============================================================
Troubleshooting
============================================================

If you encounter permission-related errors:

1. Confirm you are authenticated with the correct GCP account.
2. Verify the active project is set correctly:

       gcloud config set project ml-ops-on-gcp

3. Re-run the IAM bootstrap script:

       bash scripts/bootstrap_iam.sh
