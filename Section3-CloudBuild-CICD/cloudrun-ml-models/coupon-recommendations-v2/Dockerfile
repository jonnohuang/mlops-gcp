FROM python:3.10-slim

ENV APP_HOME=/app
WORKDIR $APP_HOME

# Install runtime deps
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY pyproject.toml ./pyproject.toml
COPY src ./src

# Optional: include model artifact for demo/testing.
# In production, prefer MODEL_URI=gs://... and do not bake artifacts into the image.
COPY artifacts ./artifacts

# Install the package (so imports work cleanly)
RUN pip install --no-cache-dir .

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 coupon_reco.app:app
