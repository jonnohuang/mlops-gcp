# Progressive lab workflow

This repo is structured so each lab follows the same 3-stage schedule:

1) **Local training** (ML labs only)  
2) **Local serving + tests**  
3) **GCP deploy via Cloud Build** (manual or trigger)

## 0. One-time setup

```bash
bash scripts/bootstrap_iam.sh
```

## 1. Local training (ML labs)
- Run the notebook/script in the lab
- Generate artifacts (course style) or write artifacts to GCS (portfolio style)

## 2. Local serving + local tests

```bash
export PORT=8080
python main.py
curl http://localhost:8080/healthz
```

Then docker:

```bash
docker build -t local:test .
docker run --rm -p 8080:8080 -e PORT=8080 local:test
```

## 3. GCP deploy (manual)
From repo root:

```bash
bash scripts/deploy_lab.sh <relative/lab/folder>
```

Example:

```bash
bash scripts/deploy_lab.sh Section3-CloudBuild-CICD/cloudrun-ml-models/coupon-recommendations
```
