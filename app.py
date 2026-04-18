from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hi there! Welcome to the Hello World practice app."

if __name__ == "__main__":
    # Use environment variables for port (Standard practice)
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)