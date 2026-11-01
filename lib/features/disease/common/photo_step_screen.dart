import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/photo_store.dart';
import '../../../core/utils/platform_info.dart';
import '../../../core/widgets/big_button.dart';
import 'check_draft.dart';
import 'kind_ui.dart';
import 'symptom_step_screen.dart';

/// Step: take or choose a photo. The photo is saved with the report so an
/// officer can see it later. (It is not analysed by the app.)
class PhotoStepScreen extends StatefulWidget {
  const PhotoStepScreen({super.key, required this.draft});

  final CheckDraft draft;

  @override
  State<PhotoStepScreen> createState() => _PhotoStepScreenState();
}

class _PhotoStepScreenState extends State<PhotoStepScreen> {
  String? _photo;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _photo = widget.draft.photoPath;
    _recover();
  }

  Future<void> _recover() async {
    final lost = await PhotoStore.recoverLost();
    if (lost != null && mounted) setState(() => _photo = lost);
  }

  Future<void> _pick(bool camera) async {
    setState(() => _busy = true);
    String? path;
    try {
      path = await PhotoStore.pick(camera: camera);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ছবি নেওয়া যায়নি। ক্যামেরার অনুমতি দিন।')));
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (path != null) {
        final old = _photo;
        if (old != null && old != path) PhotoStore.delete(old);
        _photo = path;
      }
    });
  }

  void _next() {
    widget.draft.photoPath = _photo;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SymptomStepScreen(draft: widget.draft)));
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.draft.kind;
    final photo = _photo;
    final subject = widget.draft.pondName ?? widget.draft.cropLabel;

    return Scaffold(
      appBar: AppBar(title: Text(kind.title), backgroundColor: kind.color),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (subject != null)
                Text(subject,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: AppColors.textMuted)),
              Text(kind.photoPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _busy
                      ? const Center(child: CircularProgressIndicator())
                      : photo == null
                          ? Icon(Icons.add_a_photo, size: 110, color: kind.color)
                          : Image.file(
                              File(photo),
                              fit: BoxFit.cover,
                              cacheWidth: 900,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image, size: 90,
                                  color: AppColors.textMuted),
                            ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // PC has no camera: only "pick a photo file" there.
                  if (PlatformInfo.hasCamera) ...[
                    Expanded(
                      child: _PhotoButton(
                        icon: Icons.photo_camera,
                        label: 'ক্যামেরা',
                        color: kind.color,
                        onTap: _busy ? null : () => _pick(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _PhotoButton(
                      icon: Icons.photo_library,
                      label: PlatformInfo.hasCamera ? 'গ্যালারি' : 'ফাইল থেকে ছবি',
                      color: kind.color,
                      onTap: _busy ? null : () => _pick(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BigButton(
                label: photo == null ? 'ছবি ছাড়া এগিয়ে যান' : 'পরের ধাপ',
                icon: Icons.arrow_forward,
                outlined: photo == null,
                color: kind.color,
                onPressed: _busy ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(backgroundColor: color),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
