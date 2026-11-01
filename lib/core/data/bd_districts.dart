/// 64 districts of Bangladesh with approximate district-town coordinates
/// (enough for a weather forecast). Grouped by division for easy picking.
class District {
  const District(this.id, this.name, this.division, this.lat, this.lon);

  final String id;
  final String name;
  final String division;
  final double lat;
  final double lon;
}

const List<String> kDivisions = [
  'ঢাকা', 'চট্টগ্রাম', 'রাজশাহী', 'খুলনা',
  'বরিশাল', 'সিলেট', 'রংপুর', 'ময়মনসিংহ',
];

const List<District> kDistricts = [
  // ঢাকা
  District('dhaka', 'ঢাকা', 'ঢাকা', 23.81, 90.41),
  District('gazipur', 'গাজীপুর', 'ঢাকা', 24.00, 90.42),
  District('narayanganj', 'নারায়ণগঞ্জ', 'ঢাকা', 23.62, 90.50),
  District('narsingdi', 'নরসিংদী', 'ঢাকা', 23.93, 90.72),
  District('manikganj', 'মানিকগঞ্জ', 'ঢাকা', 23.86, 90.00),
  District('munshiganj', 'মুন্সিগঞ্জ', 'ঢাকা', 23.54, 90.53),
  District('tangail', 'টাঙ্গাইল', 'ঢাকা', 24.25, 89.92),
  District('kishoreganj', 'কিশোরগঞ্জ', 'ঢাকা', 24.44, 90.78),
  District('gopalganj', 'গোপালগঞ্জ', 'ঢাকা', 23.01, 89.83),
  District('faridpur', 'ফরিদপুর', 'ঢাকা', 23.61, 89.84),
  District('madaripur', 'মাদারীপুর', 'ঢাকা', 23.17, 90.20),
  District('rajbari', 'রাজবাড়ী', 'ঢাকা', 23.76, 89.64),
  District('shariatpur', 'শরীয়তপুর', 'ঢাকা', 23.21, 90.35),
  // চট্টগ্রাম
  District('chattogram', 'চট্টগ্রাম', 'চট্টগ্রাম', 22.36, 91.78),
  District('coxsbazar', 'কক্সবাজার', 'চট্টগ্রাম', 21.43, 92.01),
  District('cumilla', 'কুমিল্লা', 'চট্টগ্রাম', 23.46, 91.18),
  District('feni', 'ফেনী', 'চট্টগ্রাম', 23.02, 91.40),
  District('noakhali', 'নোয়াখালী', 'চট্টগ্রাম', 22.87, 91.10),
  District('lakshmipur', 'লক্ষ্মীপুর', 'চট্টগ্রাম', 22.94, 90.83),
  District('chandpur', 'চাঁদপুর', 'চট্টগ্রাম', 23.23, 90.67),
  District('brahmanbaria', 'ব্রাহ্মণবাড়িয়া', 'চট্টগ্রাম', 23.96, 91.11),
  District('rangamati', 'রাঙ্গামাটি', 'চট্টগ্রাম', 22.65, 92.18),
  District('khagrachhari', 'খাগড়াছড়ি', 'চট্টগ্রাম', 23.12, 91.98),
  District('bandarban', 'বান্দরবান', 'চট্টগ্রাম', 22.20, 92.22),
  // রাজশাহী
  District('rajshahi', 'রাজশাহী', 'রাজশাহী', 24.37, 88.60),
  District('natore', 'নাটোর', 'রাজশাহী', 24.42, 89.00),
  District('naogaon', 'নওগাঁ', 'রাজশাহী', 24.81, 88.94),
  District('chapainawabganj', 'চাঁপাইনবাবগঞ্জ', 'রাজশাহী', 24.60, 88.27),
  District('pabna', 'পাবনা', 'রাজশাহী', 24.01, 89.24),
  District('sirajganj', 'সিরাজগঞ্জ', 'রাজশাহী', 24.45, 89.70),
  District('bogura', 'বগুড়া', 'রাজশাহী', 24.85, 89.37),
  District('joypurhat', 'জয়পুরহাট', 'রাজশাহী', 25.10, 89.02),
  // খুলনা
  District('khulna', 'খুলনা', 'খুলনা', 22.82, 89.55),
  District('bagerhat', 'বাগেরহাট', 'খুলনা', 22.65, 89.79),
  District('satkhira', 'সাতক্ষীরা', 'খুলনা', 22.72, 89.07),
  District('jashore', 'যশোর', 'খুলনা', 23.17, 89.21),
  District('jhenaidah', 'ঝিনাইদহ', 'খুলনা', 23.54, 89.15),
  District('magura', 'মাগুরা', 'খুলনা', 23.49, 89.42),
  District('narail', 'নড়াইল', 'খুলনা', 23.17, 89.51),
  District('kushtia', 'কুষ্টিয়া', 'খুলনা', 23.90, 89.12),
  District('chuadanga', 'চুয়াডাঙ্গা', 'খুলনা', 23.64, 88.84),
  District('meherpur', 'মেহেরপুর', 'খুলনা', 23.77, 88.63),
  // বরিশাল
  District('barishal', 'বরিশাল', 'বরিশাল', 22.70, 90.37),
  District('patuakhali', 'পটুয়াখালী', 'বরিশাল', 22.36, 90.33),
  District('bhola', 'ভোলা', 'বরিশাল', 22.69, 90.65),
  District('pirojpur', 'পিরোজপুর', 'বরিশাল', 22.58, 89.97),
  District('barguna', 'বরগুনা', 'বরিশাল', 22.15, 90.12),
  District('jhalokathi', 'ঝালকাঠি', 'বরিশাল', 22.64, 90.20),
  // সিলেট
  District('sylhet', 'সিলেট', 'সিলেট', 24.90, 91.87),
  District('moulvibazar', 'মৌলভীবাজার', 'সিলেট', 24.48, 91.78),
  District('habiganj', 'হবিগঞ্জ', 'সিলেট', 24.37, 91.42),
  District('sunamganj', 'সুনামগঞ্জ', 'সিলেট', 25.07, 91.40),
  // রংপুর
  District('rangpur', 'রংপুর', 'রংপুর', 25.74, 89.25),
  District('dinajpur', 'দিনাজপুর', 'রংপুর', 25.63, 88.64),
  District('gaibandha', 'গাইবান্ধা', 'রংপুর', 25.33, 89.53),
  District('kurigram', 'কুড়িগ্রাম', 'রংপুর', 25.81, 89.64),
  District('lalmonirhat', 'লালমনিরহাট', 'রংপুর', 25.91, 89.45),
  District('nilphamari', 'নীলফামারী', 'রংপুর', 25.93, 88.86),
  District('panchagarh', 'পঞ্চগড়', 'রংপুর', 26.33, 88.55),
  District('thakurgaon', 'ঠাকুরগাঁও', 'রংপুর', 26.03, 88.46),
  // ময়মনসিংহ
  District('mymensingh', 'ময়মনসিংহ', 'ময়মনসিংহ', 24.75, 90.41),
  District('jamalpur', 'জামালপুর', 'ময়মনসিংহ', 24.92, 89.95),
  District('netrokona', 'নেত্রকোণা', 'ময়মনসিংহ', 24.88, 90.73),
  District('sherpur', 'শেরপুর', 'ময়মনসিংহ', 25.02, 90.02),
];

District? districtById(String? id) {
  for (final d in kDistricts) {
    if (d.id == id) return d;
  }
  return null;
}
