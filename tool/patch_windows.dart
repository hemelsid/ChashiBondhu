// Patches the windows/ folder that `flutter create --platforms windows`
// generated: Bangla window title, window size, icon, file details.
// Safe to run more than once.
//
//   dart run tool/patch_windows.dart
import 'dart:io';

void main() {
  final main = File('windows/runner/main.cpp');
  if (!main.existsSync()) {
    stderr.writeln('ERROR: run `flutter create --platforms windows .` first.');
    exit(1);
  }

  // Title "চাষিবন্ধু" written as \u escapes so the C++ file stays ASCII.
  const title = r'L"চাষিবন্ধু"';
  var s = main.readAsStringSync();
  s = s.replaceFirst(RegExp(r'window\.Create\(L"[^"]*"'), 'window.Create($title');
  // Portrait-ish window that fits a 1366x768 laptop screen.
  s = s.replaceFirst(RegExp(r'Win32Window::Size size\(\d+, \d+\);'),
      'Win32Window::Size size(820, 700);');
  main.writeAsStringSync(s);

  final rc = File('windows/runner/Runner.rc');
  if (rc.existsSync()) {
    var r = rc.readAsStringSync();
    r = r
        .replaceFirst(RegExp(r'VALUE "FileDescription", "[^"]*"'),
            'VALUE "FileDescription", "Chashibondhu - farmer helper"')
        .replaceFirst(RegExp(r'VALUE "ProductName", "[^"]*"'),
            'VALUE "ProductName", "Chashibondhu"')
        .replaceFirst(RegExp(r'VALUE "CompanyName", "[^"]*"'), 'VALUE "CompanyName", "hemelsid"');
    rc.writeAsStringSync(r);
  }

  final icon = File('branding/windows/app_icon.ico');
  if (icon.existsSync()) icon.copySync('windows/runner/resources/app_icon.ico');

  stdout.writeln('Windows patched: title, size, icon, file details.');
}
