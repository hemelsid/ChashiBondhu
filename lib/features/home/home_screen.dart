import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../settings/settings_screen.dart';
import '../smart/smart_screen.dart';
import 'home_features.dart';

/// 6 big cards in a 2 × 3 grid that always fits the screen (no scrolling),
/// so every card is reachable with one thumb.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    assert(homeFeatures.length == 6, 'Home must have exactly 6 cards');
    const gap = 12.0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            children: [
              const _Header(),
              const SizedBox(height: 10),
              // Smart alerts strip (not a 7th card): opens "আজকের কাজ".
              const SmartBanner(),
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  children: [
                    for (var row = 0; row < 3; row++) ...[
                      if (row > 0) const SizedBox(height: gap),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _HomeCard(feature: homeFeatures[row * 2])),
                            const SizedBox(width: gap),
                            Expanded(child: _HomeCard(feature: homeFeatures[row * 2 + 1])),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.agriculture, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('চাষিবন্ধু',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1.1)),
              Text('চাষির পাশে, সব সময়',
                  style: TextStyle(fontSize: 17, color: AppColors.textMuted)),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          height: 60,
          child: IconButton(
            tooltip: 'সেটিংস',
            iconSize: 34,
            color: AppColors.textMuted,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ),
      ],
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.feature});

  final HomeFeature feature;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: feature.color,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: feature.builder)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: FittedBox(
                    child: Icon(feature.icon, color: Colors.white),
                  ),
                ),
              ),
              Text(
                feature.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (!feature.ready)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('শীঘ্রই আসছে',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: feature.color)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
