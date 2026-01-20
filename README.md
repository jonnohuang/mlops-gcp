# MLOps on GCP (mlops-gcp)

Course-driven implementation of an end-to-end MLOps workflow on Google Cloud Platform.

## Goals
- Build reproducible training + inference pipelines
- Containerize workloads with Docker
- Deploy to GCP services (e.g., Cloud Run / Vertex AI)
- CI/CD Using Cloud Build,Container and Artifact Registry
- Continuous Training using Airflow for ML Workflow Orchestration:
- Writing Test Cases
- Vertex AI Ecosystem using Python
- Kubeflow Pipelines for ML Workflow and reusable ML components
- Deploy Useful Applications using PaLM LLM of GCP Generative AI 

## How to Run (Local)
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## Portfolio-first workflow (recommended)

- `main`: portfolio-ready, stable, deployable
- `dev`: course work in progress

### Common GCP config
See `env.common.sh`.

### One-time IAM bootstrap
```bash
bash scripts/bootstrap_iam.sh
```

### Deploy any lab manually (works from dev)
```bash
bash scripts/deploy_lab.sh Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations
```

### Triggers for dev vs main
See `docs/TRIGGERS_DEV_MAIN.md` and `scripts/create_trigger_cloudrun.sh`.