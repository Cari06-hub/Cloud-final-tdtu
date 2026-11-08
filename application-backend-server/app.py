import json
import os
from pathlib import Path
 
import pymysql
import requests
from flask import Flask, jsonify, request
from jose import jwt, JWTError
 
app = Flask(__name__)
BASE_DIR = Path(__file__).resolve().parent
 
@app.get("/hello")
def hello():
    return jsonify(message="Hello from App Server!")
 
@app.get("/student")
def student():
    with open(BASE_DIR / "students.json", "r", encoding="utf-8") as f:
        students = json.load(f)
    return jsonify(students)
@app.get("/students-db")
def students_db():
    try:
        conn = pymysql.connect(
            host=os.getenv("DB_HOST", "relational-database-server"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.environ["MARIADB_USER"],
            password=os.environ["MARIADB_PASSWORD"],
            database="studentdb",
            cursorclass=pymysql.cursors.DictCursor,
            connect_timeout=5,
        )
        try:
            with conn.cursor() as cursor:
                cursor.execute("SELECT id, student_id, fullname, dob, major "
                               "FROM students ORDER BY id")
                rows = cursor.fetchall()
        finally:
            conn.close()
        for item in rows:
            if item["dob"] is not None:
                item["dob"] = item["dob"].isoformat()
        return jsonify(rows)
    except (pymysql.MySQLError, KeyError, ValueError):
        app.logger.exception("Database query failed")
        return jsonify(error="Database temporarily unavailable"), 503
 
@app.get("/secure")
def secure():
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return jsonify(error="Missing Bearer token"), 401
    token = auth.split(" ", 1)[1].strip()
    issuer = os.getenv("OIDC_ISSUER", "")
    audience = os.getenv("OIDC_AUDIENCE", "flask-app")
    jwks_url = os.getenv("OIDC_JWKS_URL", "")
    if not issuer or not jwks_url:
        return jsonify(error="OIDC not configured"), 503
    try:
        response = requests.get(jwks_url, timeout=5)
        response.raise_for_status()
        payload = jwt.decode(
            token, response.json(), algorithms=["RS256"],
            audience=audience, issuer=issuer,
        )
        return jsonify(
            message="Secure resource OK",
            preferred_username=payload.get("preferred_username"),
        )
    except requests.RequestException:
        return jsonify(error="Identity provider unavailable"), 503
    except (JWTError, ValueError):
        return jsonify(error="Invalid or expired token"), 401
 
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081)
