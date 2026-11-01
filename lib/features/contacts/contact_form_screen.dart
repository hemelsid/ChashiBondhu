import 'package:flutter/material.dart';

import '../../core/data/bd_districts.dart';
import '../../core/storage/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/choice_grid.dart';
import '../../core/widgets/section_title.dart';
import 'contacts_data.dart';
import 'contacts_repository.dart';

/// Save a number by hand (officer, vet, shop …).
class ContactFormScreen extends StatefulWidget {
  const ContactFormScreen({super.key, this.existing});

  final PhoneContact? existing;

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  static const roles = [
    ('উপজেলা মৎস্য কর্মকর্তা', Icons.set_meal),
    ('উপজেলা কৃষি কর্মকর্তা', Icons.spa),
    ('উপসহকারী কৃষি কর্মকর্তা', Icons.agriculture),
    ('প্রাণিসম্পদ কর্মকর্তা / ভেট', Icons.pets),
    ('এনজিও কর্মী', Icons.volunteer_activism),
    ('খাবার / ওষুধের দোকান', Icons.storefront),
    ('পোনা / বীজ বিক্রেতা', Icons.local_shipping),
    ('অন্য', Icons.person),
  ];

  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late String? _role = widget.existing?.role;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = Bn.toLatin(_phone.text).replaceAll(RegExp(r'[^0-9+]'), '');
    final name = _name.text.trim().isEmpty ? (_role ?? '') : _name.text.trim();
    String? error;
    if (_role == null) {
      error = 'কার নম্বর, বেছে নিন।';
    } else if (phone.length < 3) {
      error = 'মোবাইল নম্বর লিখুন।';
    }
    setState(() => _error = error);
    if (error != null) return;
    await ContactsRepository.instance.save(PhoneContact(
      id: widget.existing?.id ?? newId(),
      name: name,
      role: _role!,
      phone: phone,
      districtId: AppSettings.districtId,
      upazila: AppSettings.upazila,
      mine: true,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('নম্বর রাখা হয়েছে ✓')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final district = districtById(AppSettings.districtId);
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'নতুন নম্বর' : 'নম্বর বদলান')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionTitle('কার নম্বর?', icon: Icons.badge),
          ChoiceGrid<String>(
            columns: 2,
            tileHeight: 96,
            options: [
              for (final (label, icon) in roles)
                ChoiceOption(value: label, label: label, icon: icon),
            ],
            selected: _role,
            onSelected: (r) => setState(() => _role = r),
          ),
          const SectionTitle('নাম (না লিখলেও চলবে)', icon: Icons.person),
          TextField(
            controller: _name,
            style: const TextStyle(fontSize: 21),
            decoration: const InputDecoration(hintText: 'যেমন: রহিম সাহেব'),
          ),
          const SectionTitle('মোবাইল নম্বর', icon: Icons.phone),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: '০১৭০০০০০০০০'),
          ),
          if (district != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('এলাকা: ${district.name}',
                  style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(error,
                  style: const TextStyle(
                      fontSize: 18, color: AppColors.danger, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 24),
          BigButton(label: 'সংরক্ষণ করুন', icon: Icons.check, onPressed: _save),
        ],
      ),
    );
  }
}
