import 'package:flutter/material.dart';
import '../game3d/data/abilities/ability_types.dart';

/// An active status effect currently applied to an entity (player, ally, monster).
///
/// Tracks remaining duration and provides helpers for UI display
/// (icon, color, buff vs debuff classification, progress ring).
class ActiveEffect {
  final StatusEffect type;
  double remainingDuration;
  final double totalDuration;
  double strength;

  /// Damage to apply each tick (0 = no damage, pure status effect)
  final double damagePerTick;

  /// Seconds between ticks
  final double tickInterval;

  /// Accumulator for tick timing
  double tickAccumulator;

  /// Name of the ability that created this effect (for combat log)
  final String sourceName;

  /// Whether this effect persists until death/cleanse (ignores duration)
  bool isPermanent;

  ActiveEffect({
    required this.type,
    required this.remainingDuration,
    required this.totalDuration,
    this.strength = 1.0,
    this.damagePerTick = 0.0,
    this.tickInterval = 0.0,
    this.tickAccumulator = 0.0,
    this.sourceName = '',
    this.isPermanent = false,
  });

  /// Whether this effect deals periodic damage
  bool get isDoT => damagePerTick > 0 && tickInterval > 0;

  /// Whether this effect has expired.
  bool get isExpired => !isPermanent && remainingDuration <= 0;

  /// Progress from 1.0 (full) to 0.0 (expired).
  double get progress => isPermanent ? 1.0 : (remainingDuration / totalDuration).clamp(0.0, 1.0);

  /// Buffs = positive effects on self/allies.
  bool get isBuff =>
      type == StatusEffect.haste ||
      type == StatusEffect.shield ||
      type == StatusEffect.regen ||
      type == StatusEffect.strength;

  /// Debuffs = negative effects (everything except buffs and none).
  bool get isDebuff => !isBuff && type != StatusEffect.none;

  /// Tick the effect timer by dt seconds.
  void tick(double dt) {
    // Reason: Permanent effects never expire — skip duration decrement
    if (!isPermanent) remainingDuration -= dt;
  }

  /// Icon for each status effect type.
  static IconData iconFor(StatusEffect type) {
    switch (type) {
      case StatusEffect.burn:
        return Icons.local_fire_department;
      case StatusEffect.freeze:
        return Icons.ac_unit;
      case StatusEffect.poison:
        return Icons.science;
      case StatusEffect.stun:
        return Icons.flash_off;
      case StatusEffect.slow:
        return Icons.speed;
      case StatusEffect.bleed:
        return Icons.water_drop;
      case StatusEffect.blind:
        return Icons.visibility_off;
      case StatusEffect.root:
        return Icons.park;
      case StatusEffect.silence:
        return Icons.volume_off;
      case StatusEffect.haste:
        return Icons.fast_forward;
      case StatusEffect.shield:
        return Icons.shield;
      case StatusEffect.regen:
        return Icons.favorite;
      case StatusEffect.strength:
        return Icons.fitness_center;
      case StatusEffect.weakness:
        return Icons.trending_down;
      case StatusEffect.fear:
        return Icons.warning;
      case StatusEffect.vulnerablePhysical:
      case StatusEffect.vulnerableFire:
      case StatusEffect.vulnerableFrost:
      case StatusEffect.vulnerableLightning:
      case StatusEffect.vulnerableNature:
      case StatusEffect.vulnerableShadow:
      case StatusEffect.vulnerableArcane:
      case StatusEffect.vulnerableHoly:
        return Icons.shield_outlined;
      case StatusEffect.none:
        return Icons.circle;
    }
  }

  /// Color for each status effect type.
  static Color colorFor(StatusEffect type) {
    switch (type) {
      case StatusEffect.burn:
        return const Color(0xFFFF6600);
      case StatusEffect.freeze:
        return const Color(0xFF66CCFF);
      case StatusEffect.poison:
        return const Color(0xFF66FF66);
      case StatusEffect.stun:
        return const Color(0xFFFFCC00);
      case StatusEffect.slow:
        return const Color(0xFF9999FF);
      case StatusEffect.bleed:
        return const Color(0xFFCC0000);
      case StatusEffect.blind:
        return const Color(0xFF999999);
      case StatusEffect.root:
        return const Color(0xFF886622);
      case StatusEffect.silence:
        return const Color(0xFF6666CC);
      case StatusEffect.haste:
        return const Color(0xFF00CCFF);
      case StatusEffect.shield:
        return const Color(0xFF3399FF);
      case StatusEffect.regen:
        return const Color(0xFF00CC66);
      case StatusEffect.strength:
        return const Color(0xFFFF3333);
      case StatusEffect.weakness:
        return const Color(0xFF996633);
      case StatusEffect.fear:
        return const Color(0xFF9933CC);
      case StatusEffect.vulnerablePhysical:
        return const Color(0xFFCC9966);
      case StatusEffect.vulnerableFire:
        return const Color(0xFFFF6600);
      case StatusEffect.vulnerableFrost:
        return const Color(0xFF66CCFF);
      case StatusEffect.vulnerableLightning:
        return const Color(0xFFFFFF00);
      case StatusEffect.vulnerableNature:
        return const Color(0xFF66FF66);
      case StatusEffect.vulnerableShadow:
        return const Color(0xFF9933CC);
      case StatusEffect.vulnerableArcane:
        return const Color(0xFFCC66FF);
      case StatusEffect.vulnerableHoly:
        return const Color(0xFFFFFF99);
      case StatusEffect.none:
        return const Color(0xFF666666);
    }
  }
}
