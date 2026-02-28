import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/duel_result.dart';
import '../../models/ally.dart';
import '../data/abilities/ability_types.dart' show AbilityData;
import 'duel_config.dart';

// ==================== STRATEGY ENUM ====================

/// AI behaviour profile applied to an entire duel side.
enum DuelStrategy { aggressive, defensive, balanced, support, berserker }

/// Human-readable labels for every DuelStrategy.
const Map<DuelStrategy, String> duelStrategyLabels = {
  DuelStrategy.aggressive: 'Aggressive',
  DuelStrategy.defensive:  'Defensive',
  DuelStrategy.balanced:   'Balanced',
  DuelStrategy.support:    'Support',
  DuelStrategy.berserker:  'Berserker',
};

// ==================== SETUP CONFIG ====================

/// Immutable snapshot of a Setup-tab configuration, passed from DuelPanel to
/// the _startDuel command handler so that manager.reset() does not clobber it.
class DuelSetupConfig {
  final List<String>      challengerClasses;
  final List<String>      enemyTypes;
  final List<int>         challengerGearTiers;
  final List<int>         enemyGearTiers;
  final DuelStrategy      challengerStrategy;
  final DuelStrategy      enemyStrategy;
  final DuelEndCondition  endCondition;

  const DuelSetupConfig({
    required this.challengerClasses,
    required this.enemyTypes,
    required this.challengerGearTiers,
    required this.enemyGearTiers,
    required this.challengerStrategy,
    required this.enemyStrategy,
    required this.endCondition,
  });
}

// ==================== STATE MACHINE ====================

/// State machine phases for a duel.
enum DuelPhase { idle, active, completed }

/// Manages duel state, event recording, and SharedPreferences persistence.
///
/// Instantiated once in game3d_widget_init.dart and stored on GameState.
class DuelManager {
  DuelPhase phase = DuelPhase.idle;

  // ── Setup snapshot (written by _startDuel, read by DuelSystem + Active tab) ─

  /// First challenger class for display in history + Active tab.
  String? selectedChallengerClass;

  /// First enemy type for display in history + Active tab.
  String? selectedEnemyType;

  int challengerPartySize = 1;
  int enemyPartySize      = 1;

  List<String> challengerPartyClasses = [];
  List<String> enemyPartyTypes        = [];
  List<int>    challengerGearTiers    = [];
  List<int>    enemyGearTiers         = [];

  DuelStrategy      challengerStrategy = DuelStrategy.balanced;
  DuelStrategy      enemyStrategy      = DuelStrategy.balanced;
  DuelEndCondition  endCondition       = DuelEndCondition.totalAnnihilation;

  double elapsedSeconds = 0.0;

  // ── Ability lists (one list per combatant) ─────────────────────────────────

  /// Per-combatant ability lists for the challenger party.
  List<List<AbilityData>> challengerPartyAbilities = [];

  /// Per-combatant ability lists for the enemy party.
  List<List<AbilityData>> enemyPartyAbilities = [];

  // ── Hot-path caches (set once at duel start, read every frame by DuelSystem) ─

  /// Reason: avoids sublist() allocation in DuelSystem.update() every frame.
  List<Ally> challengerParty = const [];
  List<Ally> enemyParty      = const [];

  /// Reason: pre-computed so DuelSystem._runAI() needs no config lookup per ability use.
  List<double> challengerDamageMults = const [];
  List<double> enemyDamageMults      = const [];

  // ── Global cooldown + combo-window timers ──────────────────────────────────

  /// Per-combatant GCD timers: indices 0..chalSize-1 are challengers,
  /// chalSize..total-1 are enemies. Counts down to 0 each frame.
  List<double> combatantGcds = [];

  /// Per-combatant combo-window timers. Non-zero means the combatant fired a
  /// combo-primer ability and the next ability may bypass the GCD.
  List<double> combatantComboWindows = [];

  /// Highest GCD remaining across all challenger combatants (0 when ready).
  double get challengerMaxGcd {
    if (combatantGcds.isEmpty || challengerPartySize == 0) return 0.0;
    double m = 0.0;
    for (int i = 0; i < challengerPartySize && i < combatantGcds.length; i++) {
      if (combatantGcds[i] > m) m = combatantGcds[i];
    }
    return m;
  }

  /// Highest GCD remaining across all enemy combatants (0 when ready).
  double get enemyMaxGcd {
    if (combatantGcds.isEmpty) return 0.0;
    double m = 0.0;
    for (int i = challengerPartySize; i < combatantGcds.length; i++) {
      if (combatantGcds[i] > m) m = combatantGcds[i];
    }
    return m;
  }

  // ── Legacy single-combatant accessors (DuelSystem fallback) ───────────────

  List<AbilityData> get challengerAbilities =>
      challengerPartyAbilities.isNotEmpty ? challengerPartyAbilities[0] : [];

  List<AbilityData> get enemyAbilities =>
      enemyPartyAbilities.isNotEmpty ? enemyPartyAbilities[0] : [];

  // ==================== STATS ====================

  DuelCombatantStats challengerStats = DuelCombatantStats();
  DuelCombatantStats enemyStats      = DuelCombatantStats();
  List<DuelEvent>    currentEvents   = [];
  List<DuelResult>   history         = [];

  static const _storageKey = 'duel_history';

  // ==================== PERSISTENCE ====================

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        history = list
            .map((e) => DuelResult.fromJson(e as Map<String, dynamic>))
            .toList();
        print('[DuelManager] Loaded ${history.length} history entries');
      }
    } catch (e) {
      print('[DuelManager] Failed to load history: $e');
    }
  }

  Future<void> saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _storageKey, jsonEncode(history.map((r) => r.toJson()).toList()));
    } catch (e) {
      print('[DuelManager] Failed to save history: $e');
    }
  }

  // ==================== EVENT RECORDING ====================

  void recordEvent(DuelEvent event) {
    currentEvents.add(event);
    if (event.type == 'damage') {
      if (event.actorId == 'challenger') {
        challengerStats.totalDamageDealt += event.value;
      } else {
        enemyStats.totalDamageDealt += event.value;
      }
    } else if (event.type == 'heal') {
      if (event.actorId == 'challenger') {
        challengerStats.totalHealingDone += event.value;
      } else {
        enemyStats.totalHealingDone += event.value;
      }
    }
  }

  // ==================== LIFECYCLE ====================

  Future<void> finalizeDuel(String winnerId, double duration) async {
    final result = DuelResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      challengerClass:    selectedChallengerClass ?? 'unknown',
      enemyFactionType:   selectedEnemyType       ?? 'unknown',
      challengerClasses:  List.from(challengerPartyClasses),
      enemyTypes:         List.from(enemyPartyTypes),
      challengerGearTiers: List.from(challengerGearTiers),
      enemyGearTiers:     List.from(enemyGearTiers),
      winnerId:           winnerId,
      durationSeconds:    duration,
      endCondition:       endCondition,
      events:             List.from(currentEvents),
      challengerStats:    challengerStats,
      enemyStats:         enemyStats,
    );
    history.insert(0, result);
    // Reason: cap history to prevent unbounded SharedPreferences growth
    final maxEntries = globalDuelConfig?.historyMaxEntries ?? 200;
    if (history.length > maxEntries) {
      history.removeRange(maxEntries, history.length);
    }
    await saveHistory();
    phase = DuelPhase.completed;
  }

  /// Reset runtime state; preserves history.  Setup fields are re-written by
  /// the command handler immediately after reset() returns.
  void reset() {
    phase = DuelPhase.idle;
    elapsedSeconds = 0.0;
    currentEvents.clear();
    challengerStats = DuelCombatantStats();
    enemyStats      = DuelCombatantStats();
    selectedChallengerClass  = null;
    selectedEnemyType        = null;
    challengerPartySize      = 1;
    enemyPartySize           = 1;
    challengerPartyClasses   = [];
    enemyPartyTypes          = [];
    challengerGearTiers      = [];
    enemyGearTiers           = [];
    challengerPartyAbilities = [];
    enemyPartyAbilities      = [];
    challengerStrategy       = DuelStrategy.balanced;
    enemyStrategy            = DuelStrategy.balanced;
    endCondition             = DuelEndCondition.totalAnnihilation;
    challengerParty          = const [];
    enemyParty               = const [];
    challengerDamageMults    = const [];
    enemyDamageMults         = const [];
    combatantGcds            = [];
    combatantComboWindows    = [];
  }
}
