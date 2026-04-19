from flask import Flask, jsonify, request
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hi there! Welcome to the Hello World."

@app.route('/login', methods=["POST"])
def login():
    # Support JSON payloads and form-encoded payloads.
    data = request.get_json(silent=True) or request.form
    username = (data.get("username") or "").strip() if data else ""
    password = (data.get("password") or "") if data else ""

    if not username or not password:
        return jsonify({
            "success": False,
            "message": "username and password are required"
        }), 400

    # Demo-only authentication check; replace with real user validation.
    if username == "admin" and password == "secret123":
        return jsonify({
            "success": True,
            "message": "Login successful",
            "user": username
        }), 200

    return jsonify({
        "success": False,
        "message": "Invalid username or password"
    }), 401

if __name__ == "__main__":
    # Use environment variables for port (Standard practice)
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)