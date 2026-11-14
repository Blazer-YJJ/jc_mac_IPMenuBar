#!/bin/bash
# 卸载 IPMenuBar：移除登录自启、结束进程、删除 /Applications 里的 App。
set -euo pipefail

LABEL="io.github.blazeryjj.ipmenubar"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"
pkill -f "IPMenuBar.app/Contents/MacOS/IPMenuBar" 2>/dev/null || true
rm -rf "/Applications/IPMenuBar.app"
echo "已卸载 IPMenuBar。"
