import json
import sys
from pathlib import Path

events = json.loads(Path(sys.argv[1]).read_text())["data"]
stages = {"notes", "armed", "revealed", "returned", "afterUp", "afterDown"}
assert len(events) == len(stages) and {e["stage"] for e in events} == stages, events
for event in events:
    assert event["windows"] > 0 and event["views"] == [], event
print("All scenes checked; no native volume view or custom meter", events)
