import os
import requests
from flask import Flask, jsonify

app = Flask(__name__)
BACKEND_URL = os.environ.get("BACKEND_URL", "http://backend:5002")

@app.route("/health")
def health():
    return jsonify({"service": "internal-api", "status": "healthy", "backend": BACKEND_URL})

@app.route("/backend-data")
def backend_data():
    try:
        response = requests.get(f"{BACKEND_URL}/data", timeout=5)
        response.raise_for_status()
        return jsonify({"service": "internal-api", "backend": response.json()})
    except requests.RequestException as exc:
        return jsonify({"error": "unable to reach backend", "detail": str(exc)}), 502

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
