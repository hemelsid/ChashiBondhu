import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bangla.dart';

/// Opens the phone dialer. Shows a Bangla message if it fails.
Future<void> callNumber(BuildContext context, String number) async {
  final digits = Bn.toLatin(number).replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(Uri(scheme: 'tel', path: digits));
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger.showSnackBar(
      SnackBar(content: Text('ফোন খোলা যায়নি। নম্বর: ${Bn.digits(digits)}')),
    );
  }
}
