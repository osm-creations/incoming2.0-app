"""Loopback-only, two-account API fixture for the dashboard and Settings UI test."""
import json
import os
import secrets
from http.server import BaseHTTPRequestHandler, HTTPServer

INITIAL = {
    "alice": {"staticText": "Coral", "callerName": "Casey", "injectUserId": "alpha_id"},
    "bob": {"staticText": "Teal", "callerName": "Rowan", "injectUserId": "beta_id"},
}
UPDATES = ["updated_id", ""]
PRIMARY = "/api/v1/clip-configs/primary"
configs = {account: dict(config) for account, config in INITIAL.items()}
reads = set()
writes = []
violations = []
sessions = {}


class Fixture(BaseHTTPRequestHandler):
    def reply(self, data, status=200):
        self.send_json({"data": data}, status)

    def error(self, status, code, message):
        self.send_json({"error": {"code": code, "message": message}}, status)

    def send_json(self, item, status):
        body = json.dumps(item).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def json_body(self):
        return json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))) or b"{}")

    def access_account(self):
        auth = self.headers.get("Authorization")
        for account, access in sessions.values():
            if auth == "Bearer " + access:
                return account
        return None

    def issue_session(self, account):
        refresh = secrets.token_urlsafe(20)
        access = secrets.token_urlsafe(20)
        sessions[refresh] = (account, access)
        self.reply({
            "accessToken": access, "refreshToken": refresh, "expiresIn": 3600,
            "forcePasswordChange": False,
            "user": {"id": "qa-" + account, "publicUserId": account, "email": account + "@example.invalid",
                     "role": "USER", "status": "ACTIVE"},
        })

    def primary(self, account):
        config = {"id": "primary-" + account, "publicConfigId": "config-" + account,
                  "name": "Fixture", "mode": "DIRECT_NOTES", "enabled": 1,
                  "openOverflowInitially": 0, **configs[account]}
        self.reply({"config": config, "invocationUrl": f"http://127.0.0.1:8743/c/{account}/fixture?t=local"})

    def do_POST(self):
        body = self.json_body()
        if self.path == "/api/v1/auth/login":
            account = body.get("login", "").removesuffix("@example.invalid")
            if account in INITIAL and body.get("password") == "fixturepass":
                return self.issue_session(account)
            return self.error(401, "UNAUTHENTICATED", "Invalid fixture login.")
        if self.path in ("/api/v1/auth/refresh", "/api/v1/auth/logout"):
            session = sessions.pop(body.get("refreshToken"), None)
            if self.path.endswith("/logout"):
                return self.reply({"loggedOut": True})
            if session:
                return self.issue_session(session[0])
            return self.error(401, "UNAUTHENTICATED", "Invalid fixture refresh token.")
        self.error(404, "NOT_FOUND", "Unknown route.")

    def do_GET(self):
        if self.path == "/ready":
            return self.reply({"ready": True})
        if self.path == "/verified":
            expected = {"alice": {**INITIAL["alice"], "injectUserId": ""}, "bob": INITIAL["bob"]}
            verified = reads == set(INITIAL) and writes == UPDATES and configs == expected and not violations
            return self.reply({"verified": verified, "reads": sorted(reads), "writes": writes,
                               "violations": violations}, 200 if verified else 409)
        if self.path == PRIMARY:
            account = self.access_account()
            if account is None:
                return self.error(401, "UNAUTHENTICATED", "Sign in to read settings.")
            reads.add(account)
            return self.primary(account)
        self.error(404, "NOT_FOUND", "Unknown route.")

    def do_PATCH(self):
        body = self.json_body()
        account = self.access_account()
        if self.path != PRIMARY or account != "alice" or len(writes) >= len(UPDATES) or body != {
            "injectUserId": UPDATES[len(writes)]
        }:
            violations.append("Unexpected PATCH account, route, fields, value or order.")
            return self.error(409, "UNEXPECTED_WRITE", violations[-1])
        configs[account]["injectUserId"] = body["injectUserId"]
        writes.append(body["injectUserId"])
        self.primary(account)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", int(os.environ.get("FIXTURE_PORT", "8743"))), Fixture).serve_forever()
