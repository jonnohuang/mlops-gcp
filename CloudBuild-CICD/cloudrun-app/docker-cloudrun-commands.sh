# Step-1
# docker build -t demo-flask-app .

# # Push to Container Registry 
# docker tag demo-flask-app gcr.io/ml-ops-on-gcp/demo-flask-app
# docker push gcr.io/ml-ops-on-gcp/demo-flask-app

# Step-0 Authenticate Login to GCP
gcloud auth login
gcloud config set project ml-ops-on-gcp
# Google Container Registry (depreicated)
gcloud auth configure-docker gcr.io --quiet
# Artifact Registry (Current/Recommended)
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet


gcloud auth login
gcloud config set project ml-ops-on-gcp
gcloud config set account jonnohuang2025@gmail.com



# For MacOS M1/M2 arm64 cross-arch: buildx, tag, push
docker buildx build \
  --platform linux/amd64 \
  -t gcr.io/ml-ops-on-gcp/demo-flask-app:latest \
  --push \
  .

# gcloud run deploy demo-flask-app --image gcr.io/ml-ops-on-gcp/demo-flask-app --region us-central1

# Deploy to GCR
gcloud run deploy demo-flask-app \
  --image gcr.io/ml-ops-on-gcp/demo-flask-app:latest \
  --region us-central1 \
  --allow-unauthenticated

# Push to Artifact Registry 
# docker tag demo-flask-app us-central1-docker.pkg.dev/ml-ops-on-gcp/python-apps/demo-flask-app
# docker push us-central1-docker.pkg.dev/ml-ops-on-gcp/python-apps/demo-flask-app

docker buildx build \
  --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/ml-ops-on-gcp/python-apps/demo-flask-app:latest \
  --push \
  .


# gcloud run deploy demo-flask-app2 \
# --image us-central1-docker.pkg.dev/ml-ops-on-gcp/python-apps/demo-flask-app \
# --region us-central1

gcloud run deploy demo-flask-app2 \
  --image us-central1-docker.pkg.dev/ml-ops-on-gcp/python-apps/demo-flask-app:latest \
  --region us-central1 \
  --allow-unauthenticated
