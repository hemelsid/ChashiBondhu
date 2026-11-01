import 'disease_library.dart';

/// We never say "100% sure" — only বেশি (more likely) or মাঝারি (possible).
enum Likelihood {
  high('বেশি'),
  medium('মাঝারি');

  const Likelihood(this.label);

  final String label;

  static Likelihood fromKey(String? key) =>
      key == 'high' ? Likelihood.high : Likelihood.medium;
}

class DiseaseMatch {
  const DiseaseMatch({
    required this.problem,
    required this.score,
    required this.likelihood,
  });

  final DiseaseProblem problem;

  /// 0..1, internal only — never shown as a percentage.
  final double score;
  final Likelihood likelihood;
}

/// Simple, explainable symptom matching.
///
/// score = 0.65 × coverage + 0.35 × precision
///   coverage  = weight of the problem's symptoms that were ticked
///               ÷ total weight of the problem's symptoms
///   precision = ticked symptoms that belong to the problem
///               ÷ all ticked symptoms
class DiseaseMatcher {
  DiseaseMatcher._();

  static const double highAt = 0.6;
  static const double mediumAt = 0.3;

  static List<DiseaseMatch> match(
    DiseaseLibrary library,
    Set<String> selected, {
    String? cropId,
    int maxResults = 3,
  }) {
    if (selected.isEmpty) return const [];
    final matches = <DiseaseMatch>[];

    for (final p in library.problems) {
      if (cropId != null && p.crops.isNotEmpty && !p.crops.contains(cropId)) {
        continue;
      }
      final total = p.totalWeight;
      if (total <= 0) continue;
      var hitWeight = 0.0;
      var hitCount = 0;
      for (final s in selected) {
        final w = p.weights[s];
        if (w != null) {
          hitWeight += w;
          hitCount++;
        }
      }
      if (hitCount == 0) continue;
      final score = 0.65 * (hitWeight / total) + 0.35 * (hitCount / selected.length);
      if (score < mediumAt) continue;
      matches.add(DiseaseMatch(
          problem: p, score: score, likelihood: Likelihood.medium));
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    final top = matches.take(maxResults).toList();

    // Only the first one can be "বেশি", and only if it clearly leads.
    // A tie means we honestly cannot tell → all stay "মাঝারি".
    if (top.isNotEmpty) {
      final first = top.first;
      final second = top.length > 1 ? top[1].score : 0.0;
      if (first.score >= highAt && first.score - second >= leadNeeded) {
        top[0] = DiseaseMatch(
            problem: first.problem, score: first.score, likelihood: Likelihood.high);
      }
    }
    return top;
  }

  /// How far the first match must be ahead of the second to be "বেশি".
  static const double leadNeeded = 0.05;
}
