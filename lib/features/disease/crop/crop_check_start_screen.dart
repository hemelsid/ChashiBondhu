import 'package:flutter/material.dart';

import '../../../core/storage/app_settings.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/choice_grid.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../common/check_draft.dart';
import '../common/disease_library.dart';
import '../common/kind_ui.dart';
import '../common/photo_step_screen.dart';

/// Crop names the farmer typed ("অন্য ফসল"), kept for next time.
class CustomCrops {
  CustomCrops._();

  static const _key = 'customCrops';

  static List<String> all() =>
      ((AppSettings.get(_key) as List?) ?? const []).map((e) => e.toString()).toList();

  static Future<void> add(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final list = all()..remove(n);
    await AppSettings.put(_key, [n, ...list]);
  }

  static Future<void> remove(String name) async =>
      AppSettings.put(_key, all()..remove(name));
}

/// ফসলের রোগ চেক. Step 1: which crop? (one tap goes to the photo step)
class CropCheckStartScreen extends StatefulWidget {
  const CropCheckStartScreen({super.key});

  @override
  State<CropCheckStartScreen> createState() => _CropCheckStartScreenState();
}

class _CropCheckStartScreenState extends State<CropCheckStartScreen> {
  static const _otherId = '__other__';

  void _start({String? cropId, required String label}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoStepScreen(
        // A typed crop has no id → every problem in the library is considered.
        draft: CheckDraft(kind: DiseaseKind.crop, cropId: cropId, cropLabel: label),
      ),
    ));
  }

  Future<void> _askName() async {
    final ctrl = TextEditingController();
    final ok = await showBigDialog<bool>(
      context,
      title: const Text('কোন ফসল?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      body: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(fontSize: 21),
        decoration: const InputDecoration(hintText: 'যেমন: পেঁপে, মুলা, ঢেঁড়স'),
      ),
      buttons: (ctx) => [
        BigButton(
            label: 'এগিয়ে যান',
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.of(ctx).pop(true)),
        BigButton(
            label: 'বাতিল',
            icon: Icons.close,
            outlined: true,
            onPressed: () => Navigator.of(ctx).pop(false)),
      ],
    );
    final name = ctrl.text.trim();
    if (ok != true || name.isEmpty || !mounted) return;
    await CustomCrops.add(name);
    if (!mounted) return;
    setState(() {});
    _start(label: name);
  }

  Future<void> _removeCustom(String name) async {
    final ok = await confirmDialog(context,
        title: 'তালিকা থেকে সরাবেন?', message: name, confirmLabel: 'সরান');
    if (!ok) return;
    await CustomCrops.remove(name);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const kind = DiseaseKind.crop;
    final custom = CustomCrops.all();
    return Scaffold(
      appBar: AppBar(title: Text(kind.title), backgroundColor: kind.color),
      body: FutureBuilder<DiseaseLibrary>(
        future: DiseaseLibrary.load(kind),
        builder: (context, snap) {
          final lib = snap.data;
          if (lib == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('কোন ফসল?',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ChoiceGrid<String>(
                columns: 3,
                tileHeight: 112,
                options: [
                  for (final c in lib.crops)
                    ChoiceOption(value: c.id, label: c.label, emoji: c.emoji),
                  const ChoiceOption(value: _otherId, label: 'অন্য ফসল', emoji: '➕'),
                ],
                selected: null,
                onSelected: (id) {
                  if (id == _otherId) {
                    _askName();
                  } else {
                    _start(cropId: id, label: lib.crop(id)?.label ?? id);
                  }
                },
              ),
              if (custom.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('আপনার যোগ করা ফসল (সরাতে চেপে ধরে রাখুন)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final name in custom)
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => _start(label: name),
                          onLongPress: () => _removeCustom(name),
                          icon: const Text('🌱', style: TextStyle(fontSize: 22)),
                          label: Text(name),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
