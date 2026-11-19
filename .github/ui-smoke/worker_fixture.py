from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json

class WorkerFixture(BaseHTTPRequestHandler):
    def reply(self, status, data):
        body = json.dumps({"data": data}).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path == "/api/v1/auth/login":
            data = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            assert data["login"] == "fixture" and data["password"] == "fixture"
            return self.reply(200, {"accessToken":"fixture-access","refreshToken":"fixture-refresh",
                                    "expiresIn":3600,"forcePasswordChange":False,
                                    "user":{"id":"performer","publicUserId":"fixture","email":"fixture@example.invalid","role":"USER","status":"ACTIVE"}})
        if self.path != "/api/v1/app-clip/bootstrap":
            return self.send_error(404)
        data = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        assert data["publicUserId"] == "fixture" and data["capability"] == "local"
        self.reply(200, {
            "configuration": {
                "name":"Rehearsal", "mode":"DIRECT_NOTES", "staticText":"" if data["publicConfigId"] == "empty" else "Rose",
                "callerName":"Jamie", "hasInjectUserId":data["publicConfigId"] != "disabled",
                "openOverflowInitially":False, "options":[]
            },
            "session":{"id":"rehearsal","token":"fixture-only","expiresAt":"2099-01-01T00:00:00Z"}
        })

    def do_GET(self):
        if self.path == "/api/v1/clip-configs/primary":
            assert self.headers["Authorization"] == "Bearer fixture-access"
            return self.reply(200, {"config":{"id":"primary","publicConfigId":"enabled","name":"Fixture",
                                              "mode":"DIRECT_NOTES","enabled":1,"openOverflowInitially":0,
                                              "staticText":"Rose","injectUserId":""},
                                    "invocationUrl":"http://127.0.0.1:8743/c/fixture/enabled?t=local"})
        if self.path == "/ready":
            return self.reply(200, {})
        if self.path != "/api/v1/app-clip/sessions/rehearsal/selection":
            return self.send_error(404)
        assert self.headers["Authorization"] == "Clip fixture-only"
        self.reply(200, {"value":"Taylor Anderson"})

    def do_PATCH(self):
        if self.path != "/api/v1/app-clip/sessions/rehearsal/status":
            return self.send_error(404)
        assert self.headers["Authorization"] == "Clip fixture-only"
        data = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        self.reply(200, {"status":data["status"]})

ThreadingHTTPServer(("127.0.0.1", 8743), WorkerFixture).serve_forever()
