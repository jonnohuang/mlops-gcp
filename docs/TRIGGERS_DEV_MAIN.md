# Cloud Build triggers for `dev` and `main`

Goal:
- `dev` branch deploys to **staging** services (e.g. `coupon-recommendations-dev`)
- `main` branch deploys to **portfolio/prod** services (e.g. `coupon-recommendations`)

## Why
If `main` is portfolio-first, you still want to push often during course work without
constantly redeploying your portfolio services.

## Recommended setup
Create **two triggers** per lab:

### Trigger A: dev → staging
- **Branch regex**: `^dev$`
- **Build config**: the lab's `cloudbuild.yaml`
- **Substitutions**:
  - `_SERVICE`: `...-dev` (staging service name)
  - `_AR_REPO`: per lab (e.g. `python-apps`)
  - `_IMAGE`: per lab (e.g. `coupon-reco`)

### Trigger B: main → prod
- **Branch regex**: `^main$`
- **Build config**: same `cloudbuild.yaml`
- **Substitutions**:
  - `_SERVICE`: prod service name

## Staging naming convention
Use a stable suffix:
- Cloud Run service: `<service>-dev`
- Image: same `_IMAGE` but different tag (Cloud Build tags by commit SHA)

## If you don't want a staging service
Skip the `dev` trigger and test from `dev` by running:

```bash
bash scripts/deploy_lab.sh <lab_folder>
```

This keeps `main` clean while still letting you test on GCP anytime.
