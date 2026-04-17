from flask import Flask, jsonify, request
import requests

app = Flask(__name__)

BACKEND_URL = 'http://backend:5000'

@app.route('/health')
def health():
    return jsonify({"status": "API service is healthy"})


@app.route('/api/data', methods=['GET', 'POST'])
def api_data():
    try:
        if request.method == 'POST':
            payload = request.get_json() or {}
            response = requests.post(f'{BACKEND_URL}/data', json=payload, timeout=5)
        else:
            response = requests.get(f'{BACKEND_URL}/data', timeout=5)

        response.raise_for_status()
        return jsonify(response.json()), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=4000)