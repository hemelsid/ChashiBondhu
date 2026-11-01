import 'package:flutter/material.dart';

import '../../core/data/bd_districts.dart';
import '../../core/storage/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import '../../core/utils/phone_call.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/section_title.dart';
import '../weather/district_picker_screen.dart';
import 'contact_form_screen.dart';
import 'contacts_data.dart';
import 'contacts_repository.dart';

/// সাহায্য ও যোগাযোগ — helplines, your district's offices, officers,
/// organisations, and numbers you saved yourself.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ContactsRepository.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('সাহায্য ও যোগাযোগ')),
      body: AnimatedBuilder(
        animation: repo.changes,
        builder: (context, _) => FutureBuilder<ContactsData>(
          future: repo.directory(),
          builder: (context, snap) {
            final data = snap.data;
            if (data == null) return const Center(child: CircularProgressIndicator());
            return _Body(data: data, mine: repo.mine());
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.mine});

  final ContactsData data;
  final List<PhoneContact> mine;

  @override
  Widget build(BuildContext context) {
    final district = districtById(AppSettings.districtId);
    final upazila = AppSettings.upazila;
    final officers = <OfficerContact>[
      if (district != null)
        ...data.officers.where((o) => o.contact.districtId == district.id),
    ];
    // Same upazila first.
    int rank(OfficerContact o) => upazila.isNotEmpty && o.contact.upazila == upazila ? 0 : 1;
    officers.sort((a, b) => rank(a).compareTo(rank(b)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // ---- Helplines ----
        const SectionTitle('হেল্পলাইন (বিনা খরচে বা কম খরচে)', icon: Icons.call),
        for (final h in data.helplines) _CallCard(contact: h, color: AppColors.primary),

        // ---- Area ----
        const SectionTitle('আপনার এলাকার অফিস', icon: Icons.place),
        Row(
          children: [
            Expanded(
              child: Text(
                district == null
                    ? 'এলাকা বাছা হয়নি'
                    : (upazila.isEmpty ? district.name : '$upazila, ${district.name}'),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 48,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const DistrictPickerScreen())),
                child: Text(district == null ? 'এলাকা বাছুন' : 'বদলান'),
              ),
            ),
          ],
        ),
        if (district != null) ...[
          for (final o in officers)
            _CallCard(contact: o.contact, color: AppColors.cardPond, showSource: true),
          if (officers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'এই জেলার অফিসারদের নম্বর এখনো তালিকায় নেই। নিচের অফিসের ওয়েবসাইটে '
                '"কর্মকর্তাবৃন্দ" অংশে সরকারি মোবাইল নম্বর পাবেন — পেলে "আমার নম্বর"-এ রেখে দিন।',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
            ),
          for (final (office, label, desc) in DistrictOffices.offices)
            _LinkCard(
              icon: office == 'fisheries'
                  ? Icons.set_meal
                  : office == 'dae'
                      ? Icons.spa
                      : Icons.pets,
              title: '$label, ${district.name}',
              subtitle: desc,
              url: DistrictOffices.website(office, district.id),
            ),
        ],

        // ---- Own numbers ----
        const SectionTitle('আমার নম্বর', icon: Icons.contacts),
        if (mine.isEmpty)
          const Text('উপজেলা মৎস্য/কৃষি কর্মকর্তা, ভেট বা দোকানের নম্বর এখানে রাখুন।',
              style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
        for (final c in mine) _CallCard(contact: c, color: AppColors.cardDiary, editable: true),
        const SizedBox(height: 8),
        BigButton(
          label: 'নতুন নম্বর যোগ করুন',
          icon: Icons.person_add,
          outlined: true,
          color: AppColors.cardDiary,
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ContactFormScreen())),
        ),

        // ---- Organisations ----
        for (final type in OrgType.values) ...[
          SectionTitle(type.label,
              icon: type == OrgType.ngo ? Icons.volunteer_activism : Icons.account_balance),
          for (final o in data.organizations.where((o) => o.type == type))
            _LinkCard(
              icon: type == OrgType.research ? Icons.science : Icons.account_balance,
              title: o.name,
              subtitle: o.desc,
              url: o.website,
              phone: o.phone,
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'তালিকা হালনাগাদ: ${data.updated.isEmpty ? '—' : Bn.digits(data.updated)} · '
          'ইন্টারনেট থাকলে নিজে থেকে নতুন তথ্য আসে।',
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({
    required this.contact,
    required this.color,
    this.editable = false,
    this.showSource = false,
  });

  final PhoneContact contact;
  final Color color;
  final bool editable;
  final bool showSource;

  Future<void> _menu(BuildContext context) async {
    final ok = await confirmDialog(context,
        title: 'নম্বর মুছবেন?', message: contact.name, confirmLabel: 'হ্যাঁ, মুছুন');
    if (ok) await ContactsRepository.instance.delete(contact.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = contact;
    final sub = [
      if (c.role.isNotEmpty && c.role != c.name) c.role,
      if (c.desc.isNotEmpty) c.desc,
      if (c.upazila.isNotEmpty) c.upazila,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: editable && !c.id.startsWith('_')
              ? () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ContactFormScreen(existing: c)))
              : null,
          onLongPress: editable ? () => _menu(context) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      if (sub.isNotEmpty)
                        Text(sub, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
                      Text(Bn.digits(c.phone),
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                      if (showSource && c.source.isNotEmpty)
                        Text('সূত্র: ${c.source}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 64,
                  height: 64,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: color, padding: EdgeInsets.zero),
                    onPressed: () => callNumber(context, c.phone),
                    child: const Icon(Icons.call, size: 32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    this.phone = '',
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: url.isEmpty ? null : () => openLink(context, url),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 34, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
                      if (url.isNotEmpty)
                        const Text('ওয়েবসাইট খুলুন ›',
                            style: TextStyle(fontSize: 15, color: AppColors.primary)),
                    ],
                  ),
                ),
                if (phone.isNotEmpty)
                  IconButton(
                    iconSize: 32,
                    onPressed: () => callNumber(context, phone),
                    icon: const Icon(Icons.call, color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
