# Coupon Recommendations (Cloud Run) — CI/CD with Cloud Build

A simple **coupon recommendation** ML inference API deployed to **Google Cloud Run**, with **CI/CD using Cloud Build**.

This repo is organized to keep **inference code** clean (`src/`), while keeping **training** and data separate (`training/`).

---

## Architecture

**GitHub → Cloud Build trigger → build image → push to Artifact Registry → deploy to Cloud Run**

- Cloud Run sends traffic to your container on the `$PORT` environment variable (default `8080`).
- The service loads a pickled XGBoost model from:
  - a local file inside the container (demo/default), or
  - **GCS** via `MODEL_URI=gs://...` (production-style).

---

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/healthz` | liveness |
| GET | `/readyz` | readiness (verifies model can load) |
| POST | `/predict` | return coupon acceptance prediction |

### Example request

```bash
curl -X POST "$SERVICE_URL/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "destination": "No Urgent Place",
    "passanger": "Kid(s)",
    "weather": "Sunny",
    "temperature": 80,
    "time": "10AM",
    "coupon": "Bar",
    "expiration": "1d",
    "gender": "Female",
    "age": "21",
    "maritalStatus": "Unmarried partner",
    "has_children": 1,
    "education": "Some college - no degree",
    "occupation": "Unemployed",
    "income": "$37500 - $49999",
    "Bar": "never",
    "CoffeeHouse": "never",
    "CarryAway": "4~8",
    "RestaurantLessThan20": "4~8",
    "Restaurant20To50": "1~3",
    "toCoupon_GEQ15min": 1,
    "toCoupon_GEQ25min": 0,
    "direction_same": 0
  }'
```

---

## Local development

### 1) Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
```

### 2) Run locally

```bash
export MODEL_URI=artifacts/xgboost_coupon_recommendation.pkl
python -m coupon_reco.main
```

Service: `http://localhost:8080`

### 3) Smoke test

```bash
SERVICE_URL=http://localhost:8080 ./scripts/smoke_test.sh
```

### 4) Run tests

```bash
python -m pytest -q
```

---

## Docker

```bash
docker build -t coupon-reco:local .
docker run --rm -p 8080:8080 -e PORT=8080 -e MODEL_URI=artifacts/xgboost_coupon_recommendation.pkl coupon-reco:local
SERVICE_URL=http://localhost:8080 ./scripts/smoke_test.sh
```

---

## CI/CD with Cloud Build

`cloudbuild.yaml` does:
1. install deps + run tests
2. build container image
3. push to **Artifact Registry**
4. deploy to **Cloud Run**

### Substitutions

In `cloudbuild.yaml`:
- `_REGION` (default: `us-central1`)
- `_SERVICE` (default: `coupon-recommendations`)
- `_AR_REPO` (default: `ml-services`)
- `_MODEL_URI` (default: `artifacts/xgboost_coupon_recommendation.pkl`)

The image path is:

```
${_REGION}-docker.pkg.dev/$PROJECT_ID/${_AR_REPO}/${_SERVICE}:${SHORT_SHA}
```

### Production model loading (recommended)

Upload your model to GCS and deploy with:

```
MODEL_URI=gs://YOUR_BUCKET/path/to/xgboost_coupon_recommendation.pkl
```

Make sure your Cloud Run service account has permissions to read that object.

---

## Repo structure

```
.
├─ src/coupon_reco/          # inference service code
├─ artifacts/               # demo model artifact (avoid committing large artifacts in real projects)
├─ training/                # notebook + training data
├─ tests/                   # unit tests
├─ scripts/                 # local run + smoke tests
├─ Dockerfile
├─ cloudbuild.yaml
└─ requirements*.txt
```

---

## Notes / recommended next steps

- Move model artifacts fully to GCS or Vertex Model Registry
- Add request validation (e.g., pydantic via FastAPI)
- Add structured logging + metrics
- Split CI and CD into separate Cloud Build triggers
