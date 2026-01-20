# Local development on Mac (Apple Silicon / M1/M2)

## Conda environment
Use a per-project env when possible. For the course, a shared env is fine.

```bash
conda create -n mlops-gcp python=3.11 -y
conda activate mlops-gcp
pip install -U pip
```

If a lab folder has `requirements.txt`:

```bash
pip install -r requirements.txt
```

## Running Flask locally
Cloud Run expects the app to listen on `$PORT` (default 8080). All updated labs default to **8080**.

```bash
export PORT=8080
python main.py
curl http://localhost:8080/healthz
```

## Docker builds on Apple Silicon
Cloud Run runs on Linux x86_64 in most setups. If you hit native-arch issues, build **linux/amd64** locally:

```bash
docker buildx create --use >/dev/null 2>&1 || true
docker buildx build --platform linux/amd64 -t local:test --load .
docker run --rm -p 8080:8080 -e PORT=8080 local:test
```

If your image is pure-Python, multi-arch usually works fine.
