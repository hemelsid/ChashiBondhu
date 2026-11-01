import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/bangla.dart';
import '../../core/utils/platform_info.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/confirm_dialog.dart';
import 'reminder.dart';
import 'reminder_form_screen.dart';
import 'reminder_repository.dart';
import 'reminder_ui.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  void _add(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ReminderFormScreen()));

  @override
  Widget build(BuildContext context) {
    final repo = ReminderRepository.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('রিমাইন্ডার'), backgroundColor: AppColors.cardDiary),
      body: ValueListenableBuilder(
        valueListenable: repo.changes,
        builder: (context, _, __) {
          final list = repo.all();
          return Column(
            children: [
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.alarm, size: 100, color: AppColors.cardDiary),
                            SizedBox(height: 12),
                            Text('কোনো রিমাইন্ডার নেই', style: AppText.title),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                              PlatformInfo.hasReminderAlerts
                                  ? 'কাজ হলে টিক দিন। মুছতে চেপে ধরে রাখুন।'
                                  : 'কম্পিউটারে শব্দ করে জানানো হয় না — সময় হলে হোমের "আজকের কাজ"-এ দেখাবে। '
                                      'কাজ হলে টিক দিন, মুছতে চেপে ধরে রাখুন (মাউসে ক্লিক করে ধরে রাখুন)।',
                              style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
                          for (final r in list) _ReminderTile(reminder: r),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SafeArea(
                  top: false,
                  child: BigButton(
                    label: 'নতুন রিমাইন্ডার',
                    icon: Icons.add_alarm,
                    color: AppColors.cardDiary,
                    onPressed: () => _add(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});

  final Reminder reminder;

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDialog(context,
        title: 'রিমাইন্ডার মুছবেন?',
        message: reminder.type.label,
        confirmLabel: 'হ্যাঁ, মুছুন');
    if (ok) await ReminderRepository.instance.delete(reminder);
  }

  @override
  Widget build(BuildContext context) {
    final r = reminder;
    final done = r.isDone();
    final when = r.type.daily
        ? 'প্রতিদিন ${bnTime(r.dueAt.hour, r.dueAt.minute)}'
        : '${Bn.relativeDate(r.dueAt)}, ${bnTime(r.dueAt.hour, r.dueAt.minute)}';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: done ? AppColors.okBg : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: done ? AppColors.ok : AppColors.border, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ReminderRepository.instance.toggleDone(r),
          onLongPress: () => _delete(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: r.type.color,
                  child: Icon(r.type.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.type.label,
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              decoration: done ? TextDecoration.lineThrough : null)),
                      Text(when, style: const TextStyle(fontSize: 16)),
                      if (r.pondName != null)
                        Text(r.pondName!,
                            style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 42, color: done ? AppColors.ok : AppColors.textMuted),
                    Text(done ? 'হয়েছে' : 'বাকি',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: done ? AppColors.ok : AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
