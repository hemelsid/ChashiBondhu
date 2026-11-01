import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/remote/remote_data.dart';
import '../../core/storage/app_settings.dart';
import '../../core/storage/local_db.dart';
import 'contacts_data.dart';

class ContactsRepository {
  ContactsRepository._();

  static final ContactsRepository instance = ContactsRepository._();

  static const file = 'contacts.json';

  Box<dynamic> get _box => LocalDb.box(LocalDb.contacts);

  /// Rebuild when own contacts, settings or downloaded data change.
  Listenable get changes =>
      Listenable.merge([_box.listenable(), AppSettings.listenable(), RemoteData.revision]);

  /// Shared directory: newest checked download, else the bundled copy.
  Future<ContactsData> directory() async {
    final remote = RemoteData.text(file);
    if (remote != null && ContactsData.isValid(remote)) return ContactsData.parse(remote);
    return ContactsData.parse(await RemoteData.asset(file));
  }

  /// Numbers saved by the farmer (plus the officer numbers from Settings).
  List<PhoneContact> mine() {
    final list = _box.values
        .whereType<Map>()
        .map((m) => PhoneContact.fromMap(m, mine: true))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final fromSettings = [
      if (AppSettings.fishOfficerPhone.isNotEmpty)
        PhoneContact(
          id: '_fish',
          name: AppSettings.fishOfficerName.isEmpty
              ? 'উপজেলা মৎস্য কর্মকর্তা'
              : AppSettings.fishOfficerName,
          role: 'উপজেলা মৎস্য কর্মকর্তা',
          phone: AppSettings.fishOfficerPhone,
          mine: true,
        ),
      if (AppSettings.cropOfficerPhone.isNotEmpty)
        PhoneContact(
          id: '_crop',
          name: AppSettings.cropOfficerName.isEmpty
              ? 'উপজেলা কৃষি কর্মকর্তা'
              : AppSettings.cropOfficerName,
          role: 'উপজেলা কৃষি কর্মকর্তা',
          phone: AppSettings.cropOfficerPhone,
          mine: true,
        ),
    ];
    return [...fromSettings, ...list];
  }

  Future<void> save(PhoneContact c) => _box.put(c.id, c.toMap());

  Future<void> delete(String id) async {
    if (id == '_fish') return AppSettings.setFishOfficer('', '');
    if (id == '_crop') return AppSettings.setCropOfficer('', '');
    await _box.delete(id);
  }
}
