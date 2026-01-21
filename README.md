# MLOps on Google Cloud — Portfolio-First Monorepo

This repository is a **portfolio-first MLOps monorepo on Google Cloud**, created by completing and then **modernizing a full MLOps course curriculum into production-minded projects**.

Rather than treating the course as the end goal, I use it as raw material to:
- modernize legacy labs for current GCP defaults
- introduce proper CI/CD separation (PR validation vs environment deployment)
- apply Cloud Run and Artifact Registry best practices
- curate selected labs into **ML infrastructure–quality portfolio projects**

---

## 🎯 Target roles

- **Google Cloud ML Infrastructure Engineer**
- **Machine Learning Engineer (Platform / Serving / Pipelines)**

---

## 🔑 What this repository demonstrates

- Cloud Run model serving
- CI/CD with Cloud Build (PR validation + branch-based deployment)
- Artifact Registry image management
- Progressive refactoring from *course lab* → *portfolio-quality service*
- Local reproducibility on macOS Apple Silicon (M2) using conda + Docker
- End-to-end ML lifecycle awareness (training → serving → orchestration)

Emphasis is placed on **deployability, reproducibility, and operational correctness**, not just model accuracy.

---

## ⭐ Start here (featured portfolio projects)

### Coupon Recommendation ML Service — **Primary portfolio artifact**
**Path:**  
`Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations-v2/`

Highlights:
- production-style structure (`src/`, `tests/`, `scripts`, configuration)
- health endpoints for Cloud Run
- Cloud Build build → push → deploy pipeline
- continuously deployable to Google Cloud Run

### Coupon Recommendation — Course reference + CI/CD split
**Path:**  
`Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations/`

Kept intentionally for learning fidelity and to show evolution.
Includes separate CI and CD configurations:
- `cloudbuild.pr.yaml` — build and test only
- `cloudbuild.deploy.yaml` — build, push, and deploy

---

## 🗂 Repository layout (high level)

- `Section3-CloudBuild-CICD/` — Cloud Run, Cloud Build, and ML model serving (most portfolio-relevant)
- `Section4-ContinuousTraining-Airflow-Composer/` — continuous training and orchestration
- `Section5-7-VertexAI-Development/` — Vertex AI training, batch prediction, explainability
- `Section6-Kubeflow-Pipelines/` — experiments and pipelines
- `Section7-Feature-Store/` — feature store examples
- `Section8-GenAI/` — supplementary GenAI labs
- `docs/` — setup, workflows, and CI/CD strategy
- `scripts/` — reusable infrastructure helpers
- `archive/` — preserved pre-modernization snapshots

---

## 🔁 Portfolio-first workflow (high level)

- `dev` — course work, refactors, experiments, frequent deployments
- `main` — curated, stable, portfolio-ready implementations only

CI/CD is structured to support:
- PR validation (build + test only)
- branch-based deployment for `dev` and `main`

---

## 📄 Documentation

Detailed setup and workflows are documented separately:

- GCP project & IAM setup: `docs/SETUP_GCP.md`
- Local development (macOS M2): `docs/LOCAL_MAC_M2.md`
- Progressive lab workflow: `docs/PROGRESSIVE_LABS.md`
- CI/CD trigger strategy: `docs/TRIGGERS_DEV_MAIN.md`

---

## ⚠️ Disclaimer

This repository builds on publicly available course material for educational purposes.
Refactored implementations reflect independent engineering decisions and modernization work.
