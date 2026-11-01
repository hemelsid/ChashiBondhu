import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

/// Above this window width the app is shown as a centered column.
const double kWideLayoutFrom = 760;
const double kMaxContentWidth = 720;

class ChashibondhuApp extends StatelessWidget {
  const ChashibondhuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'চাষিবন্ধু',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Bangla everywhere, including the date picker.
      locale: const Locale('bn', 'BD'),
      supportedLocales: const [Locale('bn', 'BD')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Respect large system fonts, but cap them so big cards don't break.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        Widget page = MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
          ),
          child: child ?? const SizedBox.shrink(),
        );
        // PC / wide screen: keep the same big, simple phone layout in a
        // centered column instead of stretching buttons across the window.
        if (mq.size.width > kWideLayoutFrom) {
          page = ColoredBox(
            color: const Color(0xFFDDE5D8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: Material(elevation: 6, child: page),
              ),
            ),
          );
        }
        return page;
      },
      home: const HomeScreen(),
    );
  }
}
