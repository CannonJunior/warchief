import '../data/abilities/ability_types.dart';
import '../state/cc_config.dart';

/// Tracks recent CC applications per target per DR category.
///
/// Within the DR window (default 18s), successive CC of the same category
/// has reduced duration: 100% → 50% → 25% → immune. The counter resets
/// after the window expires with no new application.
///
/// Categories share DR across their member effects (e.g. stun/knockdown/airborne
/// all share the "stun" DR category).
class CcDiminishingReturns {
  CcDiminishingReturns._();

  /// Key: targetId → (drCategory → _DrTracker)
  static final Map<int, Map<String, _DrTracker>> _trackers = {};

  /// Returns the duration multiplier for applying [effect] to [targetId].
  /// Also advances the DR counter for that category.
  static double applyAndGetMultiplier(int targetId, StatusEffect effect) {
    final cfg = globalCcConfig;
    if (cfg == null || !cfg.drEnabled) return 1.0;

    final category = _categoryFor(effect, cfg);
    if (category == null) return 1.0;

    final targetTrackers = _trackers.putIfAbsent(targetId, () => {});
    final tracker = targetTrackers.putIfAbsent(category, () => _DrTracker());

    final reductions = cfg.drReductions;
    final window = cfg.drWindow;

    // Reason: if the DR window has expired since the last application,
    // reset the counter so the next CC lands at full duration.
    if (tracker.lastApplyTime > 0 &&
        _now() - tracker.lastApplyTime > window) {
      tracker.count = 0;
    }

    final idx = tracker.count.clamp(0, reductions.length - 1);
    final mult = reductions[idx];

    tracker.count++;
    tracker.lastApplyTime = _now();

    return mult;
  }

  /// Returns the DR category name for [effect], or null if the effect
  /// is not subject to diminishing returns.
  static String? _categoryFor(StatusEffect effect, CcConfig cfg) {
    final effectName = effect.name;
    for (final entry in cfg.drCategories.entries) {
      if (entry.value.contains(effectName)) return entry.key;
    }
    return null;
  }

  /// Clear all DR state (e.g. on duel reset or zone change).
  static void reset() {
    _trackers.clear();
  }

  /// Clear DR state for a specific target.
  static void resetTarget(int targetId) {
    _trackers.remove(targetId);
  }

  /// Monotonic time source — seconds since epoch, adequate for window comparison.
  static double _now() =>
      DateTime.now().millisecondsSinceEpoch / 1000.0;
}

class _DrTracker {
  int count = 0;
  double lastApplyTime = 0.0;
}
