import os
import requests
from flask import Flask, jsonify, render_template

app = Flask(__name__, template_folder="templates")
INTERNAL_API_URL = os.environ.get("INTERNAL_API_URL", "http://internal-api:5001")

@app.route("/")
def index():
    return render_template("index.html", internal_api=INTERNAL_API_URL)

@app.route("/health")
def health():
    return jsonify({"service": "frontend", "status": "healthy"})

@app.route("/internal-data")
def internal_data():
    try:
        response = requests.get(f"{INTERNAL_API_URL}/backend-data", timeout=5)
        response.raise_for_status()
        return jsonify({"service": "frontend", "internal_api": response.json()})
    except requests.RequestException as exc:
        return jsonify({"error": "unable to reach internal-api", "detail": str(exc)}), 502

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
