import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Spiritkin abilities — Primal nature warriors attuned to the spirit realm.
///
/// Combo chain: Pounce (gap-closer) → Swipe → Feral Strike → Spirit Bite → Savage Tear.
/// Four synergistic groups reward green mana investment.
class SpiritkinAbilities {
  SpiritkinAbilities._();

  // ==================== GROUP 1: BASIC MELEE ====================

  /// Pounce — Leap onto target, closing distance and slowing for 2s.
  /// Gap-closer that opens Swipe/Feral Strike combos.
  static final pounce = AbilityData(
    name: 'Pounce',
    description: 'Leap onto the target with feral power, closing distance instantly and slowing them for 2 seconds.',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 10.0,
    range: 8.0,
    color: Vector3(0.55, 0.80, 0.28),
    impactColor: Vector3(0.65, 0.90, 0.38),
    impactSize: 0.6,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    knockbackForce: 1.5,
    manaColor: ManaColor.green,
    manaCost: 12.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
    comboPrimes: ['Swipe', 'Feral Strike'],
  );

  /// Swipe — Lightning-fast claw rake. No mana cost.
  static final swipe = AbilityData(
    name: 'Swipe',
    description: 'A lightning-fast claw rake. No mana cost — use freely to fill gaps between cooldowns.',
    type: AbilityType.melee,
    damage: 14.0,
    cooldown: 1.5,
    range: 2.5,
    color: Vector3(0.50, 0.78, 0.25),
    impactColor: Vector3(0.60, 0.88, 0.35),
    impactSize: 0.40,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
    comboPrimes: ['Feral Strike', 'Spirit Bite'],
  );

  /// Feral Strike — Bone-crunching body slam that slows target by 40% for 2s.
  static final feralStrike = AbilityData(
    name: 'Feral Strike',
    description: 'A bone-crunching body slam that slows the target by 40% for 2 seconds. No mana cost.',
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
    comboPrimes: ['Spirit Bite', 'Savage Tear'],
  );

  /// Spirit Bite — Nature-infused fang strike that applies a 6s poison DoT.
  static final spiritBite = AbilityData(
    name: 'Spirit Bite',
    description: 'A spirit-infused fang strike that injects venomous nature energy, dealing poison over 6 seconds.',
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
    comboPrimes: ['Savage Tear', 'Spirit Rush'],
  );

  /// Savage Tear — Dual-claw rake dealing heavy damage with bleed DoT.
  /// Combo finisher after Feral Strike or Spirit Bite.
  static final savageTear = AbilityData(
    name: 'Savage Tear',
    description: 'Savage both-claws rake that tears deep wounds, dealing heavy damage and a bleed DoT. Combo finisher after Spirit Bite or Feral Strike.',
    type: AbilityType.melee,
    damage: 36.0,
    cooldown: 9.0,
    range: 2.5,
    color: Vector3(0.65, 0.35, 0.22),
    impactColor: Vector3(0.80, 0.42, 0.28),
    impactSize: 0.8,
    statusEffect: StatusEffect.bleed,
    statusDuration: 5.0,
    dotTicks: 3,
    windupTime: 0.35,
    windupMovementSpeed: 0.5,
    manaColor: ManaColor.green,
    manaCost: 20.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
    comboPrimes: ['Spirit Bite', 'Spirit Rush'],
  );

  // ==================== GROUP 2: LONG STANCE BUFFS ====================

  /// Spirit Skin — +20% damage for 60s. Drains ~2 green mana/sec.
  static final spiritSkin = AbilityData(
    name: 'Spirit Skin',
    description: 'Encase yourself in living spirit-bark, increasing all damage by +20% for 60 seconds. Drains ~2 green mana/sec.',
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

  /// Blood Aspect — +30% attack and movement speed for 45s. Drains ~4 green mana/sec.
  static final bloodAspect = AbilityData(
    name: 'Blood Aspect',
    description: 'Enter a feral bloodlust state, gaining +30% attack and movement speed for 45 seconds. Drains ~4 green mana/sec.',
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

  /// Spirit Awakening — +35% damage for 30s. Drains ~8 green mana/sec.
  static final spiritAwakening = AbilityData(
    name: 'Spirit Awakening',
    description: 'Channel the full force of the spirit realm, surging with +35% damage for 30 seconds. Drains ~8 green mana/sec.',
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

  /// Spirit Surge — +40% haste for 10 seconds.
  static final spiritSurge = AbilityData(
    name: 'Spirit Surge',
    description: 'Channel a burst of primal speed, gaining +40% attack and movement speed for 10 seconds.',
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

  /// Verdant Ward — Absorb up to 80 damage for 8s.
  static final verdantWard = AbilityData(
    name: 'Verdant Ward',
    description: 'Weave a dense nature barrier that absorbs up to 80 damage for 8 seconds.',
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

  /// Nature's Grace — +30% damage amplifier for 12s.
  static final naturesGrace = AbilityData(
    name: "Nature's Grace",
    description: "Suffuse yourself with nature's power, amplifying all damage by +30% for 12 seconds.",
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

  /// Thornbind — HoT 25 HP over 8s + thorn damage reflection.
  static final thornbind = AbilityData(
    name: 'Thornbind',
    description: 'Entwine yourself in spirit thorns for 8 seconds: heals 25 HP and returns damage to attackers.',
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

  /// Verdant Stride — HoT 45 HP over 15s + 25% movement speed.
  static final verdantStride = AbilityData(
    name: 'Verdant Stride',
    description: 'Attune your steps to the spirit realm for 15 seconds: heals 45 HP and grants +25% movement speed.',
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

  /// Ironbark Shell — HoT 60 HP over 25s + absorbs 50 damage.
  static final ironbarkShell = AbilityData(
    name: 'Ironbark Shell',
    description: 'Encase yourself in living ironbark for 25 seconds: heals 60 HP and absorbs up to 50 incoming damage.',
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

  // ==================== GROUP 5: DIRECT HEALING ====================

  /// Nature Mend — Instant 30 HP heal for self or ally.
  static final natureMend = AbilityData(
    name: 'Nature Mend',
    description: 'Channel raw nature energy into an instant heal of 30 HP. Targets a friendly ally if selected.',
    type: AbilityType.heal,
    cooldown: 8.0,
    range: 40.0,
    healAmount: 30.0,
    color: Vector3(0.42, 0.80, 0.30),
    impactColor: Vector3(0.52, 0.90, 0.42),
    impactSize: 0.85,
    castTime: 0.8,
    manaColor: ManaColor.green,
    manaCost: 20.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Spirit Bloom — AoE burst heal for up to 5 nearby allies.
  static final spiritBloom = AbilityData(
    name: 'Spirit Bloom',
    description: 'Release a pulse of spirit energy that heals up to 5 nearby allies (including yourself) for 20 HP each.',
    type: AbilityType.heal,
    cooldown: 20.0,
    duration: 0.5,
    range: 40.0,
    healAmount: 20.0,
    color: Vector3(0.48, 0.85, 0.35),
    impactColor: Vector3(0.58, 0.95, 0.45),
    impactSize: 1.2,
    aoeRadius: 10.0,
    maxTargets: 5,
    manaColor: ManaColor.green,
    manaCost: 30.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  // ==================== SPIRIT ANIMAL SUMMON ====================

  /// Animal Spirit — Summon a spirit wolf bonded to the Spiritkin.
  static final animalSpirit = AbilityData(
    name: 'Animal Spirit',
    description: 'Summon a spirit wolf bonded to your soul. '
        'The wolf persists while you have green mana, draining 5/sec. '
        'Each second it restores 3 green mana to every other party member.',
    type: AbilityType.summon,
    cooldown: 120.0,
    range: 0.0,
    color: Vector3(0.45, 0.78, 0.28),
    impactColor: Vector3(0.55, 0.90, 0.40),
    impactSize: 1.5,
    manaColor: ManaColor.green,
    manaCost: 30.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Spirit Rush — Activates chain-combo mode.
  static final spiritRush = AbilityData(
    name: 'Spirit Rush',
    description: 'Rush with spirit-fueled frenzy — activate chain-combo mode. '
        'Land 7 spiritkin hits within 7 seconds to trigger a powerful haste burst and healing regen.',
    type: AbilityType.melee,
    damage: 16.0,
    cooldown: 10.0,
    range: 2.0,
    color: Vector3(0.48, 0.80, 0.28),
    impactColor: Vector3(0.58, 0.90, 0.38),
    impactSize: 0.55,
    manaColor: ManaColor.green,
    manaCost: 15.0,
    damageSchool: DamageSchool.nature,
    category: 'spiritkin',
    enablesComboChain: true,
    comboPrimes: ['Swipe', 'Pounce'],
  );

  // ==================== INTERRUPT ====================

  /// Spirit Sever — Interrupts spellcasting for 3s.
  static final spiritSever = AbilityData(
    name: 'Spirit Sever',
    description: 'A razor-precise strike that severs the target\'s connection to the spirit realm, interrupting their spellcasting for 3 seconds.',
    type: AbilityType.melee,
    damage: 13.0,
    cooldown: 14.0,
    range: 2.2,
    color: Vector3(0.50, 0.78, 0.25),
    impactColor: Vector3(0.60, 0.88, 0.35),
    impactSize: 0.5,
    statusEffect: StatusEffect.interrupt,
    statusDuration: 3.0,
    manaColor: ManaColor.green,
    manaCost: 10.0,
    damageSchool: DamageSchool.nature,
    category: 'spiritkin',
    comboPrimes: ['Pounce', 'Swipe'],
  );

  /// Spirit Bond — Self-buff channeling spirit energy into combat power.
  static final spiritBond = AbilityData(
    name: 'Spirit Bond',
    description: 'Bond with your spirit companion to channel their power into your strikes, increasing your combat effectiveness.',
    type: AbilityType.buff,
    cooldown: 5.0,
    duration: 3600.0,
    color: Vector3(0.5, 0.9, 0.3),
    impactColor: Vector3(0.6, 1.0, 0.4),
    impactSize: 1.2,
    statusEffect: StatusEffect.strength,
    statusStrength: 0.20,
    manaColor: ManaColor.green,
    manaCost: 25.0,
    category: 'spiritkin',
    isAura: true,
    auraRange: 10.0,
  );

  /// All Spiritkin abilities as a flat list.
  /// Ordered short→long cooldown; slots 11-15 hold the longest cooldowns.
  /// Cut: naturesGrace, thornbind, verdantStride, ironbarkShell, spiritBloom
  ///      (minor HoT/buffs that overlap with stance identity or verdantWard).
  static List<AbilityData> get all => [
    spiritSkin,      //  1  0.0s  stance: +20% damage
    bloodAspect,     //  2  0.0s  stance: +30% speed
    spiritAwakening, //  3  0.0s  stance: +35% damage
    swipe,           //  4  1.5s  free basic melee
    spiritBite,      //  5  2.5s  poison DoT
    feralStrike,     //  6  3.0s  free body slam slow
    spiritBond,      //  7  5.0s  damage aura
    natureMend,      //  8  8.0s  direct heal
    savageTear,      //  9  9.0s  combo finisher bleed
    pounce,          // 10 10.0s  gap closer + slow CC
    spiritRush,      // 11 10.0s  chain combo primer
    spiritSever,     // 12 14.0s  interrupt
    spiritSurge,     // 13 20.0s  burst haste
    verdantWard,     // 14 25.0s  shield absorb
    animalSpirit,    // 15 120.0s summon spirit wolf
  ];
}
