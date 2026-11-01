import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../storage/local_db.dart';
import 'supabase_config.dart';
import 'sync_outbox.dart';
import 'sync_service.dart';
import 'sync_tables.dart';

enum SyncState {
  /// No Supabase keys in this build — offline only.
  off,
  idle,
  syncing,

  /// Tried, no internet. Will try again.
  offline,
  error,
}

/// Optional cloud backup. Never blocks the app:
/// - starts after the first screen is shown
/// - signs in anonymously (no login screen); a phone number can be linked
///   to the same account later
/// - pushes the outbox on app start, on resume, every 10 minutes and a few
///   seconds after each change.
class SyncManager implements SyncService {
  SyncManager._();

  static final SyncManager instance = SyncManager._();

  final ValueNotifier<SyncState> state = ValueNotifier(SyncState.off);
  final ValueNotifier<DateTime?> lastSynced = ValueNotifier(null);

  bool _initialized = false;
  bool _running = false;
  Timer? _debounce;
  Timer? _periodic;
  AppLifecycleListener? _lifecycle;

  /// Supabase client once ready, else null (used by market prices).
  SupabaseClient? get client => _initialized ? Supabase.instance.client : null;

  bool get enabled => SupabaseConfig.enabled;

  Future<void> start() async {
    if (!enabled) {
      state.value = SyncState.off;
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _initialized = true;
      state.value = SyncState.idle;
    } catch (e) {
      debugPrint('supabase init failed: $e');
      state.value = SyncState.error;
      return;
    }
    SyncOutbox.onChanged = schedule;
    _lifecycle = AppLifecycleListener(onResume: schedule);
    _periodic = Timer.periodic(const Duration(minutes: 10), (_) => schedule());
    // Make sure the users row exists.
    await SyncOutbox.upsert('users', 'me');
    unawaited(pushPending());
  }

  /// Push soon (waits a few seconds so many quick changes go together).
  void schedule() {
    if (!_initialized) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), () => unawaited(pushPending()));
  }

  Future<String?> _uid() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    return auth.currentUser?.id;
  }

  @override
  Future<void> pushPending() async {
    if (!_initialized || _running) return;
    _running = true;
    state.value = SyncState.syncing;
    try {
      final uid = await _uid();
      if (uid == null) throw Exception('no user');
      final db = Supabase.instance.client;

      final entries = SyncOutbox.pending();
      int order(Map e) => kSyncTables[e['table']]?.order ?? 9;
      final upserts = entries.where((e) => e['op'] == 'upsert').toList()
        ..sort((a, b) => order(a).compareTo(order(b)));
      final deletes = entries.where((e) => e['op'] == 'delete').toList()
        ..sort((a, b) => order(b).compareTo(order(a)));

      for (final e in [...upserts, ...deletes]) {
        final spec = kSyncTables[e['table']];
        if (spec == null) {
          await SyncOutbox.markDone(e);
          continue;
        }
        try {
          if (e['op'] == 'delete') {
            await db.from(spec.table).delete().eq('id', e['id'] as String);
          } else {
            Map<dynamic, dynamic>? local;
            final boxName = spec.box;
            if (boxName != null) {
              final m = LocalDb.box(boxName).get(e['id']);
              if (m is! Map) {
                // Record gone locally (deleted later) — nothing to send.
                await SyncOutbox.markDone(e);
                continue;
              }
              local = m;
              if (spec.table == 'disease_reports') {
                local = await _uploadPhoto(db, uid, local);
              }
            }
            await db.from(spec.table).upsert(spec.toRemote(local ?? const {}, uid));
          }
          await SyncOutbox.markDone(e);
        } on PostgrestException catch (err) {
          // Bad row (e.g. schema mismatch): log and keep it for a later fix,
          // but don't block the rest.
          debugPrint('sync ${spec.table} ${e['id']}: ${err.message}');
        }
      }
      lastSynced.value = DateTime.now();
      state.value = SyncState.idle;
    } on SocketException {
      state.value = SyncState.offline;
    } on TimeoutException {
      state.value = SyncState.offline;
    } catch (e) {
      debugPrint('sync failed: $e');
      // Most failures here are network related (ClientException, auth refresh).
      state.value = SyncState.offline;
    } finally {
      _running = false;
    }
  }

  /// Uploads the report photo once, and remembers the remote path locally.
  Future<Map<dynamic, dynamic>> _uploadPhoto(
      SupabaseClient db, String uid, Map<dynamic, dynamic> local) async {
    final path = local['photoPath'] as String?;
    if (path == null || local['remotePhotoPath'] != null) return local;
    final file = File(path);
    if (!file.existsSync()) return local;
    final remote = '$uid/${local['id']}.jpg';
    await db.storage.from(SupabaseConfig.photoBucket).upload(
          remote,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    final updated = Map<dynamic, dynamic>.from(local)..['remotePhotoPath'] = remote;
    // Write directly (not via repository) so it doesn't queue itself again.
    await LocalDb.box(LocalDb.diseaseReports).put(local['id'], updated);
    return updated;
  }

  void dispose() {
    _debounce?.cancel();
    _periodic?.cancel();
    _lifecycle?.dispose();
  }
}
