import 'package:flutter/material.dart';

import '../../core/storage/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/choice_grid.dart';
import '../../core/widgets/section_title.dart';
import '../pond/data/pond.dart';
import '../pond/data/pond_repository.dart';
import 'reminder.dart';
import 'reminder_repository.dart';
import 'reminder_ui.dart';

class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({super.key});

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  ReminderType? _type;
  Pond? _pond;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _saving = false;

  void _onType(ReminderType t) {
    setState(() {
      _type = t;
      _time = t == ReminderType.feed
          ? const TimeOfDay(hour: 8, minute: 0)
          : const TimeOfDay(hour: 7, minute: 0);
      _suggestHarvest();
    });
  }

  void _onPond(String? pondId) {
    setState(() {
      _pond = pondId == null ? null : PondRepository.instance.pond(pondId);
      _suggestHarvest();
    });
  }

  void _suggestHarvest() {
    final p = _pond;
    if (_type == ReminderType.harvest && p != null) {
      _date = estimateHarvest(p.species, p.stockDate);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
      cancelText: 'বাতিল',
      confirmText: 'ঠিক আছে',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      cancelText: 'বাতিল',
      confirmText: 'ঠিক আছে',
      helpText: 'সময় বেছে নিন',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final type = _type;
    if (type == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final base = type.daily ? now : _date;
    final reminder = Reminder(
      id: newId(),
      type: type,
      pondId: _pond?.id,
      pondName: _pond?.name,
      dueAt: DateTime(base.year, base.month, base.day, _time.hour, _time.minute),
      notificationId: await AppSettings.nextNotificationId(),
      createdAt: now,
      updatedAt: now,
    );
    final scheduled = await ReminderRepository.instance.add(reminder);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(scheduled
          ? 'রিমাইন্ডার রাখা হয়েছে ✓'
          : 'রাখা হয়েছে, কিন্তু সময় পার হয়ে গেছে — ফোনে জানানো হবে না'),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final type = _type;
    final ponds = PondRepository.instance.allPonds();

    return Scaffold(
      appBar: AppBar(title: const Text('নতুন রিমাইন্ডার'), backgroundColor: AppColors.cardDiary),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionTitle('কিসের রিমাইন্ডার?', icon: Icons.alarm),
          ChoiceGrid<ReminderType>(
            columns: 2,
            tileHeight: 110,
            options: [
              for (final t in ReminderType.values)
                ChoiceOption(value: t, label: t.label, icon: t.icon, iconColor: t.color),
            ],
            selected: type,
            onSelected: _onType,
          ),
          if (type != null) ...[
            if (ponds.isNotEmpty) ...[
              const SectionTitle('কোন পুকুর? (না বাছলেও চলবে)', icon: Icons.water),
              // Compare by id: pond objects are re-read on every build.
              ChoiceGrid<String?>(
                columns: 2,
                tileHeight: 80,
                options: [
                  const ChoiceOption<String?>(
                      value: null, label: 'সব পুকুর', icon: Icons.select_all),
                  for (final p in ponds)
                    ChoiceOption<String?>(value: p.id, label: p.name, emoji: p.species.emoji),
                ],
                selected: _pond?.id,
                onSelected: _onPond,
              ),
            ],
            if (!type.daily) ...[
              SectionTitle(
                  type == ReminderType.harvest && _pond != null
                      ? 'তারিখ (আনুমানিক, বদলাতে পারেন)'
                      : 'তারিখ',
                  icon: Icons.calendar_month),
              _PickerButton(
                icon: Icons.event,
                text: Bn.relativeDate(_date),
                onTap: _pickDate,
              ),
            ],
            SectionTitle(type.daily ? 'প্রতিদিন কখন?' : 'সময়', icon: Icons.schedule),
            _PickerButton(
              icon: Icons.access_time,
              text: bnTime(_time.hour, _time.minute),
              onTap: _pickTime,
            ),
            const SizedBox(height: 24),
            BigButton(
              label: 'সংরক্ষণ করুন',
              icon: Icons.check,
              color: AppColors.cardDiary,
              onPressed: _saving ? null : _save,
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppColors.cardDiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ),
            const Text('বদলান', style: TextStyle(fontSize: 17, color: AppColors.cardDiary)),
          ],
        ),
      ),
    );
  }
}
