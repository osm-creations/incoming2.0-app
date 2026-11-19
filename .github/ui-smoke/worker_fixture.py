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
        if self.path != "/api/v1/app-clip/bootstrap":
            return self.send_error(404)
        data = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        assert data["publicUserId"] == "fixture" and data["capability"] == "local"
        self.reply(200, {
            "configuration": {
                "name":"Rehearsal", "mode":"DIRECT_NOTES", "staticText":"Rose",
                "callerName":"Jamie", "hasInjectUserId":data["publicConfigId"] == "enabled",
                "openOverflowInitially":False, "options":[]
            },
            "session":{"id":"rehearsal","token":"fixture-only","expiresAt":"2099-01-01T00:00:00Z"}
        })

    def do_GET(self):
        if self.path == "/ready":
            return self.reply(200, {})
        if self.path != "/api/v1/app-clip/sessions/rehearsal/selection":
            return self.send_error(404)
        assert self.headers["Authorization"] == "Clip fixture-only"
        self.reply(200, {"value":"Morgan"})

    def do_PATCH(self):
        if self.path != "/api/v1/app-clip/sessions/rehearsal/status":
            return self.send_error(404)
        assert self.headers["Authorization"] == "Clip fixture-only"
        data = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        self.reply(200, {"status":data["status"]})

ThreadingHTTPServer(("127.0.0.1", 8743), WorkerFixture).serve_forever()
