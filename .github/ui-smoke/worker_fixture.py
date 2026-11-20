from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import json

primary = '/api/v1/clip-configs/primary'
config = {
    "id": "demo", "public_config_id": "sample", "name": "Performance",
    "mode": "DIRECT_NOTES", "enabled": 1, "open_overflow_initially": 0,
    "static_text": "Rose", "caller_name": "Jamie Rose", "uses_plain_presentation": False,
}
patches = []
reads = []


class Fixture(BaseHTTPRequestHandler):
    def respond(self, data):
        body = json.dumps({"data": data}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def config_response(self):
        self.respond({"config": config, "invocation_url": "https://example.com/c/105/sample"})

    def do_POST(self):
        if self.path != "/api/v1/auth/refresh":
            return self.send_error(404)
        self.respond({
            "accessToken": "test-access", "refreshToken": "test-refresh", "expiresIn": 3600,
            "forcePasswordChange": False,
            "user": {"id": "sample", "publicUserId": "105", "email": "performer@example.com",
                     "role": "USER", "status": "ACTIVE"}
        })

    def do_GET(self):
        if self.path == '/ready':
            return self.respond(True)
        if self.path != primary:
            return self.send_error(404)
        reads.append(config.get('reveal_delay_seconds'))
        print('PRIMARY GET', reads[-1], flush=True)
        Path('roundtrip.json').write_text(json.dumps({'gets': reads, 'patches': patches}))
        self.config_response()

    def do_PATCH(self):
        if self.path != primary:
            return self.send_error(404)
        data = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        if set(data) != {"revealDelaySeconds"} or type(data["revealDelaySeconds"]) != int or not 0 <= data["revealDelaySeconds"] <= 60:
            return self.send_error(422, "Unexpected PATCH body")
        value = data["revealDelaySeconds"]
        print("PRIMARY PATCH", data, flush=True)
        patches.append(value)
        config["reveal_delay_seconds"] = value
        Path('roundtrip.json').write_text(json.dumps({'gets': reads, 'patches': patches}))
        self.config_response()


HTTPServer(("127.0.0.1", 8743), Fixture).serve_forever()
