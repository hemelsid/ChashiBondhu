/// Traffic-light signal used everywhere in the app.
///   ok     = সবুজ  = ঠিক আছে
///   warn   = হলুদ  = সতর্ক
///   danger = লাল   = বিপদ
/// Order matters: a higher index is worse.
enum Signal {
  ok,
  warn,
  danger;

  /// The worst signal in the list (empty list = ok).
  static Signal worst(Iterable<Signal> signals) {
    var result = Signal.ok;
    for (final s in signals) {
      if (s.index > result.index) result = s;
    }
    return result;
  }
}
