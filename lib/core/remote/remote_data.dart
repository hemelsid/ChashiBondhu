import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../storage/local_db.dart';

enum OnlineState { unknown, checking, online, offline }

/// Online + offline data.
///
/// The data files live in the GitHub repo (`assets/data/*.json`). When there
/// is internet the app downloads newer copies, checks them, and keeps them
/// for offline use. With no internet it uses the last good copy, or the copy
/// bundled inside the app. Editing a file on GitHub updates every phone/PC.
class RemoteData {
  RemoteData._();

  static const baseUrl =
      'https://raw.githubusercontent.com/hemelsid/ChashiBondhu/main/assets/data/';

  /// Files kept up to date.
  static const files = [
    'contacts.json',
    'market_prices.json',
    'briefing.json',
    'fish_diseases.json',
    'crop_diseases.json',
  ];

  /// How often to look for new data on its own.
  static const every = Duration(hours: 3);

  static final ValueNotifier<OnlineState> state = ValueNotifier(OnlineState.unknown);

  /// Bumps whenever any file changes, so screens can rebuild.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// A downloaded file is used only if its checker says it is fine.
  static final Map<String, bool Function(String text)> _validators = {};

  static void registerValidator(String file, bool Function(String text) check) =>
      _validators[file] = check;

  static Box<dynamic> get _box => LocalDb.box(LocalDb.remoteData);

  static DateTime? get lastUpdated {
    final ms = _box.get('lastSuccess') as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Last good downloaded copy, or null.
  static String? text(String file) => _box.get('text:$file') as String?;

  /// Downloaded copy if there is one, else the copy bundled in the app.
  static Future<String> textOrAsset(String file) async =>
      text(file) ?? await rootBundle.loadString('assets/data/$file');

  static Future<String> asset(String file) => rootBundle.loadString('assets/data/$file');

  static AppLifecycleListener? _lifecycle;
  static bool _running = false;

  /// Call once after the first screen is shown.
  static void start() {
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(refresh()));
    unawaited(refresh());
  }

  /// Looks for newer data. Quiet: never throws, never blocks the app.
  static Future<bool> refresh({bool force = false}) async {
    if (_running) return false;
    final last = _box.get('lastTry') as int?;
    if (!force &&
        last != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)) < every) {
      return false;
    }
    _running = true;
    state.value = OnlineState.checking;
    var changed = false;
    try {
      await _box.put('lastTry', DateTime.now().millisecondsSinceEpoch);
      for (final f in files) {
        final etag = _box.get('etag:$f') as String?;
        final res = await http.get(
          Uri.parse('$baseUrl$f'),
          headers: {if (etag != null) 'If-None-Match': etag},
        ).timeout(const Duration(seconds: 20));
        if (res.statusCode == 304) continue;
        if (res.statusCode != 200) continue;
        final body = const Utf8Decoder(allowMalformed: false).convert(res.bodyBytes);
        final check = _validators[f];
        if (check != null && !check(body)) {
          debugPrint('remote $f rejected by checker');
          continue;
        }
        if (body != text(f)) {
          await _box.put('text:$f', body);
          changed = true;
        }
        final newTag = res.headers['etag'];
        if (newTag != null) await _box.put('etag:$f', newTag);
      }
      await _box.put('lastSuccess', DateTime.now().millisecondsSinceEpoch);
      state.value = OnlineState.online;
    } catch (e) {
      debugPrint('remote refresh failed: $e');
      state.value = OnlineState.offline;
    } finally {
      _running = false;
    }
    if (changed) revision.value++;
    return changed;
  }
}
