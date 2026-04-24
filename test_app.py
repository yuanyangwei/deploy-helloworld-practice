import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_hello(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b"Hello World" in response.data

def test_login_success(client):
    response = client.post('/login', json={"username": "admin", "password": "secret123"})
    assert response.status_code == 200
    data = response.get_json()
    assert data["success"] is True
    assert data["user"] == "admin"

def test_login_missing_fields(client):
    response = client.post('/login', json={})
    assert response.status_code == 400
    data = response.get_json()
    assert data["success"] is False
    assert "required" in data["message"]

def test_login_invalid(client):
    response = client.post('/login', json={"username": "foo", "password": "bar"})
    assert response.status_code == 401
    data = response.get_json()
    assert data["success"] is False
    assert "Invalid" in data["message"]
