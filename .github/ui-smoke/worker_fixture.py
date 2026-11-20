"""Local-only sample data for review screenshots of the signed-in performer."""
from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class Fixture(BaseHTTPRequestHandler):
    def respond(self, data):
        body = json.dumps({"data": data}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path != "/api/v1/auth/refresh":
            return self.send_error(404)
        self.respond({
            "accessToken": "sample-access", "refreshToken": "sample-refresh", "expiresIn": 3600,
            "forcePasswordChange": False,
            "user": {"id": "sample", "publicUserId": "105", "email": "performer@example.com",
                     "role": "USER", "status": "ACTIVE"}
        })

    def do_GET(self):
        if self.path == "/ready":
            return self.respond({"ready": True})
        if self.path != "/api/v1/clip-configs/primary":
            return self.send_error(404)
        self.respond({
            "config": {"id": "sample", "publicConfigId": "sample", "name": "Performance",
                       "mode": "DIRECT_NOTES", "enabled": 1, "openOverflowInitially": 0,
                       "staticText": "Rose", "callerName": "Jamie Rose", "injectUserId": "performer_demo",
                       "usesPlainPresentation": True},
            "invocationUrl": "https://example.com/c/105/sample"
        })

HTTPServer(("127.0.0.1", 8743), Fixture).serve_forever()
