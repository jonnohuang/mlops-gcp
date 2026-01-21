# Cloud Build CI/CD: Multi-Branch Deployment Strategy

## Goal
Establish a robust automated deployment pipeline that separates development iterations from stable portfolio demonstrations.

* **`dev` branch**: Deploys to **staging services** (e.g., `coupon-recommendations-dev`).
* **`main` branch**: Deploys to **portfolio/stable services** (e.g., `coupon-recommendations`).



---

## Why This Setup?
When treating the `main` branch as **portfolio-first**, this workflow ensures:
* **Frequent Iteration:** Push often while learning without breaking stable endpoints.
* **Stability:** Experiments do not automatically redeploy production services.
* **Professional Storytelling:** Demonstrates a clear ML Ops narrative: `dev` for iteration and `main` for stable, production-ready systems.

---

## Recommended Setup (Per Lab)
Create two Cloud Build triggers for each Cloud Run lab.

### Trigger A: dev → staging
* **Branch Regex:** `^dev$`
* **Build Config:** Prefer `cloudbuild.deploy.yaml`; fallback to `cloudbuild.yaml`.
* **Deploys to:** `<service>-dev`
* **Substitutions:**
    * `_SERVICE`: `<service>-dev`
    * `_AR_REPO`: Per lab (e.g., `python-apps`)
    * `_IMAGE`: Per lab (e.g., `coupon-reco`)
    * `_REGION`: `us-central1`
    * `_RUNTIME_SA`: (Optional) Only if required by the lab’s deploy config.

### Trigger B: main → portfolio/prod
* **Branch Regex:** `^main$`
* **Build Config:** Same as `dev`.
* **Deploys to:** `<service>`
* **Substitutions:**
    * `_SERVICE`: `<service>`

---

## Important: Service Account Format
All triggers in this repository are **regional** (`us-central1`). For regional Cloud Build GitHub triggers, you **must** specify the service account as a full resource name.

> **Note:** Using only the email address may cause trigger creation to fail with an `INVALID_ARGUMENT` error.

**Correct Format:**
`projects/$PROJECT_ID/serviceAccounts/$SA_EMAIL`

**Example:**
`projects/ml-ops-on-gcp/serviceAccounts/79824532858-compute@developer.gserviceaccount.com`

---

## Recommended: Use the Helper Script
You can automate the creation of both triggers by running the following command from the repository root:

```bash
./scripts/create_trigger_cloudrun.sh \
  name_base=coupon-reco \
  repo_owner=jonnohuang \
  repo_name=mlops-gcp \
  lab_dir=Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations \
  service=coupon-recommendations \
  ar_repo=python-apps \
  image=coupon-reco
```

**This script creates:**
1.  **`coupon-reco-dev`**: Watches `dev`, deploys to `coupon-recommendations-dev`.
2.  **`coupon-reco-main`**: Watches `main`, deploys to `coupon-recommendations`.

*Note: If `cloudbuild.pr.yaml` exists, the script will attempt to create a PR trigger but will skip safely if regional/GitHub constraints cause a failure.*

---

## Staging Naming Convention
To maintain consistency across labs, use the following suffix logic:
* **Cloud Run service:** `<service>-dev`
* **Artifact Registry image:** Keep the same `_IMAGE` name, but distinguish by commit SHA tags.

### Listing Regional Triggers
To verify your setup, use the following gcloud command:
```bash
gcloud builds triggers list \
  --region us-central1 \
  --format="table(name,filename,serviceAccount)"
```

---

## Promotion Rule of Thumb
### Safe to Merge to `main`
* Tooling, scripts, documentation, and general repository hygiene.

### Merge Lab/Model Code to `main` ONLY after:
1.  **Local Run:** Code executes successfully in your local environment.
2.  **Docker Build:** The image builds without errors.
3.  **Dev Deployment:** The staging service (`<service>-dev`) responds correctly to requests.