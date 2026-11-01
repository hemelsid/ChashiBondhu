import 'package:flutter/material.dart';

import '../../core/remote/remote_data.dart';
import '../../core/theme/app_colors.dart';
import '../briefing/briefing_screen.dart';
import '../contacts/contacts_screen.dart';
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
              const SizedBox(height: 8),
              // Rotating headlines / weather / this month's work.
              const HeadlineTicker(),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset('assets/images/logo.png', width: 56, height: 56),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('চাষিবন্ধু',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1.1)),
              ),
              _OnlineChip(),
            ],
          ),
        ),
        _HeaderButton(
          tooltip: 'সাহায্য ও যোগাযোগ',
          icon: Icons.support_agent,
          page: ContactsScreen(),
        ),
        _HeaderButton(tooltip: 'সেটিংস', icon: Icons.settings, page: SettingsScreen()),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.tooltip, required this.icon, required this.page});

  final String tooltip;
  final IconData icon;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 56,
      child: IconButton(
        tooltip: tooltip,
        iconSize: 32,
        color: AppColors.textMuted,
        icon: Icon(icon),
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }
}

/// "● অনলাইন" / "● অফলাইন — সব কাজ চলবে". Tap to look for new data.
class _OnlineChip extends StatelessWidget {
  const _OnlineChip();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OnlineState>(
      valueListenable: RemoteData.state,
      builder: (context, state, _) {
        final (Color dot, String text) = switch (state) {
          OnlineState.online => (AppColors.ok, 'অনলাইন · তথ্য হালনাগাদ'),
          OnlineState.checking => (AppColors.warn, 'হালনাগাদ খোঁজা হচ্ছে…'),
          OnlineState.offline => (AppColors.textMuted, 'অফলাইন · সব কাজ চলবে'),
          OnlineState.unknown => (AppColors.textMuted, 'চাষির পাশে, সব সময়'),
        };
        return InkWell(
          onTap: () => RemoteData.refresh(force: true),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state != OnlineState.unknown) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        );
      },
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
