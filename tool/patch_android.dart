// Patches the android/ folder that `flutter create` generated.
// Safe to run more than once. Works with Groovy (build.gradle) and
// Kotlin (build.gradle.kts) projects.
//
//   dart run tool/patch_android.dart
import 'dart:io';

void main() {
  _manifest();
  _gradle();
  _signing();
  _proguard();
  _icon();
  stdout.writeln('Android patched: name, icon, permissions, Android 8+ (minSdk 26), '
      'notifications, signing, R8 rules.');
}

/// Copies branding/android/mipmap-*/ic_launcher.png over the Flutter default.
void _icon() {
  final src = Directory('branding/android');
  if (!src.existsSync()) return;
  for (final dir in src.listSync().whereType<Directory>()) {
    final name = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final target = Directory('android/app/src/main/res/$name')..createSync(recursive: true);
    File('${dir.path}/ic_launcher.png').copySync('${target.path}/ic_launcher.png');
  }
}

/// Release builds are signed with keystore/release.jks (kept in the repo on
/// purpose: same key every build, so new versions install over old ones).
void _signing() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  final isKts = kts.existsSync();
  final f = isKts ? kts : groovy;
  var s = f.readAsStringSync();
  if (s.contains('keystore/release.jks')) return;
  if (!File('keystore/release.jks').existsSync()) return;

  final block = isKts
      ? '''
    signingConfigs {
        create("release") {
            storeFile = file("../../keystore/release.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "chashibondhu"
            keyAlias = "chashibondhu"
            keyPassword = System.getenv("KEYSTORE_PASSWORD") ?: "chashibondhu"
        }
    }

    buildTypes {'''
      : '''
    signingConfigs {
        release {
            storeFile file("../../keystore/release.jks")
            storePassword System.getenv("KEYSTORE_PASSWORD") ?: "chashibondhu"
            keyAlias "chashibondhu"
            keyPassword System.getenv("KEYSTORE_PASSWORD") ?: "chashibondhu"
        }
    }

    buildTypes {''';
  if (!RegExp(r'\n\s*buildTypes\s*\{').hasMatch(s)) {
    _fail('buildTypes not found in ${f.path}');
  }
  s = s.replaceFirst(RegExp(r'\n\s*buildTypes\s*\{'), '\n$block');
  // Point the release build at our key. Templates differ by Flutter version:
  //   Kotlin:  signingConfig = signingConfigs.getByName("debug")
  //   Groovy:  signingConfig = signingConfigs.debug   (or without "=")
  final before = s;
  s = isKts
      ? s.replaceFirst(
          RegExp(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)'),
          'signingConfig = signingConfigs.getByName("release")')
      : s.replaceFirst(RegExp(r'signingConfig\s*=?\s*signingConfigs\.debug'),
          'signingConfig = signingConfigs.release');
  if (s == before) {
    _fail('Could not switch the release build to keystore/release.jks in ${f.path}. '
        'APKs would be signed with a throw-away debug key.');
  }
  f.writeAsStringSync(s);
}

void _fail(String msg) {
  stderr.writeln('ERROR: $msg');
  exit(1);
}

void _manifest() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) _fail('Run `flutter create` first (no AndroidManifest.xml).');
  var s = f.readAsStringSync();

  // App name under the icon.
  s = s.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="চাষিবন্ধু"');

  const perms = [
    'android.permission.INTERNET',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
  ];
  for (final p in perms) {
    if (!s.contains(p)) {
      s = s.replaceFirst(
          '<application', '<uses-permission android:name="$p"/>\n    <application');
    }
  }

  if (!s.contains('ScheduledNotificationReceiver')) {
    s = s.replaceFirst('</application>', '''
        <!-- Reminders (flutter_local_notifications) -->
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>''');
  }

  if (!s.contains('android.intent.action.DIAL')) {
    s = s.replaceFirst('</manifest>', '''
    <!-- Phone call to officer / helpline -->
    <queries>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
    </queries>
</manifest>''');
  }
  f.writeAsStringSync(s);
}

void _gradle() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  final isKts = kts.existsSync();
  final f = isKts ? kts : groovy;
  if (!f.existsSync()) _fail('android/app/build.gradle(.kts) not found.');
  var s = f.readAsStringSync();

  // Android 8.0+ only (API 26).
  s = s.replaceAllMapped(
    RegExp(r'minSdk(Version)?(\s*=?\s*)flutter\.minSdkVersion'),
    (m) => 'minSdk${m[1] ?? ''}${m[2]}26',
  );

  // Java 8+ APIs on old phones (needed by the reminders plugin).
  if (!s.contains('esugaringEnabled')) {
    s = s.replaceFirst(
      RegExp(r'compileOptions\s*\{'),
      isKts
          ? 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true'
          : 'compileOptions {\n        coreLibraryDesugaringEnabled true',
    );
  }
  if (!s.contains('desugar_jdk_libs')) {
    s += isKts
        ? '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")\n}\n'
        : "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'\n}\n";
  }
  if (!s.contains('esugaringEnabled')) {
    _fail('Could not find compileOptions in ${f.path}. Add core library '
        'desugaring by hand (see README).');
  }
  f.writeAsStringSync(s);
}

void _proguard() {
  // Flutter adds android/app/proguard-rules.pro to release builds automatically.
  File('android/app/proguard-rules.pro').writeAsStringSync('''
# flutter_local_notifications stores scheduled reminders with Gson.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keepattributes Signature
''');
}
