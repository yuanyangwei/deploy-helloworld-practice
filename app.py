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


# Example PUT endpoint
@app.route('/update', methods=["PUT"])
def update():
    data = request.get_json(silent=True) or {}
    username = (data.get("username") or "").strip()
    new_value = data.get("new_value")
    if not username or new_value is None:
        return jsonify({
            "success": False,
            "message": "username and new_value are required"
        }), 400
    # Demo: pretend to update something
    return jsonify({
        "success": True,
        "message": f"Updated {username} with new value: {new_value}"
    }), 200

# Example DELETE endpoint
@app.route('/delete', methods=["DELETE"])
def delete():
    data = request.get_json(silent=True) or {}
    username = (data.get("username") or "").strip()
    if not username:
        return jsonify({
            "success": False,
            "message": "username is required"
        }), 400
    # Demo: pretend to delete something
    return jsonify({
        "success": True,
        "message": f"Deleted user: {username}"
    }), 200

if __name__ == "__main__":
    # Use environment variables for port (Standard practice)
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)