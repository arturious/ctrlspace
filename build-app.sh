#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
APP="$ROOT/build/ctrlspace.app"

swift build --package-path "$ROOT" -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$ROOT/App/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/.build/release/ctrlspace" "$APP/Contents/MacOS/ctrlspace"

echo "$APP"
