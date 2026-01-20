# import pytest
# from unittest.mock import patch,MagicMock
# from main import app, client as app_client

# @pytest.fixture
# def client():
#     with app.test_client() as client:
#         yield client

# @patch.object(app_client,'load_table_from_uri')
# @patch.object(app_client,'get_table')
# def test_main_endpoint(mock_get_table, mock_load_table_from_uri, client):
#     mock_load_job = MagicMock()
#     mock_load_table_from_uri.return_value = mock_load_job

#     mock_table = MagicMock()
#     mock_table.num_rows = 50
#     mock_get_table.return_value = mock_table

#     response = client.get('/')
#     assert response.status_code == 200
#     data = response.get_json()
#     assert 'data' in data
#     assert data['data'] == 40
    
#     mock_load_table_from_uri.assert_called_once()
#     mock_load_job.result.assert_called_once()
#     mock_get_table.assert_called_once()

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
    mock_load_job = MagicMock()
    mock_bq.load_table_from_uri.return_value = mock_load_job
    mock_bq.get_table.return_value = types.SimpleNamespace(num_rows=50)

    monkeypatch.setattr(main, "get_bq_client", lambda: mock_bq)
    monkeypatch.setattr(main, "make_job_config", lambda: object())  # no google import

    resp = flask_client.get("/")

    assert resp.status_code == 200
    assert resp.get_json() == {"data": 50}
    mock_bq.load_table_from_uri.assert_called_once()
    mock_load_job.result.assert_called_once()
    mock_bq.get_table.assert_called_once()


# Execute pytest -q to run tests