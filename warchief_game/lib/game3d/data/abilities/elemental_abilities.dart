import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Elemental abilities — Elemental reaction combos: ice→fire, freeze→smash.
///
/// Combo chain: Frostbite Slash (chill) → Magma Strike (fire reaction) → Flame Wave.
/// Earthquake sets up ground-slam follow-ups. Magnetic Disrupt opens punish windows.
class ElementalAbilities {
  ElementalAbilities._();

  /// Ice Lance — Piercing ice projectile.
  static final iceLance = AbilityData(
    name: 'Ice Lance',
    description: 'Sharp ice projectile that pierces through enemies.',
    type: AbilityType.ranged,
    damage: 18.0,
    cooldown: 3.0,
    range: 40.0,
    color: Vector3(0.7, 0.9, 1.0),
    impactColor: Vector3(0.8, 1.0, 1.0),
    impactSize: 0.4,
    projectileSpeed: 18.0,
    projectileSize: 0.2,
    piercing: true,
    maxTargets: 3,
    category: 'elemental',
    damageSchool: DamageSchool.frost,
    comboPrimes: ['Frostbite Slash', 'Earthquake'],
  );

  /// Flame Wave — Line AoE fire attack.
  static final flameWave = AbilityData(
    name: 'Flame Wave',
    description: 'Sends a wave of fire in a line.',
    type: AbilityType.aoe,
    damage: 30.0,
    cooldown: 7.0,
    duration: 0.6,
    range: 12.0,
    color: Vector3(1.0, 0.5, 0.1),
    impactColor: Vector3(1.0, 0.6, 0.2),
    impactSize: 0.8,
    aoeRadius: 2.0,
    statusEffect: StatusEffect.burn,
    statusDuration: 2.0,
    category: 'elemental',
    damageSchool: DamageSchool.fire,
    comboPrimes: ['Ice Lance', 'Earthquake'],
  );

  /// Earthquake — Channeled ground AoE with periodic stun.
  static final earthquake = AbilityData(
    name: 'Earthquake',
    description: 'Shakes the ground, damaging and stunning enemies.',
    type: AbilityType.channeled,
    damage: 15.0,
    cooldown: 25.0,
    duration: 3.0,
    range: 15.0,
    color: Vector3(0.6, 0.4, 0.2),
    impactColor: Vector3(0.7, 0.5, 0.3),
    impactSize: 1.5,
    aoeRadius: 8.0,
    dotTicks: 6,
    statusEffect: StatusEffect.stun,
    statusDuration: 0.5,
    castTime: 1.0,
    channelEffect: ChannelEffect.earthquake,
    category: 'elemental',
    damageSchool: DamageSchool.nature,
    comboPrimes: ['Magma Strike', 'Flame Wave'],
  );

  // ==================== MELEE ABILITIES ====================

  /// Frostbite Slash — Ice-enchanted blade that slows. Combo opener.
  static final frostbiteSlash = AbilityData(
    name: 'Frostbite Slash',
    description: 'Slash with an ice-enchanted blade, chilling the target. '
        'Chilled targets take bonus damage from Magma Strike (ice-fire reaction).',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 1.0,
    range: 2.5,
    color: Vector3(0.6, 0.85, 1.0),
    impactColor: Vector3(0.7, 0.9, 1.0),
    impactSize: 0.5,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    category: 'elemental',
    damageSchool: DamageSchool.frost,
    comboPrimes: ['Magma Strike', 'Ice Lance'],
  );

  /// Magma Strike — Molten fist slam. Deals bonus damage to chilled targets.
  static final magmaStrike = AbilityData(
    name: 'Magma Strike',
    description: 'Slam with a molten fist, searing the target with lingering flames. '
        'Deals amplified damage to chilled targets (ice-fire reaction).',
    type: AbilityType.melee,
    damage: 28.0,
    cooldown: 7.0,
    range: 2.5,
    color: Vector3(1.0, 0.4, 0.1),
    impactColor: Vector3(1.0, 0.5, 0.2),
    impactSize: 0.7,
    statusEffect: StatusEffect.burn,
    statusDuration: 3.0,
    category: 'elemental',
    damageSchool: DamageSchool.fire,
    comboPrimes: ['Flame Wave', 'Elemental Chain'],
  );

  /// Elemental Rend — Fiery strike that permanently exposes target.
  static final elementalRend = AbilityData(
    name: 'Elemental Rend',
    description: 'A fiery strike that permanently exposes the target to fire damage.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(1.0, 0.4, 0.1),
    impactColor: Vector3(1.0, 0.5, 0.2),
    impactSize: 0.6,
    category: 'elemental',
    damageSchool: DamageSchool.fire,
    appliesPermanentVulnerability: true,
    comboPrimes: ['Flame Wave', 'Magma Strike'],
  );

  // ==================== INTERRUPT ====================

  /// Magnetic Disrupt — Electromagnetic pulse interrupt.
  static final magneticDisrupt = AbilityData(
    name: 'Magnetic Disrupt',
    description: 'Fire a focused electromagnetic pulse that interrupts the target\'s spellcasting for 3 seconds.',
    type: AbilityType.ranged,
    damage: 16.0,
    cooldown: 22.0,
    range: 20.0,
    color: Vector3(1.0, 0.75, 0.1),
    impactColor: Vector3(1.0, 0.88, 0.3),
    impactSize: 0.55,
    projectileSpeed: 28.0,
    projectileSize: 0.20,
    statusEffect: StatusEffect.interrupt,
    statusDuration: 3.0,
    manaColor: ManaColor.red,
    manaCost: 20.0,
    damageSchool: DamageSchool.lightning,
    category: 'elemental',
    comboPrimes: ['Frostbite Slash', 'Ice Lance'],
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Elemental Chain — Activates chain-combo mode.
  static final elementalChain = AbilityData(
    name: 'Elemental Chain',
    description: 'Chain elemental forces through your blows — activate chain-combo mode. '
        'Land 7 elemental hits within 7 seconds to trigger a red mana surge and elemental AoE.',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 10.0,
    range: 2.5,
    color: Vector3(0.9, 0.45, 0.12),
    impactColor: Vector3(1.0, 0.58, 0.22),
    impactSize: 0.65,
    manaColor: ManaColor.red,
    manaCost: 20.0,
    damageSchool: DamageSchool.fire,
    category: 'elemental',
    enablesComboChain: true,
    comboPrimes: ['Magma Strike', 'Frostbite Slash'],
  );

  /// Elemental Attunement — Aura channeling elemental forces into damage.
  static final elementalAttunement = AbilityData(
    name: 'Elemental Attunement',
    description: 'Attune to the raw elemental forces within you, channeling their power to amplify all your attacks.',
    type: AbilityType.buff,
    cooldown: 5.0,
    duration: 3600.0,
    color: Vector3(1.0, 0.5, 0.1),
    impactColor: Vector3(1.0, 0.6, 0.2),
    impactSize: 1.2,
    statusEffect: StatusEffect.strength,
    statusStrength: 0.20,
    manaColor: ManaColor.red,
    manaCost: 25.0,
    category: 'elemental',
  );

  // ==================== CC ABILITIES ====================

  /// Magma Geyser — Erupts magma, launching enemies airborne.
  static final magmaGeyser = AbilityData(
    name: 'Magma Geyser',
    description: 'Erupts a geyser of magma at the target location, launching enemies airborne.',
    type: AbilityType.aoe,
    damage: 35.0,
    cooldown: 18.0,
    range: 12.0,
    aoeRadius: 4.0,
    color: Vector3(1.0, 0.4, 0.0),
    impactColor: Vector3(1.0, 0.55, 0.15),
    impactSize: 1.1,
    statusEffect: StatusEffect.airborne,
    statusStrength: 4.0,
    statusDuration: 1.2,
    manaColor: ManaColor.red,
    manaCost: 25.0,
    damageSchool: DamageSchool.fire,
    category: 'elemental',
  );

  /// Petrify — Encases the target in stone, freezing them in place.
  static final petrify = AbilityData(
    name: 'Petrify',
    description: 'Encases the target in living stone, freezing them in place.',
    type: AbilityType.ranged,
    cooldown: 22.0,
    range: 12.0,
    castTime: 1.0,
    color: Vector3(0.5, 0.4, 0.25),
    impactColor: Vector3(0.6, 0.5, 0.35),
    impactSize: 0.7,
    statusEffect: StatusEffect.freeze,
    statusDuration: 3.0,
    manaColor: ManaColor.red,
    manaCost: 20.0,
    secondaryManaColor: ManaColor.green,
    secondaryManaCost: 15.0,
    damageSchool: DamageSchool.nature,
    category: 'elemental',
  );

  /// Glacial Prison — Banishes the target in a prison of ice.
  static final glacialPrison = AbilityData(
    name: 'Glacial Prison',
    description: 'Encases the target in a glacial prison, phasing them out of existence.',
    type: AbilityType.ranged,
    cooldown: 30.0,
    range: 15.0,
    castTime: 1.5,
    color: Vector3(0.6, 0.85, 1.0),
    impactColor: Vector3(0.7, 0.95, 1.0),
    impactSize: 0.9,
    statusEffect: StatusEffect.banish,
    statusDuration: 3.0,
    manaColor: ManaColor.blue,
    manaCost: 25.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 10.0,
    category: 'elemental',
  );

  /// All elemental abilities as a list.
  /// Ordered short→long cooldown; slots 7-12 hold the longest cooldowns.
  static List<AbilityData> get all => [
    frostbiteSlash,      //  1  1.0s  combo opener chill
    iceLance,            //  2  3.0s  ranged piercing
    elementalAttunement, //  3  5.0s  damage aura
    flameWave,           //  4  7.0s  AoE fire line
    magmaStrike,         //  5  7.0s  melee fire reaction
    elementalChain,      //  6 10.0s  chain combo primer
    elementalRend,       //  7 12.0s  permanent vulnerability
    magmaGeyser,         //  8 18.0s  AoE airborne launch
    petrify,             //  9 22.0s  ranged freeze CC
    magneticDisrupt,     // 10 22.0s  interrupt ranged
    earthquake,          // 11 25.0s  channeled AoE stun CC
    glacialPrison,       // 12 30.0s  banish CC
  ];
}
