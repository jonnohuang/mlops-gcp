#!/usr/bin/env bash
set -euo pipefail

# Convenience notes / commands for local Mac (Apple Silicon) development.
#
# 1) Conda env (recommended for course):
#   conda create -n mlops-gcp python=3.11 -y
#   conda activate mlops-gcp
#   pip install -r requirements.txt
#
# 2) Docker parity with Cloud Run (amd64):
#   docker buildx create --use --name multiarch || true
#   docker buildx build --platform linux/amd64 -t local:test . --load
#   docker run --rm -p 8080:8080 -e PORT=8080 local:test
#
# If you do NOT need strict parity, plain docker build works too:
#   docker build -t local:test .
