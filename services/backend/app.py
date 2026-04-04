from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/health")
def health():
    return jsonify({"service": "backend", "status": "healthy"})

@app.route("/data")
def data():
    return jsonify({
        "service": "backend",
        "message": "Secure backend data",
        "items": [
            {"id": 1, "name": "trusted resource"},
            {"id": 2, "name": "internal config"}
        ]
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002)
