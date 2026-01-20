from flask import Flask
import os

app = Flask(__name__)

TABLE_ID = "ml-ops-on-gcp.test_schema.us_states"
URI = "gs://ml-ops-on-gcp-data/us-states.csv"

def get_bq_client():
    from google.cloud import bigquery
    return bigquery.Client()

def make_job_config():
    from google.cloud import bigquery
    return bigquery.LoadJobConfig(
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
    )

@app.route("/")
def main():
    client = get_bq_client()
    job_config = make_job_config()

    load_job = client.load_table_from_uri(URI, TABLE_ID, job_config=job_config)
    load_job.result()

    destination_table = client.get_table(TABLE_ID)
    return {"data": destination_table.num_rows}

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 5052)))
