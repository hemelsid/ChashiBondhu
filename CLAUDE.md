# Notes for AI assistants working on this repo

- This repo (`hemelsid/Chashibondhu`) is the single home of the চাষিবন্ধু app (Flutter): Android phone + PC (Windows). Each Release contains both.
  Commit and push every change here so the owner always has the latest code and APKs.
- After each change: update `CHANGELOG.md`, push to `main`, wait for the "Build APK" workflow,
  and give the owner the new Release files.
- The owner can't run builds locally; **GitHub Actions is the build machine**.
  The `android/` and `windows/` folders are generated in CI by `flutter create` +
  `tool/patch_android.dart` / `tool/patch_windows.dart` (not committed). Put platform changes
  in the patch scripts. The PC installer is `tool/installer.iss` (Inno Setup).
- Keep phone and PC in step: same features; use `PlatformInfo` for differences
  (no camera and no reminder alerts on PC — "আজকের কাজ" shows due reminders there).
- **Online data** (updates installed apps without a new APK): `assets/data/*.json` on `main` is
  downloaded by `RemoteData` (contacts, market prices, briefing, disease libraries), checked by the
  validators in `lib/app_data.dart`, cached for offline. Edits there do not trigger an APK build.
  `briefing.json` is rewritten every 6 h by `.github/workflows/briefing.yml`.
- **Contacts**: only verified numbers, with `source`. Never invent officer phone numbers.
- Flutter version is pinned in `.github/workflows/build.yml` (`FLUTTER_VERSION`).
- Keep the committed signing key `keystore/release.jks` (password `chashibondhu`);
  changing it forces users to uninstall and lose their offline data.
- Keep every APK: never delete a Release. Each build adds a new one (`v0.4.<run>`); newest is Latest.
- **All in-app text must be Bangla script** (no English-only labels, no Banglish).
  Design rules: one screen = one job, big buttons, max 6 Home cards, offline-first, no login,
  green = ঠিক আছে / yellow = সতর্ক / red = বিপদ.
- Disease checks: never name medicines/pesticides or doses; never say 100% sure;
  always show the disclaimer. `test/features_test.dart` guards this.
- Never put this app's code in other repos (e.g. Sathi.AI, MediaDownloader, Rong-Studio).
- Talk to the owner in Bengali (Bangla script, not Banglish).
