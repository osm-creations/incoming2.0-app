"""Add isolated simulator test bundles to the XcodeGen spec, preserving both production app targets."""
from pathlib import Path
p = Path("project.yml")
t = p.read_text()
additional = """  NativeClipHostedTests:
    type: bundle.unit-test
    platform: iOS
    sources: [.github/native-clip/Hosted]
    dependencies:
      - target: IncomingClip
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.osmcreations.qa.ClipHostedTests
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_FILE: ""
        CODE_SIGN_ENTITLEMENTS: ""
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/IncomingClip.app/IncomingClip"
        BUNDLE_LOADER: "$(TEST_HOST)"
  NativeClipUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [.github/native-clip/UI]
    dependencies:
      - target: IncomingClip
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.osmcreations.qa.ClipUITests
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_FILE: ""
        CODE_SIGN_ENTITLEMENTS: ""
        TEST_TARGET_NAME: IncomingClip
"""
t=t.replace("schemes:\n",additional+"\nschemes:\n")
for name in ("NativeClipHostedTests","NativeClipUITests"):
    t += f"""
  {name}:
    build:
      targets:
        IncomingClip: all
    test:
      targets:
        - {name}
"""
# Use an isolated loopback fixture; production Swift source and production target remain intact.
t=t.replace("INFOPLIST_FILE: Sources/IncomingClip/Info.plist","INFOPLIST_FILE: .github/native-clip/FixtureEndpoints.plist")
p.write_text(t)
