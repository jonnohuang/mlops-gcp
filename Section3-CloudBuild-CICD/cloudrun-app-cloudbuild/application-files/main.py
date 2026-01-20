from google.cloud import bigquery
from flask import Flask
import os

app = Flask(__name__)

TABLE_ID = "ml-ops-on-gcp.test_schema.us_states"
URI = "gs://ml-ops-on-gcp-data/us-states.csv"

def get_bq_client():
    # Use explicit project to avoid accidental defaults (like udemy-mlops-395416)
    return bigquery.Client(project="ml-ops-on-gcp")

def make_job_config():
    return bigquery.LoadJobConfig(
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
    )

@app.route("/")
def main():
    bq = get_bq_client()
    job_config = make_job_config()

    load_job = bq.load_table_from_uri(URI, TABLE_ID, job_config=job_config)
    load_job.result()

    destination_table = bq.get_table(TABLE_ID)
    return {"data": destination_table.num_rows}


@app.route("/healthz", methods=["GET"])
def healthz():
    return {"status": "ok"}, 200

@app.route("/readyz", methods=["GET"])
def readyz():
    return {"status": "ready"}, 200

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
