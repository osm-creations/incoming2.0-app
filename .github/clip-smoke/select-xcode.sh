#!/bin/bash
set -euo pipefail
xcode="$(python3 - <<'PY'
from pathlib import Path
import re
apps = list(Path('/Applications').glob('Xcode*.app'))
stable = [(tuple(map(int,m[1].split('.'))),p) for p in apps
          if (m:=re.fullmatch(r'Xcode_(26(?:\.[0-9]+)*)\.app',p.name))]
if stable:
    print(max(stable)[1])
else:
    print('/Applications/Xcode.app')
PY
)"
sudo xcode-select -s "$xcode/Contents/Developer"
xcodebuild -version
