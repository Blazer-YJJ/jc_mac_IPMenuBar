#!/bin/bash
# 安装 IPMenuBar：拷到 /Applications 并注册登录自启（LaunchAgent）。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="io.github.blazeryjj.ipmenubar"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
APP="/Applications/IPMenuBar.app"

command -v swiftc >/dev/null || { echo "需要 Xcode Command Line Tools：xcode-select --install" >&2; exit 1; }
make -C "$ROOT" bundle

if ! cp -R "$ROOT/build/IPMenuBar.app" "$APP.tmp" 2>/dev/null; then
  echo "没有 /Applications 写权限，试试：sudo bash $0" >&2
  exit 1
fi
rm -rf "$APP"
mv "$APP.tmp" "$APP"

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$APP/Contents/MacOS/IPMenuBar</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><false/>
  <key>ProcessType</key><string>Interactive</string>
  <key>LimitLoadToSessionType</key><string>Aqua</string>
</dict>
</plist>
EOF

plutil -lint "$PLIST" >/dev/null
pkill -f "IPMenuBar.app/Contents/MacOS/IPMenuBar" 2>/dev/null || true
sleep 1
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
sleep 1
echo "已安装：$APP（登录后自动出现在菜单栏）"
