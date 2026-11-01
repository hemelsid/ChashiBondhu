import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/local_db.dart';
import 'core/sync/sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.init(); // offline storage, no login, no internet needed
  await NotificationService.instance.init();
  runApp(const ChashibondhuApp());
  // Optional cloud backup starts after the first screen; never blocks.
  unawaited(SyncManager.instance.start());
}
