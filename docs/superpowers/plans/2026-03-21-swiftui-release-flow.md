# TodoFocus Native macOS Release Flow (Non-App-Store)

This release flow is for direct GitHub Releases distribution.

- Distribution channel: GitHub Releases only
- Primary artifact: zipped `.app`
- App Store submission: out of scope

## Release Artifacts

- `TodoFocus-macos-universal.zip` (required)
- `TodoFocus-macos-universal.zip.sha256` (required)
- optional: DMG as secondary convenience artifact

## Build and Package

```bash
APP_NAME="TodoFocusMac"
SCHEME="TodoFocusMac"
ARCHIVE_PATH="$PWD/build/${APP_NAME}.xcarchive"

xcodebuild \
  -project "macos/TodoFocusMac/TodoFocusMac.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  archive

APP_PATH="$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app"
mkdir -p dist
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "dist/TodoFocus-macos-universal.zip"

cd dist
shasum -a 256 "TodoFocus-macos-universal.zip" > "TodoFocus-macos-universal.zip.sha256"
```

## Optional Signing + Notarization (Recommended)

Use Developer ID signing + notarization for better user trust and reduced Gatekeeper friction.

```bash
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "build/TodoFocus-notarize.zip"

xcrun notarytool submit "build/TodoFocus-notarize.zip" \
  --keychain-profile "AC_NOTARY_PROFILE" \
  --wait

xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "dist/TodoFocus-macos-universal.zip"
```

## Upload to GitHub Release

```bash
TAG="vX.Y.Z"

gh release upload "$TAG" \
  "dist/TodoFocus-macos-universal.zip" \
  "dist/TodoFocus-macos-universal.zip.sha256" \
  --clobber
```

## CI Requirements

- `release-macos-native` workflow should:
  1. build and archive Release app
  2. produce zipped `.app`
  3. produce SHA256 checksum
  4. upload artifacts to the tagged GitHub release
- optional notarization stage can be enabled when credentials are configured.
