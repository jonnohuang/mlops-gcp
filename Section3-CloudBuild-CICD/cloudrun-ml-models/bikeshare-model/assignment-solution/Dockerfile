FROM python:3.11-slim

ENV APP_HOME=/app
WORKDIR $APP_HOME

# App code
COPY assignment-solution/main.py ./main.py
COPY assignment-solution/requirements.txt ./requirements.txt

# Course artifact (for demo). In portfolio mode, prefer MODEL_URI from GCS.
COPY model.joblib ./model.joblib

RUN pip install --no-cache-dir -r requirements.txt

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
