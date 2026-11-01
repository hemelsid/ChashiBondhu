import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'app_data.dart';
import 'core/notifications/notification_service.dart';
import 'core/remote/remote_data.dart';
import 'core/storage/local_db.dart';
import 'core/sync/sync_manager.dart';

/// `--selftest` (used by CI on the PC build): start normally, draw the
/// first screen, then close with exit code 0. A crash fails the build.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.init(); // offline storage, no login, no internet needed
  registerRemoteData();
  await NotificationService.instance.init();
  runApp(const ChashibondhuApp());

  if (args.contains('--selftest')) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 3), () => exit(0));
    });
    return;
  }
  // Online parts start after the first screen; they never block the app.
  RemoteData.start(); // newer contacts, prices, news, disease library
  unawaited(SyncManager.instance.start()); // optional cloud backup
}
