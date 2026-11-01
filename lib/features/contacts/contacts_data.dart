import 'dart:convert';

/// One phone line (helpline, officer, or the farmer's own saved number).
class PhoneContact {
  const PhoneContact({
    required this.id,
    required this.name,
    required this.phone,
    this.role = '',
    this.desc = '',
    this.districtId,
    this.upazila = '',
    this.source = '',
    this.mine = false,
  });

  final String id;
  final String name;
  final String phone;

  /// পদবি / কাজ, e.g. "উপজেলা মৎস্য কর্মকর্তা".
  final String role;
  final String desc;
  final String? districtId;
  final String upazila;

  /// Where the number was checked (for data from GitHub).
  final String source;

  /// Saved by the farmer on this device.
  final bool mine;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        'desc': desc,
        'districtId': districtId,
        'upazila': upazila,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

  factory PhoneContact.fromMap(Map<dynamic, dynamic> m, {bool mine = false}) => PhoneContact(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        phone: (m['phone'] ?? m['number'] ?? '').toString(),
        role: (m['role'] ?? m['designation'] ?? '').toString(),
        desc: (m['desc'] ?? '').toString(),
        districtId: (m['districtId'] ?? m['district_id']) as String?,
        upazila: (m['upazila'] ?? '').toString(),
        source: (m['source'] ?? '').toString(),
        mine: mine,
      );
}

enum OrgType {
  govt('সরকারি প্রতিষ্ঠান'),
  research('গবেষণা প্রতিষ্ঠান'),
  ngo('এনজিও ও উন্নয়ন সংস্থা');

  const OrgType(this.label);

  final String label;

  static OrgType fromKey(String? k) =>
      values.firstWhere((t) => t.name == k, orElse: () => OrgType.govt);
}

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.type,
    this.desc = '',
    this.website = '',
    this.phone = '',
  });

  final String id;
  final String name;
  final OrgType type;
  final String desc;
  final String website;
  final String phone;

  factory Organization.fromMap(Map<dynamic, dynamic> m) => Organization(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        type: OrgType.fromKey(m['type'] as String?),
        desc: (m['desc'] ?? '').toString(),
        website: (m['website'] ?? '').toString(),
        phone: (m['phone'] ?? '').toString(),
      );
}

/// Officer numbers added to the shared data file, by district.
class OfficerContact {
  const OfficerContact({required this.office, required this.contact});

  /// fisheries | dae | dls
  final String office;
  final PhoneContact contact;
}

class ContactsData {
  const ContactsData({
    required this.updated,
    required this.helplines,
    required this.organizations,
    required this.officers,
  });

  final String updated;
  final List<PhoneContact> helplines;
  final List<Organization> organizations;
  final List<OfficerContact> officers;

  static ContactsData parse(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    List<dynamic> list(String k) => (j[k] as List<dynamic>?) ?? const [];
    return ContactsData(
      updated: (j['updated'] ?? '').toString(),
      helplines: [
        for (final h in list('helplines'))
          if (h is Map) PhoneContact.fromMap(h),
      ],
      organizations: [
        for (final o in list('organizations'))
          if (o is Map) Organization.fromMap(o),
      ],
      officers: [
        for (final o in list('officers'))
          if (o is Map)
            OfficerContact(office: (o['office'] ?? '').toString(), contact: PhoneContact.fromMap(o)),
      ],
    );
  }

  /// Accept a downloaded file only if it parses and has the helplines.
  static bool isValid(String text) {
    try {
      final d = parse(text);
      final digits = RegExp(r'^[0-9+ ]{3,16}$');
      return d.helplines.isNotEmpty &&
          d.helplines.every((h) => h.name.isNotEmpty && digits.hasMatch(h.phone)) &&
          d.officers.every((o) => digits.hasMatch(o.contact.phone));
    } catch (_) {
      return false;
    }
  }
}

/// District government office websites (জাতীয় তথ্য বাতায়ন). Each office
/// lists its officers with their official mobile numbers.
class DistrictOffices {
  DistrictOffices._();

  /// The portal still uses older English spellings for some districts.
  static const _portalSlug = {
    'chattogram': 'chittagong',
    'bogura': 'bogra',
    'jashore': 'jessore',
    'barishal': 'barisal',
    'cumilla': 'comilla',
    'jhalokathi': 'jhalakathi',
  };

  static String slug(String districtId) => _portalSlug[districtId] ?? districtId;

  static const offices = [
    ('fisheries', 'জেলা মৎস্য অফিস', 'মাছ চাষ, পোনা, রোগ'),
    ('dae', 'জেলা কৃষি অফিস (কৃষি সম্প্রসারণ)', 'ফসল, বীজ, সার, পোকা-রোগ'),
    ('dls', 'জেলা প্রাণিসম্পদ অফিস', 'গবাদিপশু, হাঁস-মুরগি, ভেট'),
  ];

  static String website(String office, String districtId) =>
      'https://$office.${slug(districtId)}.gov.bd';
}
