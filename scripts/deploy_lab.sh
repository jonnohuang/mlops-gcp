#!/usr/bin/env bash
set -euo pipefail

# Deploy any lab folder via Cloud Build
# Usage:
#   bash scripts/deploy_lab.sh <relative/path/to/lab>

LAB_DIR="${1:-}"
if [[ -z "$LAB_DIR" ]]; then
  echo "Usage: bash scripts/deploy_lab.sh <relative/path/to/lab>"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/env.common.sh"

LAB_PATH="$ROOT_DIR/$LAB_DIR"
if [[ ! -d "$LAB_PATH" ]]; then
  echo "Lab folder not found: $LAB_PATH"
  exit 1
fi

gcloud config set project "$PROJECT_ID"

echo "Submitting Cloud Build for: $LAB_DIR"
gcloud builds submit --region "$REGION" "$LAB_PATH"
