import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/hub_screen.dart';
import '../biosecurity/biosecurity_screen.dart';
import '../briefing/briefing_screen.dart';
import '../disease/common/report_list.dart';
import '../disease/crop/crop_check_start_screen.dart';
import '../disease/fish/fish_check_start_screen.dart';
import '../feed/feed_screen.dart';
import '../market/market_screen.dart';
import '../pond/ui/pond_list_screen.dart';
import '../reminders/reminder_list_screen.dart';
import '../water/water_check_screen.dart';
import '../weather/weather_screen.dart';

/// One card on the Home screen.
class HomeFeature {
  const HomeFeature({
    required this.label,
    required this.icon,
    required this.color,
    required this.builder,
    this.ready = true,
  });

  final String label;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  /// false = shows "শীঘ্রই আসছে" badge.
  final bool ready;
}

/// The Home screen shows exactly these 6 cards (design rule: max 6).
/// Cards with more than one job open a [HubScreen] of 2–4 big choices.
final List<HomeFeature> homeFeatures = [
  HomeFeature(
    label: 'আমার পুকুর',
    icon: Icons.water,
    color: AppColors.cardPond,
    builder: (_) => const PondListScreen(),
  ),
  HomeFeature(
    label: 'খাবার হিসাব',
    icon: Icons.calculate,
    color: AppColors.cardFeed,
    builder: (_) => const FeedScreen(),
  ),
  HomeFeature(
    label: 'পানি চেক',
    icon: Icons.water_drop,
    color: AppColors.cardWater,
    builder: (_) => const WaterCheckScreen(),
  ),
  HomeFeature(
    label: 'আবহাওয়া ও বাজার দর',
    icon: Icons.wb_sunny,
    color: AppColors.cardWeather,
    builder: (_) => HubScreen(
      title: 'আবহাওয়া ও বাজার দর',
      color: AppColors.cardWeather,
      options: [
        HubOption(
          label: 'আবহাওয়া',
          subtitle: 'আগামী ৩ দিন',
          icon: Icons.wb_sunny,
          color: const Color(0xFF5E35B1),
          builder: (_) => const WeatherScreen(),
        ),
        HubOption(
          label: 'বাজার দর',
          subtitle: 'মাছ, ধান, আলু, পেঁয়াজ',
          icon: Icons.storefront,
          color: const Color(0xFF00897B),
          builder: (_) => const MarketScreen(),
        ),
        HubOption(
          label: 'খবর ও তথ্য',
          subtitle: 'কৃষি খবর, এই মাসের কাজ',
          icon: Icons.newspaper,
          color: const Color(0xFF3949AB),
          builder: (_) => const BriefingScreen(),
        ),
      ],
    ),
  ),
  HomeFeature(
    label: 'রোগ চেক',
    icon: Icons.healing,
    color: AppColors.cardDisease,
    builder: (_) => HubScreen(
      title: 'রোগ চেক',
      color: AppColors.cardDisease,
      options: [
        HubOption(
          label: 'মাছের রোগ',
          subtitle: 'পুকুরবন্ধু — ছবি ও লক্ষণ',
          icon: Icons.set_meal,
          color: const Color(0xFF00796B),
          builder: (_) => const FishCheckStartScreen(),
        ),
        HubOption(
          label: 'ফসলের রোগ',
          subtitle: 'ধান, আলু, সবজি',
          icon: Icons.spa,
          color: const Color(0xFF558B2F),
          builder: (_) => const CropCheckStartScreen(),
        ),
        HubOption(
          label: 'আগের রিপোর্ট',
          icon: Icons.history,
          color: const Color(0xFF6D4C41),
          builder: (_) => const ReportListScreen(),
        ),
      ],
    ),
  ),
  HomeFeature(
    label: 'ডায়েরি',
    icon: Icons.menu_book,
    color: AppColors.cardDiary,
    builder: (_) => HubScreen(
      title: 'ডায়েরি',
      color: AppColors.cardDiary,
      options: [
        HubOption(
          label: 'রিমাইন্ডার',
          subtitle: 'খাবার, চুন, জাল টানা, মাছ ধরা',
          icon: Icons.alarm,
          color: const Color(0xFFE65100),
          builder: (_) => const ReminderListScreen(),
        ),
        HubOption(
          label: 'জীবাণু-নিরাপত্তা',
          subtitle: 'সাপ্তাহিক চেকলিস্ট',
          icon: Icons.verified_user,
          color: const Color(0xFF2E7D32),
          builder: (_) => const BiosecurityScreen(),
        ),
        HubOption(
          label: 'রোগ চেকের রিপোর্ট',
          icon: Icons.healing,
          color: const Color(0xFFAD1457),
          builder: (_) => const ReportListScreen(),
        ),
        HubOption(
          label: 'পুকুরের হিসাব',
          icon: Icons.water,
          color: AppColors.cardPond,
          builder: (_) => const PondListScreen(),
        ),
      ],
    ),
  ),
];
