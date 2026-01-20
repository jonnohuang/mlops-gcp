# Cloud Build triggers: dev vs main

If `main` is portfolio-first, you should avoid deploying experimental work to production services.

## Recommended setup

Create **two triggers**:

### 1) main trigger (production)
- Branch regex: `^main$`
- Deploys to service name: `<service>`

### 2) dev trigger (staging)
- Branch regex: `^dev$`
- Deploys to service name: `<service>-dev`

You can do this by:
- duplicating the trigger in Cloud Build, and
- setting substitutions (e.g. `_SERVICE`) differently per trigger.

## Why this works
- You can push freely to `dev` and validate on GCP
- Only merge to `main` when it’s clean
- `main` deployments stay stable for portfolio demos
