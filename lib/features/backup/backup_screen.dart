import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import '../../core/utils/platform_info.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/section_title.dart';
import 'backup_service.dart';

/// Move records between phone and PC with a file (no internet needed),
/// and make Excel files.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() job) async {
    setState(() => _busy = true);
    String? message;
    try {
      message = await job();
    } on FormatException {
      message = 'এটা চাষিবন্ধুর ব্যাকআপ ফাইল নয়, অথবা নতুন সংস্করণের ফাইল।';
    } catch (_) {
      message = 'কাজটি করা যায়নি। আবার চেষ্টা করুন।';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String? _exported(ExportOutcome o) => o == ExportOutcome.done
      ? (PlatformInfo.isDesktop ? 'ফাইল সংরক্ষণ হয়েছে ✓' : null)
      : null;

  @override
  Widget build(BuildContext context) {
    final desktop = PlatformInfo.isDesktop;
    return Scaffold(
      appBar: AppBar(title: const Text('ফাইলে তথ্য আনা-নেওয়া')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const SectionTitle('ব্যাকআপ ফাইল', icon: Icons.sync_alt),
            Text(
              desktop
                  ? 'ফোনের চাষিবন্ধু থেকে ব্যাকআপ ফাইল এই কম্পিউটারে আনুন, তারপর "ফাইল থেকে আনুন" চাপুন। '
                      'এখানকার তথ্যও ফাইল করে ফোনে নিতে পারবেন।'
                  : 'ফাইলটি হোয়াটসঅ্যাপ, ব্লুটুথ বা ড্রাইভে কম্পিউটারে বা নতুন ফোনে পাঠান। '
                      'সেখানে "ফাইল থেকে আনুন" চাপলেই সব তথ্য চলে আসবে।',
              style: const TextStyle(fontSize: 17, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            BigButton(
              label: 'ব্যাকআপ ফাইল বানান',
              icon: Icons.upload_file,
              onPressed: () => _run(() async => _exported(await BackupService.exportBackup())),
            ),
            const SizedBox(height: 12),
            BigButton(
              label: 'ফাইল থেকে আনুন',
              icon: Icons.download,
              outlined: true,
              onPressed: () => _run(() async {
                final r = await BackupService.importBackup();
                if (r == null) return null;
                return r.added == 0
                    ? 'নতুন কিছু নেই — সব তথ্য আগেই আছে'
                    : '${Bn.digits(r.added)}টি নতুন তথ্য যোগ হয়েছে ✓';
              }),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('আনলে কিছু মুছে যায় না। ছবি ফাইলে যায় না।',
                  style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
            ),
            const SectionTitle('এক্সেল ফাইল', icon: Icons.table_chart),
            const Text('কম্পিউটারে এক্সেলে খুলে দেখা, প্রিন্ট বা অফিসারকে দেওয়ার জন্য।',
                style: TextStyle(fontSize: 17, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            BigButton(
              label: 'পুকুরের হিসাব (এক্সেল)',
              icon: Icons.water,
              outlined: true,
              color: AppColors.cardPond,
              onPressed: () =>
                  _run(() async => _exported(await BackupService.exportPondLogsCsv())),
            ),
            const SizedBox(height: 12),
            BigButton(
              label: 'রোগ চেকের রিপোর্ট (এক্সেল)',
              icon: Icons.healing,
              outlined: true,
              color: AppColors.cardDisease,
              onPressed: () =>
                  _run(() async => _exported(await BackupService.exportReportsCsv())),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
