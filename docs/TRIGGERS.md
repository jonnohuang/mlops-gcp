# Cloud Build triggers for dev vs main

Goal:
- `dev` branch = course work + experiments, deploys to **staging/dev** services
- `main` branch = portfolio-first, deploys to **prod** services

## Recommended setup: two triggers per lab

### Trigger A (dev)
- Branch regex: `^dev$`
- Uses the same `cloudbuild.yaml`
- Overrides substitutions:
  - `_SERVICE`: `<service-name>-dev`
  - `_IMAGE`: `<image-name>-dev` (optional)

### Trigger B (main)
- Branch regex: `^main$`
- Substitutions:
  - `_SERVICE`: `<service-name>`
  - `_IMAGE`: `<image-name>`

This keeps your portfolio (`main`) clean while still letting you push `dev` and validate on GCP.

## Alternative: keep trigger only on main
If you don't want extra services, keep triggers on `main` only and test `dev` using manual builds:

```bash
bash scripts/deploy_lab.sh <lab>
```

That approach is simple and avoids staging environments, but it's slower.
