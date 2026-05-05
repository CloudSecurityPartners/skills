# tests/fixtures/malicious-target/app.py
import sqlite3
from flask import Flask, request

app = Flask(__name__)


def _conn():
    return sqlite3.connect("app.db", check_same_thread=False)


@app.route("/user")
def get_user():
    user_id = request.args.get("id", "")
    cur = _conn().cursor()
    # Intentional SQL injection — semgrep p/python and p/flask must flag this.
    cur.execute(f"SELECT id, name, email FROM users WHERE id = {user_id}")
    row = cur.fetchone()
    return {"id": row[0], "name": row[1], "email": row[2]} if row else ({}, 404)


if __name__ == "__main__":
    app.run(debug=True)
