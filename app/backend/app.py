import os
import sqlite3
from flask import Flask, jsonify, request

DB_PATH = os.environ.get('BACKEND_DB_PATH', 'data/data.db')
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

app = Flask(__name__)


def get_db():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_db()
    conn.execute(
        '''CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            value TEXT NOT NULL
        )'''
    )
    conn.commit()
    conn.close()


init_db()


@app.route('/health')
def health():
    return jsonify({"status": "Backend service is healthy"})


@app.route('/data', methods=['GET', 'POST'])
def data():
    if request.method == 'POST':
        payload = request.get_json() or {}
        value = payload.get('value')
        if not value:
            return jsonify({"error": "Missing value parameter"}), 400

        conn = get_db()
        cursor = conn.execute('INSERT INTO items (value) VALUES (?)', (value,))
        conn.commit()
        item_id = cursor.lastrowid
        conn.close()

        return jsonify({"id": item_id, "value": value}), 201

    conn = get_db()
    rows = conn.execute('SELECT id, value FROM items ORDER BY id DESC').fetchall()
    conn.close()

    return jsonify({"items": [dict(row) for row in rows]})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)