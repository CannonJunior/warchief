import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Spiritkin abilities — Primal nature warriors attuned to the spirit realm.
///
/// ## Design Philosophy
/// Four synergistic groups that reward green mana investment:
///
/// **Group 1 — Basic Melee (3):** Short-cooldown strikes; two are free, one costs
/// green mana and applies a stacking poison DoT.
///
/// **Group 2 — Stance Buffs (3, no cooldown):** Each grants a different bonus but
/// drains green mana regeneration while active. The tiers stack *multiplicatively*:
///   Spirit Skin (×1.20) × Blood Aspect (×1.30) × Spirit Awakening (×1.35) ≈ ×2.1
/// All three together cost ~14 green mana/sec — only sustainable near nature sources.
///
/// **Group 3 — Short Universal Buffs (3):** Haste, shield, and damage — each lasts
/// 8–12 s and is useful to every character class.
///
/// **Group 4 — Healing Buffs (3):** Different durations (8 s / 15 s / 25 s) with
/// distinct secondary effects: thorn damage, movement speed, and damage shield.
/// Active together they form a near-invincible state: three HoTs ticking, absorb
/// up, fast to reposition, and attackers take reflected thorn damage.
class SpiritkinAbilities {
  SpiritkinAbilities._();

  // ==================== GROUP 1: BASIC MELEE ====================
  // Two free attacks + one green-mana strike with a poison DoT.
  // Short cooldowns encourage weaving them between buff refreshes.

  /// Swipe — The fastest Spiritkin attack. No cost, 1.5 s cooldown.
  /// Use freely between buff refreshes; chains cleanly into Feral Strike or Spirit Bite.
  static final swipe = AbilityData(
    name: 'Swipe',
    description: 'A lightning-fast claw rake. No mana cost — use freely to fill gaps between '
        'cooldowns and buff refreshes. Chains cleanly into Feral Strike or Spirit Bite.',
    type: AbilityType.melee,
    damage: 14.0,
    cooldown: 1.5,
    range: 2.5,
    color: Vector3(0.50, 0.78, 0.25),
    impactColor: Vector3(0.60, 0.88, 0.35),
    impactSize: 0.40,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Feral Strike — Savage body slam that slows the target by 40% for 2 s.
  /// No cost; the slow makes follow-up Spirit Bites and DoTs land reliably.
  static final feralStrike = AbilityData(
    name: 'Feral Strike',
    description: 'A bone-crunching body slam that slows the target by 40% for 2 seconds. '
        'No mana cost. The slow window is ideal for landing Spirit Bite poison reliably.',
    type: AbilityType.melee,
    damage: 22.0,
    cooldown: 3.0,
    range: 2.5,
    color: Vector3(0.55, 0.60, 0.20),
    impactColor: Vector3(0.65, 0.70, 0.30),
    impactSize: 0.55,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    windupTime: 0.25,
    windupMovementSpeed: 0.70,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Spirit Bite — Nature-infused fang strike that applies a 6 s poison DoT.
  /// Costs green mana. Scales directly with Spirit Skin's +damage bonus — the
  /// poison ticks inherit the damage multiplier, making this the highest-pressure
  /// single-target attack when stance buffs are active.
  static final spiritBite = AbilityData(
    name: 'Spirit Bite',
    description: 'A spirit-infused fang strike that injects venomous nature energy, '
        'dealing poison over 6 seconds. Costs green mana. Poison ticks scale with active '
        'damage buffs — use after Spirit Skin for maximum DoT pressure.',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 2.5,
    range: 2.5,
    color: Vector3(0.40, 0.82, 0.22),
    impactColor: Vector3(0.50, 0.92, 0.32),
    impactSize: 0.50,
    statusEffect: StatusEffect.poison,
    statusDuration: 6.0,
    dotTicks: 4,
    manaColor: ManaColor.green,
    manaCost: 8.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  // ==================== GROUP 2: LONG STANCE BUFFS (no cooldown) ====================
  // No cooldown — the limiter is green mana. Each buff drains green mana regen
  // while active; the three together drain ~14 green/sec.
  //
  // Triple-stack synergy: Spirit Skin × Blood Aspect × Spirit Awakening ≈ ×2.1 damage
  // Cost: 88 green mana total to activate all three; then ~14 green/sec maintenance.
  // This is only sustainable near Ley Lines or nature power nodes.

  /// Spirit Skin — Tier 1 stance: living-bark armor that sharpens all attacks.
  /// +20% damage for 60 s. Drains ~2 green mana/sec. No cooldown: re-apply whenever
  /// mana allows. Alone it's a modest buff; the real payoff is stacking the other two.
  static final spiritSkin = AbilityData(
    name: 'Spirit Skin',
    description: 'Encase yourself in living spirit-bark, increasing all damage by +20% for 60 seconds. '
        'Drains ~2 green mana/sec while active. No cooldown. '
        'Alone: modest. With Blood Aspect + Spirit Awakening: damage rises to ~210% (×1.20 × 1.30 × 1.35).',
    type: AbilityType.buff,
    cooldown: 0.0,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.20,
    statusDuration: 60.0,
    color: Vector3(0.45, 0.70, 0.25),
    impactColor: Vector3(0.55, 0.80, 0.35),
    impactSize: 0.90,
    manaColor: ManaColor.green,
    manaCost: 15.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Blood Aspect — Tier 2 stance: feral bloodlust that accelerates everything.
  /// +30% attack and movement speed for 45 s. Drains ~4 green mana/sec. No cooldown.
  /// With Spirit Skin active, your empowered attacks land 30% faster — effectively
  /// amplifying total DPS beyond either buff alone.
  static final bloodAspect = AbilityData(
    name: 'Blood Aspect',
    description: 'Enter a feral bloodlust state, gaining +30% attack and movement speed for 45 seconds. '
        'Drains ~4 green mana/sec. No cooldown. '
        'Pairing with Spirit Skin means damage-boosted strikes arrive 30% faster — '
        'combined DPS gain far exceeds each buff independently.',
    type: AbilityType.buff,
    cooldown: 0.0,
    statusEffect: StatusEffect.haste,
    statusStrength: 1.30,
    statusDuration: 45.0,
    color: Vector3(0.78, 0.35, 0.20),
    impactColor: Vector3(0.88, 0.45, 0.28),
    impactSize: 1.00,
    manaColor: ManaColor.green,
    manaCost: 28.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Spirit Awakening — Tier 3 stance: full transcendence into the spirit realm.
  /// +35% damage for 30 s. Drains ~8 green mana/sec. No cooldown.
  /// The capstone of the triple-stack: alone it's strong, but the triple combination
  /// (×1.20 × 1.30 × 1.35 ≈ ×2.1) at 14 green/sec total drain is the class identity.
  static final spiritAwakening = AbilityData(
    name: 'Spirit Awakening',
    description: 'Channel the full force of the spirit realm, surging with +35% damage for 30 seconds. '
        'Drains ~8 green mana/sec. No cooldown. '
        'Triple-stack capstone: Spirit Skin + Blood Aspect + Spirit Awakening = ~210% base damage, '
        'costing ~14 green mana/sec total — only sustainable near Ley Lines or nature power nodes.',
    type: AbilityType.buff,
    cooldown: 0.0,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.35,
    statusDuration: 30.0,
    color: Vector3(0.58, 0.88, 0.30),
    impactColor: Vector3(0.68, 0.98, 0.42),
    impactSize: 1.20,
    manaColor: ManaColor.green,
    manaCost: 45.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  // ==================== GROUP 3: SHORT UNIVERSAL BUFFS ====================
  // Each lasts 8–12 s and is designed to benefit every class archetype.
  // Use during burst windows, incoming spike damage, or before a big cooldown.

  /// Spirit Surge — Universal burst speed (10 s, +40% haste).
  /// Useful for every class: melee uses it for burst windows, ranged for kiting,
  /// healers for positioning. Short cooldown encourages active use.
  static final spiritSurge = AbilityData(
    name: 'Spirit Surge',
    description: 'Channel a burst of primal speed, gaining +40% attack and movement speed for 10 seconds. '
        'Universal: melee can burst, ranged can reposition, healers can reach targets faster. '
        'Stacks with Blood Aspect for a short window of extreme speed.',
    type: AbilityType.buff,
    cooldown: 20.0,
    statusEffect: StatusEffect.haste,
    statusStrength: 1.40,
    statusDuration: 10.0,
    color: Vector3(0.50, 0.82, 0.32),
    impactColor: Vector3(0.60, 0.92, 0.42),
    impactSize: 0.90,
    manaColor: ManaColor.green,
    manaCost: 12.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Verdant Ward — Universal nature barrier absorbing up to 80 damage (8 s).
  /// Pure survival insurance for any class. Effective combined with Ironbark Shell
  /// for layered absorb: Ward absorbs first, then Shell's absorb catches overflow.
  static final verdantWard = AbilityData(
    name: 'Verdant Ward',
    description: 'Weave a dense nature barrier that absorbs up to 80 damage for 8 seconds. '
        'Works for any class — pure survival insurance. '
        'Stack with Ironbark Shell for layered absorb: Ward takes damage first, Shell catches the rest.',
    type: AbilityType.buff,
    cooldown: 25.0,
    statusEffect: StatusEffect.shield,
    statusStrength: 80.0,
    statusDuration: 8.0,
    color: Vector3(0.35, 0.65, 0.22),
    impactColor: Vector3(0.45, 0.75, 0.32),
    impactSize: 1.00,
    manaColor: ManaColor.green,
    manaCost: 18.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Nature's Grace — Universal damage amplifier (12 s, +30% damage).
  /// Longer than Spirit Surge but for damage rather than speed. Pop just before
  /// a major cooldown for maximum payoff. With all three stance buffs active,
  /// this pushes the total multiplier even further for a brief moment.
  static final naturesGrace = AbilityData(
    name: "Nature's Grace",
    description: "Suffuse yourself with nature's power, amplifying all damage by +30% for 12 seconds. "
        'Universal: scales melee, spells, poison DoTs, and pet damage equally. '
        'Pop just before a major cooldown. With all three stance buffs active, '
        'the combined multiplier briefly exceeds ×2.7 for a devastating burst window.',
    type: AbilityType.buff,
    cooldown: 30.0,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.30,
    statusDuration: 12.0,
    color: Vector3(0.42, 0.76, 0.22),
    impactColor: Vector3(0.52, 0.86, 0.32),
    impactSize: 1.00,
    manaColor: ManaColor.green,
    manaCost: 20.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  // ==================== GROUP 4: HEALING BUFFS ====================
  // Three durations (8 s / 15 s / 25 s) with distinct secondary effects:
  //   Thornbind     — HoT + thorn damage dealt back to attackers
  //   Verdant Stride — HoT + movement speed
  //   Ironbark Shell — HoT + absorb shield
  //
  // Triple-stack synergy: all three active simultaneously = continuous healing,
  // absorb layer, high mobility, and thorn reflection punishing every hit.
  // Combined maintenance cost: ~5 green/sec; pair with stance buffs only near
  // nature power nodes.

  /// Thornbind — Short (8 s): HoT healing 25 HP + thorn damage reflection.
  /// Heals over 4 ticks; enemies striking you take 15% of damage as nature return.
  /// Shortest window — burst defensive cooldown. Use right before taking heavy hits.
  static final thornbind = AbilityData(
    name: 'Thornbind',
    description: 'Entwine yourself in spirit thorns for 8 seconds: '
        'heals 25 HP over 4 ticks and returns 15% of damage received to attackers as nature damage. '
        'Shortest window — use as a burst defensive cooldown. '
        'Stack with Verdant Stride + Ironbark Shell: triple HoTs tick simultaneously, '
        'absorb is up, and every hit on you triggers thorn return.',
    type: AbilityType.buff,
    cooldown: 15.0,
    healAmount: 25.0,
    damage: 8.0,
    statusEffect: StatusEffect.regen,
    statusStrength: 1.15,
    statusDuration: 8.0,
    dotTicks: 4,
    color: Vector3(0.50, 0.62, 0.22),
    impactColor: Vector3(0.60, 0.72, 0.30),
    impactSize: 0.80,
    manaColor: ManaColor.green,
    manaCost: 18.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Verdant Stride — Medium (15 s): HoT healing 45 HP + 25% movement speed.
  /// Heals over 5 ticks; speed lets you reposition, kite, or close gaps while healing.
  /// The movement bonus means you can dictate range — vital when layering healing buffs.
  static final verdantStride = AbilityData(
    name: 'Verdant Stride',
    description: 'Attune your steps to the spirit realm for 15 seconds: '
        'heals 45 HP over 5 ticks and grants +25% movement speed. '
        'The speed lets you kite or close gaps while healing, '
        'making positioning possible even under heavy pressure. '
        'Stack with Thornbind + Ironbark Shell: your mobility lets you maintain '
        'ideal range while all three HoTs tick simultaneously.',
    type: AbilityType.buff,
    cooldown: 20.0,
    healAmount: 45.0,
    statusEffect: StatusEffect.haste,
    statusStrength: 1.25,
    statusDuration: 15.0,
    dotTicks: 5,
    color: Vector3(0.45, 0.78, 0.32),
    impactColor: Vector3(0.55, 0.88, 0.42),
    impactSize: 0.90,
    manaColor: ManaColor.green,
    manaCost: 25.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Ironbark Shell — Long (25 s): HoT healing 60 HP + absorbs 50 damage.
  /// The anchor of the healing stack: longest window and absorb layer.
  /// With Thornbind + Verdant Stride also active: continuous healing (~130 HP total
  /// over the shortest common window), absorb soaking burst, thorn return on every hit,
  /// and +25% movement — a near-invincible state that costs ~5 green/sec to sustain.
  static final ironbarkShell = AbilityData(
    name: 'Ironbark Shell',
    description: 'Encase yourself in living ironbark for 25 seconds: '
        'heals 60 HP over 6 ticks and absorbs up to 50 incoming damage. '
        'The anchor of the healing stack. '
        'With Thornbind + Verdant Stride also active: ~130 HP of total HoT healing, '
        'absorb layer, thorn damage return, and movement speed simultaneously — '
        'a near-invincible state costing ~5 green/sec to maintain.',
    type: AbilityType.buff,
    cooldown: 30.0,
    healAmount: 60.0,
    statusEffect: StatusEffect.shield,
    statusStrength: 50.0,
    statusDuration: 25.0,
    dotTicks: 6,
    color: Vector3(0.35, 0.56, 0.22),
    impactColor: Vector3(0.45, 0.66, 0.32),
    impactSize: 1.10,
    manaColor: ManaColor.green,
    manaCost: 35.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// All Spiritkin abilities as a flat list (used by the codex and action bar).
  static List<AbilityData> get all => [
    // Group 1: Basic melee
    swipe,
    feralStrike,
    spiritBite,
    // Group 2: Long stance buffs (no cooldown)
    spiritSkin,
    bloodAspect,
    spiritAwakening,
    // Group 3: Short universal buffs
    spiritSurge,
    verdantWard,
    naturesGrace,
    // Group 4: Healing buffs
    thornbind,
    verdantStride,
    ironbarkShell,
  ];
}
