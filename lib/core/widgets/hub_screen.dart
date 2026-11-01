import 'package:flutter/material.dart';

class HubOption {
  const HubOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.builder,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}

/// A screen with 2–4 big full-width choices. Used by Home cards that hold
/// more than one job (e.g. আবহাওয়া ও বাজার দর, রোগ চেক, ডায়েরি).
class HubScreen extends StatelessWidget {
  const HubScreen({
    super.key,
    required this.title,
    required this.color,
    required this.options,
  });

  final String title;
  final Color color;
  final List<HubOption> options;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                Expanded(child: _HubCard(option: options[i])),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.option});

  final HubOption option;

  @override
  Widget build(BuildContext context) {
    final sub = option.subtitle;
    return Material(
      color: option.color,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: option.builder)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Icon(option.icon, size: 60, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    if (sub != null)
                      Text(sub,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 40, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
