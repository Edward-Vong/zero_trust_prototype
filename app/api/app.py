import ssl
import json
import os
from flask import Flask, jsonify, request
import requests
from requests.adapters import HTTPAdapter
from urllib3.poolmanager import PoolManager

app = Flask(__name__)

BACKEND_URL = 'https://backend.local:5000'
CERT_DIR = '/app/certs'
KEY_PASSWORD_FILE = os.environ.get('KEY_PASSWORD_FILE', f'{CERT_DIR}/key_pass.txt')


def _key_password():
    if os.path.isfile(KEY_PASSWORD_FILE):
        with open(KEY_PASSWORD_FILE, 'r', encoding='utf-8') as f:
            value = f.read().strip()
            return value or None
    return None


class SSLContextAdapter(HTTPAdapter):
    def __init__(self, ssl_context, *args, **kwargs):
        self.ssl_context = ssl_context
        super().__init__(*args, **kwargs)

    def init_poolmanager(self, connections, maxsize, block=False, **pool_kwargs):
        self.poolmanager = PoolManager(
            num_pools=connections,
            maxsize=maxsize,
            block=block,
            ssl_context=self.ssl_context,
            **pool_kwargs,
        )


def _backend_session():
    """Return a requests.Session configured for mTLS to the backend."""
    client_ctx = ssl.create_default_context(cafile=f'{CERT_DIR}/ca_chain.crt')
    client_ctx.load_cert_chain(
        certfile=f'{CERT_DIR}/api/api.crt',
        keyfile=f'{CERT_DIR}/api/api.key',
        password=_key_password(),
    )

    session = requests.Session()
    session.mount('https://', SSLContextAdapter(client_ctx))
    return session


def _decode_json_or_text(response):
    try:
        return response.json()
    except ValueError:
        return {"raw": response.text}


@app.route('/health')
def health():
    return jsonify({"status": "API service is healthy"})


@app.route('/api/data', methods=['GET', 'POST'])
def api_data():
    try:
        session = _backend_session()
        if request.method == 'POST':
            payload = request.get_json(silent=True)
            if payload is None:
                raw_body = request.get_data(as_text=True).strip()
                if raw_body:
                    try:
                        payload = json.loads(raw_body)
                    except json.JSONDecodeError:
                        return jsonify({"error": "Invalid JSON body"}), 400
                else:
                    payload = {}
            response = session.post(f'{BACKEND_URL}/data', json=payload, timeout=5)
        else:
            response = session.get(f'{BACKEND_URL}/data', timeout=5)

        body = _decode_json_or_text(response)
        return jsonify(body), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/mtls/backend/health', methods=['GET'])
def api_mtls_backend_health():
    """Simple probe endpoint that checks backend health using mTLS."""
    try:
        session = _backend_session()
        response = session.get(f'{BACKEND_URL}/health', timeout=5)
        return jsonify(
            {
                "mtls": "ok",
                "backend_status": response.status_code,
                "backend_body": _decode_json_or_text(response),
            }
        ), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"mtls": "failed", "error": str(e)}), 500


@app.route('/api/mtls/backend/no-cert', methods=['GET'])
def api_mtls_backend_no_cert():
    """Control endpoint that tries backend TLS without a client cert."""
    try:
        response = requests.get(
            f'{BACKEND_URL}/health',
            verify=f'{CERT_DIR}/ca_chain.crt',
            timeout=5,
        )
        return jsonify(
            {
                "rejected": False,
                "unexpected_status": response.status_code,
                "backend_body": _decode_json_or_text(response),
            }
        ), 200
    except requests.exceptions.RequestException as e:
        return jsonify({"rejected": True, "error": str(e)}), 200


if __name__ == '__main__':
    server_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    server_ctx.load_cert_chain(
        certfile=f'{CERT_DIR}/api/api.crt',
        keyfile=f'{CERT_DIR}/api/api.key',
        password=_key_password(),
    )
    server_ctx.load_verify_locations(cafile=f'{CERT_DIR}/ca_chain.crt')
    server_ctx.verify_mode = ssl.CERT_REQUIRED

    app.run(
        host='0.0.0.0',
        port=4000,
        ssl_context=server_ctx,
    )