/// Sync contract. The app works fully offline; [SyncManager] is the
/// Supabase implementation and does nothing when no keys are configured.
abstract class SyncService {
  Future<void> pushPending();
}
