import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/app_info.dart';
import '../../core/data/bd_districts.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/app_settings.dart';
import '../../core/storage/local_db.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/sync/sync_outbox.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import '../../core/utils/phone_call.dart';
import '../../core/utils/photo_store.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/section_title.dart';
import '../../core/remote/remote_data.dart';
import '../backup/backup_screen.dart';
import '../contacts/contacts_screen.dart';
import '../pond/ui/pond_list_screen.dart';
import '../weather/district_picker_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ValueListenableBuilder(
        valueListenable: AppSettings.listenable(),
        builder: (context, _, __) {
          final district = districtById(AppSettings.districtId);
          final upazila = AppSettings.upazila;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              // ---- Area ----
              const SectionTitle('আমার এলাকা', icon: Icons.place),
              _InfoTile(
                icon: Icons.place,
                title: district == null
                    ? 'এলাকা বাছা হয়নি'
                    : (upazila.isEmpty ? district.name : '$upazila, ${district.name}'),
                actionLabel: 'বদলান',
                onAction: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const DistrictPickerScreen())),
              ),

              // ---- Ponds ----
              const SectionTitle('পুকুর', icon: Icons.water),
              BigButton(
                label: 'পুকুরের তালিকা',
                icon: Icons.list,
                outlined: true,
                color: AppColors.cardPond,
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PondListScreen())),
              ),

              // ---- Officers ----
              const SectionTitle('সাহায্যের জন্য যোগাযোগ', icon: Icons.support_agent),
              BigButton(
                label: 'সব যোগাযোগ (হেল্পলাইন, অফিস, এনজিও)',
                icon: Icons.support_agent,
                outlined: true,
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const ContactsScreen())),
              ),
              const SizedBox(height: 10),
              _OfficerTile(
                title: 'উপজেলা মৎস্য কর্মকর্তা',
                name: AppSettings.fishOfficerName,
                phone: AppSettings.fishOfficerPhone,
                onSave: AppSettings.setFishOfficer,
              ),
              _OfficerTile(
                title: 'উপজেলা কৃষি কর্মকর্তা',
                name: AppSettings.cropOfficerName,
                phone: AppSettings.cropOfficerPhone,
                onSave: AppSettings.setCropOfficer,
              ),
              const SizedBox(height: 8),
              BigButton(
                label: AppInfo.helplineLabel,
                icon: Icons.call,
                onPressed: () => callNumber(context, AppInfo.helplineNumber),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text('কৃষি, মাছ ও গবাদিপশুর বিনা খরচে পরামর্শ',
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
              ),

              // ---- Backup ----
              const SectionTitle('ফাইলে তথ্য আনা-নেওয়া', icon: Icons.sync_alt),
              BigButton(
                label: 'ব্যাকআপ ও এক্সেল ফাইল',
                icon: Icons.folder_open,
                outlined: true,
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BackupScreen())),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text('ফোন থেকে কম্পিউটারে, বা নতুন ফোনে — ইন্টারনেট ছাড়াই',
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
              ),
              const SectionTitle('অনলাইন তথ্য হালনাগাদ', icon: Icons.sync),
              const _DataUpdateTile(),
              const SectionTitle('অনলাইন ব্যাকআপ', icon: Icons.cloud),
              const _SyncTile(),

              // ---- Danger ----
              const SectionTitle('তথ্য মুছুন', icon: Icons.delete_forever),
              BigButton(
                label: 'ফোনের সব তথ্য মুছুন',
                icon: Icons.delete_forever,
                outlined: true,
                color: AppColors.danger,
                onPressed: () => _clearAll(context),
              ),

              // ---- About ----
              const SectionTitle('অ্যাপ সম্পর্কে', icon: Icons.info_outline),
              const Text('${AppInfo.name} — ${AppInfo.tagline}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('সংস্করণ ${AppInfo.version}', style: TextStyle(fontSize: 17)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _clearAll(BuildContext context) async {
    final first = await confirmDialog(context,
        title: 'সব তথ্য মুছবেন?',
        message: 'পুকুর, হিসাব, রোগের রিপোর্ট, ছবি ও রিমাইন্ডার এই ফোন থেকে মুছে যাবে। '
            'এলাকা ও যোগাযোগ নম্বর থাকবে।',
        confirmLabel: 'মুছুন');
    if (!first || !context.mounted) return;
    final second = await confirmDialog(context,
        title: 'আপনি নিশ্চিত?',
        message: 'মুছে ফেললে আর ফেরত আনা যাবে না।',
        confirmLabel: 'হ্যাঁ, সব মুছুন');
    if (!second || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await NotificationService.instance.cancelAll();
    for (final name in LocalDb.dataBoxes) {
      await LocalDb.box(name).clear();
    }
    await AppSettings.put('weather_cache', null);
    await PhotoStore.deleteAll();
    messenger.showSnackBar(const SnackBar(content: Text('সব তথ্য মুছে ফেলা হয়েছে')));
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 19))),
          SizedBox(
            height: 52,
            child: FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

class _OfficerTile extends StatelessWidget {
  const _OfficerTile({
    required this.title,
    required this.name,
    required this.phone,
    required this.onSave,
  });

  final String title;
  final String name;
  final String phone;
  final Future<void> Function(String name, String phone) onSave;

  Future<void> _edit(BuildContext context) async {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);
    final ok = await showBigDialog<bool>(
      context,
      title: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      body: Column(
        children: [
          TextField(
            controller: nameCtrl,
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(hintText: 'নাম'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: 'মোবাইল নম্বর'),
          ),
        ],
      ),
      buttons: (ctx) => [
        BigButton(
          label: 'সংরক্ষণ করুন',
          icon: Icons.check,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
        BigButton(
          label: 'বাতিল',
          icon: Icons.close,
          outlined: true,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
      ],
    );
    // Controllers are left to the garbage collector: the dialog's closing
    // animation may still touch them after showBigDialog returns.
    if (ok == true) await onSave(nameCtrl.text, phoneCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            hasPhone
                ? '${name.isEmpty ? '' : '$name · '}${Bn.digits(phone)}'
                : 'নম্বর রাখা হয়নি',
            style: const TextStyle(fontSize: 17, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasPhone) ...[
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () => callNumber(context, phone),
                      icon: const Icon(Icons.call),
                      label: const Text('ফোন'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.edit),
                    label: Text(hasPhone ? 'বদলান' : 'নম্বর রাখুন'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncTile extends StatelessWidget {
  const _SyncTile();

  @override
  Widget build(BuildContext context) {
    final sync = SyncManager.instance;
    if (!sync.enabled) {
      return const Text(
        'চালু নেই। সব তথ্য এই ফোনেই নিরাপদে থাকে, ইন্টারনেট লাগে না।',
        style: TextStyle(fontSize: 17, color: AppColors.textMuted),
      );
    }
    return ValueListenableBuilder(
      valueListenable: LocalDb.box(LocalDb.syncOutbox).listenable(),
      builder: (context, _, __) => ValueListenableBuilder<SyncState>(
        valueListenable: sync.state,
        builder: (context, state, _) {
          final pending = SyncOutbox.pendingCount;
          final last = sync.lastSynced.value;
          final text = switch (state) {
            SyncState.syncing => 'ব্যাকআপ হচ্ছে…',
            SyncState.offline => 'ইন্টারনেট নেই — পরে নিজে থেকে হবে',
            SyncState.error => 'ব্যাকআপ চালু করা যায়নি',
            _ => pending == 0 ? 'সব তথ্য ব্যাকআপ হয়েছে ✓' : 'বাকি আছে: ${Bn.digits(pending)}টি',
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (last != null)
                Text('শেষ ব্যাকআপ: ${Bn.relativeDate(last)}',
                    style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              BigButton(
                label: 'এখনই ব্যাকআপ করুন',
                icon: Icons.cloud_upload,
                outlined: true,
                onPressed: state == SyncState.syncing ? null : sync.pushPending,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DataUpdateTile extends StatelessWidget {
  const _DataUpdateTile();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OnlineState>(
      valueListenable: RemoteData.state,
      builder: (context, state, _) {
        final last = RemoteData.lastUpdated;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ইন্টারনেট থাকলে যোগাযোগের তালিকা, বাজার দর, খবর আর রোগের তথ্য নিজে থেকে '
              'হালনাগাদ হয়। ইন্টারনেট না থাকলে শেষ তথ্য দিয়েই সব চলে।',
              style: TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Text(
              last == null ? 'এখনো হালনাগাদ হয়নি' : 'শেষ হালনাগাদ: ${Bn.relativeDate(last)}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            BigButton(
              label: state == OnlineState.checking ? 'খোঁজা হচ্ছে…' : 'এখনই হালনাগাদ করুন',
              icon: Icons.sync,
              outlined: true,
              onPressed: state == OnlineState.checking
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await RemoteData.refresh(force: true);
                      final now = RemoteData.state.value;
                      messenger.showSnackBar(SnackBar(
                          content: Text(now == OnlineState.online
                              ? 'তথ্য হালনাগাদ হয়েছে ✓'
                              : 'ইন্টারনেট নেই — পরে নিজে থেকে হবে')));
                    },
            ),
          ],
        );
      },
    );
  }
}
