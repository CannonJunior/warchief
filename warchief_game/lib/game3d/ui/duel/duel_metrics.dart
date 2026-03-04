import '../../../models/duel_result.dart';
import '../../data/duel/duel_definitions.dart';
import '../../data/abilities/ability_types.dart';

// ── Character-level metric ────────────────────────────────────────────────────

/// Aggregated performance metric for one character type across all duels.
class CharacterMetric implements Comparable<CharacterMetric> {
  final String type;

  int    duels              = 0;
  int    wins               = 0;
  double totalDmg           = 0; // sum of attributed damage across all duels
  double totalHeal          = 0; // sum of attributed healing across all duels
  double totalDuration      = 0; // sum of duel durations (seconds)
  int    totalKillingBlows  = 0; // sum of killing blows delivered by this class
  int    totalCcCasts       = 0; // sum of CC / utility casts by this class

  CharacterMetric(this.type);

  double get winRate => duels > 0 ? wins / duels : 0.0;

  /// Average damage per second, attributed to this character type.
  double get avgDps => totalDuration > 0 ? totalDmg / totalDuration : 0.0;

  /// Average healing per second, attributed to this character type.
  double get avgHps => totalDuration > 0 ? totalHeal / totalDuration : 0.0;

  /// Average killing blows per duel appearance.
  double get avgKbPerDuel => duels > 0 ? totalKillingBlows / duels : 0.0;

  /// Overall balance score (0–100).
  ///
  /// Formula: win-rate (60 pts) + DPS efficiency normalised at 25 DPS (40 pts).
  /// Reason: win-rate is the primary balance signal; DPS captures raw output
  /// for classes that tend to draw or play in mixed parties.
  double get overallScore =>
      winRate * 60.0 + (avgDps / 25.0).clamp(0.0, 1.0) * 40.0;

  String get displayName =>
      DuelDefinitions.allDisplayNames[type] ?? type;

  @override
  int compareTo(CharacterMetric other) =>
      other.overallScore.compareTo(overallScore); // descending
}

// ── Ability-level metric ──────────────────────────────────────────────────────

/// Aggregated performance metric for one ability across all duel records.
class AbilityMetric implements Comparable<AbilityMetric> {
  final String abilityName;
  final String characterType;

  /// Ability cooldown sourced from the live [AbilityData] definition.
  final double cooldown;

  /// True for heal abilities; affects which value the rating is based on.
  final bool isHeal;

  int    uses      = 0;
  double totalDmg  = 0;
  double totalHeal = 0;

  AbilityMetric({
    required this.abilityName,
    required this.characterType,
    required this.cooldown,
    required this.isHeal,
  });

  double get avgDmgPerUse  => uses > 0 ? totalDmg  / uses : 0.0;
  double get avgHealPerUse => uses > 0 ? totalHeal / uses : 0.0;

  /// Ability rating = average output per use divided by cooldown duration.
  ///
  /// This is the "average of ratings every time the ability was used":
  ///   instanceRating = (damage or heal this cast) / cooldown
  ///   avgRating      = sum(instanceRating) / uses
  ///                  = totalOutput / (uses × cooldown)
  ///                  = avgOutputPerUse / cooldown
  ///
  /// Reason: dividing by cooldown normalises short-CD spam abilities against
  /// long-CD nukes, giving a damage-per-cooldown-second efficiency score.
  double get rating {
    final cd = cooldown > 0 ? cooldown : 1.0;
    return isHeal ? avgHealPerUse / cd : avgDmgPerUse / cd;
  }

  String get characterDisplayName =>
      DuelDefinitions.allDisplayNames[characterType] ?? characterType;

  @override
  int compareTo(AbilityMetric other) =>
      other.rating.compareTo(rating); // descending
}

// ── Computation ───────────────────────────────────────────────────────────────

/// Pure functions that aggregate [DuelResult] history into metrics.
class DuelMetrics {
  DuelMetrics._();

  // ── Character metrics ─────────────────────────────────────────────────────

  /// Build a [CharacterMetric] per character type from [history].
  ///
  /// Each duel occurrence contributes to every type present on either side.
  /// In multi-type parties, damage and healing are divided equally among all
  /// characters of the same type (since per-ability damage uses ability names
  /// as the attribution key, and ability names are class-unique).
  static List<CharacterMetric> computeCharacterMetrics(
      List<DuelResult> history) {
    final metrics = <String, CharacterMetric>{};
    for (final result in history) {
      _addCharacterSide(result, result.challengerClasses, result.challengerStats,
          won: result.winnerId == 'challenger', metrics: metrics,
          duration: result.durationSeconds);
      _addCharacterSide(result, result.enemyTypes, result.enemyStats,
          won: result.winnerId == 'enemy', metrics: metrics,
          duration: result.durationSeconds);
    }
    final list = metrics.values.toList()..sort();
    return list;
  }

  static void _addCharacterSide(
    DuelResult result,
    List<String> types,
    DuelCombatantStats stats, {
    required bool won,
    required double duration,
    required Map<String, CharacterMetric> metrics,
  }) {
    // Count occurrences of each type (e.g., 3 warriors → count = 3).
    final counts = <String, int>{};
    for (final t in types) {
      counts[t] = (counts[t] ?? 0) + 1;
    }

    for (final entry in counts.entries) {
      final type  = entry.key;
      final count = entry.value;

      // Collect the ability names that belong to this type.
      final abilNames = DuelDefinitions.getAbilities(type)
          .map((a) => a.name)
          .toSet();

      // Attribute damage/healing: divide by count because the stat maps
      // aggregate all party members of this type together.
      double xDmg = 0, xHeal = 0;
      stats.perAbilityDamage.forEach((k, v) {
        if (abilNames.contains(k)) xDmg += v / count;
      });
      stats.perAbilityHealing.forEach((k, v) {
        if (abilNames.contains(k)) xHeal += v / count;
      });
      // Reason: killing blows are ability-attributed so they are already
      // tied to a specific ability name → no division needed.
      int xKills = 0;
      stats.killingBlowsByAbility.forEach((k, v) {
        if (abilNames.contains(k)) xKills += v;
      });
      // Reason: CC casts are tracked at side level, not per ability; approximate
      // per-class share by dividing evenly across all party slots of this type.
      final totalSlots = types.length;
      final xCc = totalSlots > 0
          ? (stats.ccAndUtilityCasts * count / totalSlots).round() : 0;

      final m = metrics.putIfAbsent(type, () => CharacterMetric(type));
      m.duels              += 1;
      if (won) m.wins      += 1;
      m.totalDmg           += xDmg;
      m.totalHeal          += xHeal;
      m.totalDuration      += duration;
      m.totalKillingBlows  += xKills;
      m.totalCcCasts       += xCc;
    }
  }

  // ── Ability metrics ───────────────────────────────────────────────────────

  /// Build an [AbilityMetric] per ability name from [history].
  static List<AbilityMetric> computeAbilityMetrics(List<DuelResult> history) {
    // Build lookup tables once.
    final abilityByName = <String, AbilityData>{};
    final typeByAbility  = <String, String>{};
    for (final type in DuelDefinitions.allCombatantTypes) {
      for (final a in DuelDefinitions.getAbilities(type)) {
        abilityByName[a.name] ??= a;
        typeByAbility[a.name]  ??= type;
      }
    }

    final metrics = <String, AbilityMetric>{};
    for (final result in history) {
      _addAbilitySide(result.challengerStats, abilityByName, typeByAbility, metrics);
      _addAbilitySide(result.enemyStats,      abilityByName, typeByAbility, metrics);
    }
    final list = metrics.values.toList()..sort();
    return list;
  }

  static void _addAbilitySide(
    DuelCombatantStats stats,
    Map<String, AbilityData> abilityByName,
    Map<String, String> typeByAbility,
    Map<String, AbilityMetric> metrics,
  ) {
    for (final entry in stats.abilitiesUsed.entries) {
      final name    = entry.key;
      final uses    = entry.value;
      final ability = abilityByName[name];
      if (ability == null) continue;

      final m = metrics.putIfAbsent(
        name,
        () => AbilityMetric(
          abilityName:   name,
          characterType: typeByAbility[name] ?? '?',
          cooldown:      ability.cooldown,
          isHeal:        ability.type == AbilityType.heal,
        ),
      );
      m.uses      += uses;
      m.totalDmg  += stats.perAbilityDamage[name]  ?? 0;
      m.totalHeal += stats.perAbilityHealing[name] ?? 0;
    }
  }
}
