#!/usr/bin/env python3
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

ALLOWED_ORIGINS = [
    "http://localhost:8083",
    "http://127.0.0.1:8083",
    "http://localhost:8084",
    "http://127.0.0.1:8084",
    "http://localhost:8089",
    "http://127.0.0.1:8089",
]

USERS = {}

def cors_headers(origin):
    hdrs = {
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
        "Access-Control-Allow-Credentials": "false",
    }
    if origin in ALLOWED_ORIGINS:
        hdrs["Access-Control-Allow-Origin"] = origin
    else:
        hdrs["Access-Control-Allow-Origin"] = "*"
    return hdrs

class Handler(BaseHTTPRequestHandler):
    def _write_json(self, code, payload):
        origin = self.headers.get("Origin", "*")
        hdrs = cors_headers(origin)
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        for k, v in hdrs.items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode("utf-8"))

    def do_OPTIONS(self):
        origin = self.headers.get("Origin", "*")
        hdrs = cors_headers(origin)
        self.send_response(204)
        for k, v in hdrs.items():
            self.send_header(k, v)
        self.end_headers()

    def do_POST(self):
        path = urlparse(self.path).path
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length).decode('utf-8') if length > 0 else '{}'
        try:
            data = json.loads(body)
        except Exception:
            data = {}

        if path == "/auth/register":
            email = (data.get("email") or "").strip()
            username = (data.get("username") or "").strip()
            password = (data.get("password") or "").strip()
            if not email or not username or not password:
                return self._write_json(400, {"message": "invalid payload"})
            if username in USERS:
                return self._write_json(409, {"message": "user exists"})
            USERS[username] = {"id": f"u_{len(USERS)+1}", "email": email, "username": username, "password": password}
            token = f"mock-token-{username}"
            return self._write_json(201, {"token": token, "user": {"id": USERS[username]["id"], "email": email, "username": username}})

        if path == "/auth/login":
            identifier = (data.get("identifier") or "").strip()
            password = (data.get("password") or "").strip()
            # Support email or username
            user = None
            for u in USERS.values():
                if u["username"].lower() == identifier.lower() or u["email"].lower() == identifier.lower():
                    user = u
                    break
            if not user or user["password"] != password:
                return self._write_json(401, {"message": "invalid credentials"})
            token = f"mock-token-{user['username']}"
            return self._write_json(200, {"token": token, "user": {"id": user["id"], "email": user["email"], "username": user["username"]}})

        return self._write_json(404, {"message": "not found"})

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/users":
            # Return all users without passwords
            users = [
                {"id": u.get("id"), "email": u.get("email"), "username": u.get("username")}
                for u in USERS.values()
            ]
            return self._write_json(200, {"users": users})
        if path == "/auth/verify-token":
            auth = self.headers.get("Authorization", "")
            if auth.startswith("Bearer mock-token-"):
                return self._write_json(200, {"ok": True})
            return self._write_json(401, {"ok": False})

        if path == "/auth/me":
            # Simple: return the first user if token present
            auth = self.headers.get("Authorization", "")
            if auth.startswith("Bearer mock-token-") and USERS:
                username = auth.replace("Bearer mock-token-", "")
                user = USERS.get(username)
                if user:
                    return self._write_json(200, {"id": user["id"], "email": user["email"], "username": user["username"]})
            return self._write_json(401, {"message": "unauthorized"})

        return self._write_json(404, {"message": "not found"})

def run(host="127.0.0.1", port=3000):
    print(f"Mock API listening on http://{host}:{port}")
    HTTPServer((host, port), Handler).serve_forever()

if __name__ == "__main__":
    run()