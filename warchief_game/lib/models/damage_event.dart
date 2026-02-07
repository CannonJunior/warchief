import 'package:flutter/material.dart';

/// Represents a single damage event for DPS tracking
class DamageEvent {
  final String abilityName;
  final double damage;
  final bool isCritical;
  final bool isHit; // false = miss/dodge
  final DateTime timestamp;
  final Color abilityColor;

  DamageEvent({
    required this.abilityName,
    required this.damage,
    this.isCritical = false,
    this.isHit = true,
    DateTime? timestamp,
    this.abilityColor = Colors.white,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Time in seconds since epoch for calculations
  double get timeSeconds => timestamp.millisecondsSinceEpoch / 1000.0;
}

/// Tracks damage events and calculates DPS metrics
class DpsTracker {
  final List<DamageEvent> _events = [];
  DateTime? _sessionStart;

  /// Start a new DPS tracking session
  void startSession() {
    _events.clear();
    _sessionStart = DateTime.now();
  }

  /// End the current session
  void endSession() {
    _sessionStart = null;
  }

  /// Whether a session is active
  bool get isActive => _sessionStart != null;

  /// Record a damage event
  void recordDamage({
    required String abilityName,
    required double damage,
    bool isCritical = false,
    bool isHit = true,
    Color abilityColor = Colors.white,
  }) {
    if (!isActive) return;

    _events.add(DamageEvent(
      abilityName: abilityName,
      damage: damage,
      isCritical: isCritical,
      isHit: isHit,
      abilityColor: abilityColor,
    ));
  }

  /// Get all events
  List<DamageEvent> get events => List.unmodifiable(_events);

  /// Get events for a specific ability
  List<DamageEvent> eventsForAbility(String abilityName) {
    return _events.where((e) => e.abilityName == abilityName).toList();
  }

  /// Get unique ability names
  List<String> get abilityNames {
    return _events.map((e) => e.abilityName).toSet().toList();
  }

  /// Session duration in seconds
  double get sessionDuration {
    if (_sessionStart == null) return 0;
    return DateTime.now().difference(_sessionStart!).inMilliseconds / 1000.0;
  }

  /// Total damage dealt
  double get totalDamage {
    return _events.where((e) => e.isHit).fold(0.0, (sum, e) => sum + e.damage);
  }

  /// Overall DPS (damage per second)
  double get overallDps {
    final duration = sessionDuration;
    if (duration <= 0) return 0;
    return totalDamage / duration;
  }

  /// Total number of attacks
  int get totalAttacks => _events.length;

  /// Number of hits
  int get totalHits => _events.where((e) => e.isHit).length;

  /// Number of critical hits
  int get totalCrits => _events.where((e) => e.isCritical && e.isHit).length;

  /// Hit rate as percentage (0-100)
  double get hitRate {
    if (totalAttacks == 0) return 0;
    return (totalHits / totalAttacks) * 100;
  }

  /// Critical hit rate as percentage of hits (0-100)
  double get critRate {
    if (totalHits == 0) return 0;
    return (totalCrits / totalHits) * 100;
  }

  /// Get damage statistics for a specific ability
  AbilityDamageStats getAbilityStats(String abilityName) {
    final abilityEvents = eventsForAbility(abilityName);
    final hits = abilityEvents.where((e) => e.isHit).toList();

    if (hits.isEmpty) {
      return AbilityDamageStats(
        abilityName: abilityName,
        totalDamage: 0,
        hitCount: 0,
        missCount: abilityEvents.length,
        critCount: 0,
        minDamage: 0,
        maxDamage: 0,
        avgDamage: 0,
        medianDamage: 0,
        q1Damage: 0,
        q3Damage: 0,
        color: abilityEvents.isNotEmpty ? abilityEvents.first.abilityColor : Colors.grey,
      );
    }

    final damages = hits.map((e) => e.damage).toList()..sort();
    final critCount = hits.where((e) => e.isCritical).length;

    return AbilityDamageStats(
      abilityName: abilityName,
      totalDamage: damages.fold(0.0, (sum, d) => sum + d),
      hitCount: hits.length,
      missCount: abilityEvents.length - hits.length,
      critCount: critCount,
      minDamage: damages.first,
      maxDamage: damages.last,
      avgDamage: damages.fold(0.0, (sum, d) => sum + d) / damages.length,
      medianDamage: _percentile(damages, 50),
      q1Damage: _percentile(damages, 25),
      q3Damage: _percentile(damages, 75),
      color: abilityEvents.first.abilityColor,
    );
  }

  /// Get stats for all abilities
  List<AbilityDamageStats> getAllAbilityStats() {
    return abilityNames.map((name) => getAbilityStats(name)).toList()
      ..sort((a, b) => b.totalDamage.compareTo(a.totalDamage));
  }

  /// Calculate percentile from sorted list
  double _percentile(List<double> sortedValues, int percentile) {
    if (sortedValues.isEmpty) return 0;
    if (sortedValues.length == 1) return sortedValues.first;

    final index = (percentile / 100) * (sortedValues.length - 1);
    final lower = index.floor();
    final upper = index.ceil();

    if (lower == upper) return sortedValues[lower];

    final fraction = index - lower;
    return sortedValues[lower] + (sortedValues[upper] - sortedValues[lower]) * fraction;
  }

  /// Clear all data
  void clear() {
    _events.clear();
    _sessionStart = null;
  }
}

/// Statistics for a single ability
class AbilityDamageStats {
  final String abilityName;
  final double totalDamage;
  final int hitCount;
  final int missCount;
  final int critCount;
  final double minDamage;
  final double maxDamage;
  final double avgDamage;
  final double medianDamage;
  final double q1Damage;  // 25th percentile
  final double q3Damage;  // 75th percentile
  final Color color;

  const AbilityDamageStats({
    required this.abilityName,
    required this.totalDamage,
    required this.hitCount,
    required this.missCount,
    required this.critCount,
    required this.minDamage,
    required this.maxDamage,
    required this.avgDamage,
    required this.medianDamage,
    required this.q1Damage,
    required this.q3Damage,
    required this.color,
  });

  int get totalAttempts => hitCount + missCount;

  double get hitRate => totalAttempts > 0 ? (hitCount / totalAttempts) * 100 : 0;

  double get critRate => hitCount > 0 ? (critCount / hitCount) * 100 : 0;

  /// DPS contribution (requires session duration from tracker)
  double dpsContribution(double sessionDuration) {
    if (sessionDuration <= 0) return 0;
    return totalDamage / sessionDuration;
  }
}
