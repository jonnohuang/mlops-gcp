import types
from unittest.mock import MagicMock
import pytest
import main

@pytest.fixture
def flask_client():
    main.app.config["TESTING"] = True
    with main.app.test_client() as c:
        yield c

def test_root_returns_row_count(flask_client, monkeypatch):
    mock_bq = MagicMock()
    mock_bq.load_table_from_uri.return_value = MagicMock()
    mock_bq.get_table.return_value = types.SimpleNamespace(num_rows=50)

    monkeypatch.setattr(main, "get_bq_client", lambda: mock_bq)
    monkeypatch.setattr(main, "make_job_config", lambda: object())

    resp = flask_client.get("/")
    assert resp.status_code == 200
    assert resp.get_json() == {"data": 50}
