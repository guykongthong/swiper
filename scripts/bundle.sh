#!/bin/sh
# Builds Swiper and wraps it into build/Swiper.app (no Xcode needed).
set -e
cd "$(dirname "$0")/.."
swift build -c release
APP=build/Swiper.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/Swiper" "$APP/Contents/MacOS/Swiper"
[ -d Resources/Fonts ] && cp Resources/Fonts/* "$APP/Contents/Resources/" 2>/dev/null || true
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Swiper</string>
  <key>CFBundleIdentifier</key><string>io.github.guykongthong.swiper</string>
  <key>CFBundleExecutable</key><string>Swiper</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>ATSApplicationFontsPath</key><string>.</string>
</dict></plist>
PLIST
# Sign with a stable local certificate if it exists, so the Accessibility permission survives rebuilds.
# (macOS ties the permission to the signature; an ad hoc signature changes with every build.)
IDENTITY="${SIGN_IDENTITY:-Swiper Local Signing}"
if security find-identity -p codesigning | grep -q "$IDENTITY"; then
  codesign --force --sign "$IDENTITY" "$APP"
else
  echo "No '$IDENTITY' certificate found, using an ad hoc signature (permission resets on every rebuild)."
  codesign --force --sign - "$APP"
fi
echo "Built $APP"
