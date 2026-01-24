#!/usr/bin/env bash
set -euo pipefail

# Manual smoke test after deploy.
# Verifies: Root (/), Health (/healthz), and ML Inference (/predict)

PROJECT_ID="${PROJECT_ID:-ml-ops-on-gcp}"
REGION="${REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-coupon-recommendations-dev}"

gcloud config set project "$PROJECT_ID" >/dev/null

echo "Fetching Cloud Run URL..."
URL="$(gcloud run services describe "$SERVICE_NAME" \
  --region "$REGION" \
  --format='value(status.url)')"

if [[ -z "$URL" ]]; then
  echo "ERROR: Could not find Cloud Run URL for service: $SERVICE_NAME"
  exit 1
fi

echo "---"
echo "Target URL: $URL"
echo "---"

echo "1. Testing Root Endpoint (No more 404)..."
curl -sS -X GET "${URL}/readyz" | python -m json.tool

echo -e "\n2. Testing Health Check..."
curl -sS -X GET "${URL}/healthz" | python -m json.tool

echo -e "\n3. Testing ML Inference (/predict)..."
curl -sS -X POST "${URL}/predict" \
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
  }' | python -m json.tool