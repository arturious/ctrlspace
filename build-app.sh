#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
APP="$ROOT/build/ki.app"

swift build --package-path "$ROOT" -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$ROOT/App/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/.build/release/ki" "$APP/Contents/MacOS/ki"

echo "$APP"
