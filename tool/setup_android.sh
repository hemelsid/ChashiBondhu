#!/usr/bin/env bash
# One-time: generate android/ around the existing lib/ code, then patch it
# (Bangla name, permissions, Android 8+, reminders), and fetch packages.
set -e
cd "$(dirname "$0")/.."

flutter create --project-name chashibondhu --org com.chashibondhu --platforms android .
dart run tool/patch_android.dart
flutter pub get
echo "Done. Connect your phone (USB debugging on) and run: flutter run"
