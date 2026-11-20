import json
import os
import subprocess
import sys

def sim(*args):
    return subprocess.check_output(['xcrun', 'simctl', *args], text=True)

size = sys.argv[1]
runtimes = json.loads(sim('list', 'runtimes', '-j'))['runtimes']
ios = [r for r in runtimes if '.iOS-' in r['identifier'] and r['isAvailable']]
ios.sort(key=lambda r: tuple(map(int, r['version'].split('.'))), reverse=True)
devices = json.loads(sim('list', 'devicetypes', '-j'))['devicetypes']
names = [d['name'] for d in devices if d['name'].startswith('iPhone')]
if size == 'small':
    preferred = ['iPhone SE (3rd generation)', 'iPhone 13 mini', 'iPhone 12 mini', 'iPhone 16e', 'iPhone 17e', 'iPhone 14', 'iPhone 13']
else:
    preferred = list(reversed([n for n in names if 'Pro Max' in n]))
ids = {d['name']: d['identifier'] for d in devices}
for runtime in ios:
    for name in preferred:
        if name not in ids:
            continue
        result = subprocess.run(['xcrun', 'simctl', 'create', f'Notes {size} {name}', ids[name], runtime['identifier']], capture_output=True, text=True)
        if result.returncode == 0:
            with open(os.environ['GITHUB_ENV'], 'a') as f:
                print('DEVICE=' + result.stdout.strip(), file=f)
                print('SIM_MODEL=' + name, file=f)
            print(f'{size}: {name}, iOS {runtime["version"]}', flush=True)
            sys.exit(0)
raise RuntimeError(f'No available {size} device for installed runtimes')
