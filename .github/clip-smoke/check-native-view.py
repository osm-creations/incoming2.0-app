import json
from pathlib import Path
import sys

events = json.loads(Path(sys.argv[1]).read_text())["data"]
stages = {e["stage"]: e["views"] for e in events}
assert len(events) == 4 and set(stages) == {"notes", "armed", "revealed", "returned"}, events
for stage in ("notes", "revealed", "returned"):
    assert stages[stage] == [], (stage, stages[stage])
assert len(stages["armed"]) == 1, stages["armed"]
view = stages["armed"][0]
assert view["identifier"] == "performance.systemVolumeView", view
assert view["windowMatch"] and not view["windowHidden"], view
assert view["intersectsWindow"] and view["width"] > 5 and view["height"] > 5, view
assert not view["hidden"] and view["effectiveAlpha"] > 0.01, view
assert view["systemSliderEnabled"] and view["accessibilityHidden"], view
assert not view["directInteraction"] and not view["effectiveInteraction"] and not view["interceptsHit"], view
print("Native volume-view hierarchy and hit testing verified", json.dumps(events, separators=(",", ":")))
