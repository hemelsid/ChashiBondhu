import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'ids.dart';

/// Takes / picks a photo and keeps a small copy inside the app folder, so it
/// stays available offline even if the farmer deletes it from the gallery.
class PhotoStore {
  PhotoStore._();

  static final ImagePicker _picker = ImagePicker();

  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photos');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns the saved file path, or null if the farmer cancelled.
  static Future<String?> pick({required bool camera}) async {
    final XFile? file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      // Small enough for low storage phones and slow upload later.
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );
    if (file == null) return null;
    return _keep(file);
  }

  /// On low-memory phones Android may close the app while the camera is open.
  /// Call this when the photo screen opens to recover that photo.
  static Future<String?> recoverLost() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      final file = response.file;
      return file == null ? null : _keep(file);
    } catch (_) {
      return null;
    }
  }

  static Future<String> _keep(XFile file) async {
    final dir = await _dir();
    final path = '${dir.path}/${newId()}.jpg';
    await file.saveTo(path);
    return path;
  }

  static Future<void> delete(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (f.existsSync()) await f.delete();
  }

  static Future<void> deleteAll() async {
    final dir = await _dir();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}
