from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from secrets import token_hex
from collections import Counter

sessions = {}
counts = Counter()

class Fixture(BaseHTTPRequestHandler):
    def reply(self, payload, status=200):
        body = json.dumps({"data": payload}).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def read_body(self):
        return json.loads(self.rfile.read(int(self.headers["Content-Length"])))

    def profile_for(self, action):
        parts = self.path.split("/")
        if len(parts) != 7 or parts[1:5] != ["api","v1","app-clip","sessions"] or parts[-1] != action:
            self.send_error(404)
            return
        stored = sessions.get(parts[-2])
        if not stored or self.headers.get("Authorization") != "Clip " + stored[1]:
            self.send_error(401)
            return
        return stored[0]

    def do_POST(self):
        if self.path != "/api/v1/app-clip/bootstrap":
            return self.send_error(404)
        data = self.read_body()
        if data == {"shortToken":"AAAAAAAAAAAAAAAAAAAAAA"}:
            profile = "plain-compact"
        elif data == {"shortToken":"BBBBBBBBBBBBBBBBBBBBBB"}:
            profile = "plain-zero"
        elif data == {"shortToken":"DDDDDDDDDDDDDDDDDDDDDD"}:
            profile = "plain-meter"
        elif data == {"shortToken":"CCCCCCCCCCCCCCCCCCCCCC"}:
            profile = "plain-missing"
        elif data == {"publicUserId":"106", "publicConfigId":"sample", "capability":"local"}:
            profile = "standard-legacy"
        else:
            print("Unexpected fixture bootstrap", data, flush=True)
            return self.send_error(422)
        session, token = token_hex(8), token_hex(12)
        sessions[session] = (profile, token)
        counts["boot-" + profile] += 1
        self.reply({
            "configuration":{"callerName":"jamie rose","hasInjectUserId":profile != "plain-missing",
                             "usesPlainPresentation":profile.startswith("plain"),"name":"Fixture",
                             "revealDelaySeconds":0 if profile.endswith("zero") else (8 if profile.endswith("meter") else 5),
                             "mode":"DIRECT_NOTES","staticText":"Rose",
                             "openOverflowInitially":False,"options":[]},
            "session":{"id":session,"token":token,"expiresAt":"2099-01-01T00:00:00Z"}
        })

    def do_GET(self):
        if self.path == "/ready":
            return self.reply({})
        if self.path == "/verified":
            print("FIXTURE-COUNTS", dict(counts), flush=True)
            return self.reply(dict(counts))
        profile = self.profile_for("selection")
        if not profile: return
        counts["selection-" + profile] += 1
        if profile == "plain-missing":
            return self.send_error(424, "Missing Inject handle must be handled without a selection request")
        self.reply({"value":"taylor anderson" if profile.startswith("plain") else "morgan finch"})

    def do_PATCH(self):
        profile = self.profile_for("status")
        if not profile: return
        data=self.read_body()
        assert data["status"] in ("BLACK_WAITING", "NOTES")
        counts[data["status"] + "-" + profile] += 1
        self.reply({"status":data["status"]})

HTTPServer(("127.0.0.1",8743),Fixture).serve_forever()
