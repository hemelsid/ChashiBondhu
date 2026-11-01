/// Supabase keys come from the build command, never from the code:
///
///   flutter build apk --release \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// Without them the app simply stays offline-only.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get enabled => url.isNotEmpty && anonKey.isNotEmpty;

  /// Storage bucket for report photos.
  static const photoBucket = 'report-photos';
}
