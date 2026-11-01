# Notes for AI assistants working on this repo

- This repo (`hemelsid/Chashibondhu`) is the single home of the চাষিবন্ধু app (Flutter, Android).
  Commit and push every change here so the owner always has the latest code and APKs.
- After each change: update `CHANGELOG.md`, push to `main`, wait for the "Build APK" workflow,
  and give the owner the new Release files.
- The owner can't run builds locally; **GitHub Actions is the build machine**.
  The `android/` folder is generated in CI by `flutter create` + `tool/patch_android.dart`
  (not committed). Put Android changes in the patch script.
- Flutter version is pinned in `.github/workflows/build.yml` (`FLUTTER_VERSION`).
- Keep the committed signing key `keystore/release.jks` (password `chashibondhu`);
  changing it forces users to uninstall and lose their offline data.
- Keep every APK: never delete a Release. Each build adds a new one (`v0.2.<run>`); newest is Latest.
- **All in-app text must be Bangla script** (no English-only labels, no Banglish).
  Design rules: one screen = one job, big buttons, max 6 Home cards, offline-first, no login,
  green = ঠিক আছে / yellow = সতর্ক / red = বিপদ.
- Disease checks: never name medicines/pesticides or doses; never say 100% sure;
  always show the disclaimer. `test/features_test.dart` guards this.
- Never put this app's code in other repos (e.g. Sathi.AI, MediaDownloader, Rong-Studio).
- Talk to the owner in Bengali (Bangla script, not Banglish).
