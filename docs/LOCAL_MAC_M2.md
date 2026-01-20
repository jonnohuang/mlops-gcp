# MLOps on GCP (mlops-gcp) — Portfolio-First Monorepo

This repository is a **portfolio-first MLOps monorepo on Google Cloud**, created by completing and **refactoring a course-based MLOps curriculum into reproducible, deployable, production-minded projects**.

Rather than treating the course as the end goal, I use it as raw material to:
- modernize legacy labs
- introduce proper CI/CD separation (PR vs deploy)
- apply Cloud Run and Artifact Registry best practices
- build projects suitable for **ML infrastructure and platform engineering roles**

---

## 🎯 Target roles

- **Google Cloud ML Infrastructure Engineer**
- **Machine Learning Engineer (Platform / Serving / Pipelines)**

---

## 🔑 What this repository demonstrates

- Cloud Run model serving
- CI/CD with Cloud Build (PR checks + branch-based deployment)
- Artifact Registry image management
- Progressive refactoring from *course lab* → *portfolio-quality service*
- Local reproducibility on **macOS Apple Silicon (M2)** using conda + Docker
- End-to-end ML lifecycle awareness (training → serving → orchestration)

---

## ⭐ Featured portfolio projects

### Coupon Recommendation ML Service — Portfolio version
**Path:**  
`Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations-v2/`

Highlights:
- production-style structure (`src/`, `tests/`, `scripts`, config)
- health endpoints (`/healthz`, `/readyz`)
- Cloud Build build → push → deploy pipeline
- local conda + local Docker workflow
- deployable on GCP Cloud Run

### Coupon Recommendation — Course reference + CI/CD split
**Path:**  
`Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations/`

Kept intentionally for learning fidelity and to show evolution.  
Includes:
- `cloudbuild.pr.yaml` — CI only (tests / build, no deploy)
- `cloudbuild.deploy.yaml` — CD (build / push / deploy)

---

## 🗂 Repository layout (high level)

- `Section3-CloudBuild-CICD/` — Cloud Run, Cloud Build, and model serving labs (most portfolio-relevant)
- `Section4-ContinuousTraining-Airflow-Composer/` — continuous training & orchestration (Airflow / Composer)
- `Section5-7-VertexAI-Development/` — Vertex AI training, batch prediction, explainability
- `Section6-Kubeflow-Pipelines/` — experiments and pipeline examples
- `Section7-Feature-Store/` — Feature Store examples
- `Section8-GenAI/` — GenAI labs (supplementary)
- `docs/` — setup, workflows, and CI/CD strategy
- `scripts/` — reusable helpers for IAM, deployment, and triggers
- `archive/` — preserved pre-modernization snapshots

---

## 🔁 Portfolio-first workflow (high level)

- `dev` — course work, refactors, experiments, frequent GCP deploys
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
- CI/CD triggers strategy: `docs/TRIGGERS_DEV_MAIN.md`

---

## ⚠️ Disclaimer

This repository builds on publicly available course material for educational purposes.
Refactored implementations reflect independent engineering decisions and modernization work.
