#!/usr/bin/env bash
set -euo pipefail

export PORT=${PORT:-8080}
export MODEL_URI=${MODEL_URI:-artifacts/xgboost_coupon_recommendation.pkl}

python -m coupon_reco.main
