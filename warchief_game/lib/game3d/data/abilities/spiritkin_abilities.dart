import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Spiritkin abilities — Primal nature warriors channeling bestial fury.
///
/// Buff-then-combo playstyle: apply nature buffs, then follow up with
/// empowered melee and nature attacks. 10 abilities using Green mana
/// with several dual-mana (Green + Red) combos.
class SpiritkinAbilities {
  SpiritkinAbilities._();

  /// Primal Roar — AoE party damage buff (+25%) for 10 seconds.
  /// Empower nearby allies before engaging in melee combat.
  static final primalRoar = AbilityData(
    name: 'Primal Roar',
    description: 'Let loose a bestial roar, empowering nearby allies with +25% damage for 10 seconds',
    type: AbilityType.buff,
    cooldown: 8.0,
    color: Vector3(0.4, 0.7, 0.2),
    impactColor: Vector3(0.5, 0.8, 0.3),
    impactSize: 1.2,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.25,
    statusDuration: 10.0,
    aoeRadius: 8.0,
    manaColor: ManaColor.green,
    manaCost: 15.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Spirit Claws — Enhanced melee strike with bleed DoT.
  /// Dual-mana (Green + Red) for savage nature-infused claws.
  static final spiritClaws = AbilityData(
    name: 'Spirit Claws',
    description: 'Slash with spirit-infused claws, leaving deep wounds that bleed over time',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 5.0,
    range: 3.0,
    color: Vector3(0.6, 0.8, 0.3),
    impactColor: Vector3(0.7, 0.3, 0.2),
    impactSize: 0.6,
    statusEffect: StatusEffect.bleed,
    statusDuration: 6.0,
    dotTicks: 3,
    windupTime: 0.3,
    windupMovementSpeed: 0.5,
    manaColor: ManaColor.green,
    manaCost: 10.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 15.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Verdant Bulwark — Absorb 60 damage + thorns reflect for 12 seconds.
  /// Nature shield that punishes attackers with thorn damage.
  static final verdantBulwark = AbilityData(
    name: 'Verdant Bulwark',
    description: 'Wrap yourself in living bark that absorbs 60 damage and reflects thorn damage to attackers',
    type: AbilityType.buff,
    damage: 5.0,
    cooldown: 35.0,
    color: Vector3(0.3, 0.55, 0.2),
    impactColor: Vector3(0.4, 0.65, 0.25),
    impactSize: 1.0,
    statusEffect: StatusEffect.shield,
    statusStrength: 60.0,
    statusDuration: 12.0,
    manaColor: ManaColor.green,
    manaCost: 25.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Bloodroot Surge — Self-heal for 40 HP.
  /// Dual-mana (Green + Red) tapping into both life and blood energy.
  static final bloodrootSurge = AbilityData(
    name: 'Bloodroot Surge',
    description: 'Channel primal life force through bloodroot tendrils, restoring 40 HP',
    type: AbilityType.heal,
    cooldown: 10.0,
    healAmount: 40.0,
    color: Vector3(0.5, 0.7, 0.25),
    impactColor: Vector3(0.6, 0.4, 0.3),
    impactSize: 0.8,
    manaColor: ManaColor.green,
    manaCost: 20.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 10.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Feral Lunge — Gap-closer melee with knockback.
  /// Leap at a target and slam them backward with bestial force.
  static final feralLunge = AbilityData(
    name: 'Feral Lunge',
    description: 'Lunge at a distant enemy with feral fury, knocking them back on impact',
    type: AbilityType.melee,
    damage: 25.0,
    cooldown: 7.0,
    range: 8.0,
    color: Vector3(0.7, 0.3, 0.2),
    impactColor: Vector3(0.8, 0.4, 0.25),
    impactSize: 0.7,
    knockbackForce: 3.0,
    manaColor: ManaColor.red,
    manaCost: 20.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Aspect of the Beast — Transform into spirit beast form.
  /// Dual-mana (Green + Red) ultimate: +50% damage, +30% speed for 20 seconds.
  static final aspectOfTheBeast = AbilityData(
    name: 'Aspect of the Beast',
    description: 'Transform into a primal spirit beast — +50% damage and +30% movement speed for 20 seconds',
    type: AbilityType.summon,
    cooldown: 120.0,
    duration: 20.0,
    color: Vector3(0.55, 0.75, 0.2),
    impactColor: Vector3(0.65, 0.85, 0.3),
    impactSize: 1.5,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.5,
    statusDuration: 20.0,
    manaColor: ManaColor.green,
    manaCost: 50.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 30.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Vine Lash — Nature whip projectile that roots the target for 3 seconds.
  static final vineLash = AbilityData(
    name: 'Vine Lash',
    description: 'Lash out with a thorned vine projectile that roots the target in place for 3 seconds',
    type: AbilityType.ranged,
    damage: 15.0,
    cooldown: 6.0,
    range: 30.0,
    color: Vector3(0.35, 0.6, 0.15),
    impactColor: Vector3(0.45, 0.7, 0.2),
    impactSize: 0.5,
    projectileSpeed: 15.0,
    projectileSize: 0.2,
    statusEffect: StatusEffect.root,
    statusDuration: 3.0,
    manaColor: ManaColor.green,
    manaCost: 15.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Nature's Cataclysm — Massive AoE nature+fire damage.
  /// Dual-mana (Green + Red) for devastating combined elemental burst.
  static final naturesCataclysm = AbilityData(
    name: "Nature's Cataclysm",
    description: 'Unleash a cataclysmic eruption of nature and fire energy, devastating all enemies in the area',
    type: AbilityType.aoe,
    damage: 45.0,
    cooldown: 18.0,
    color: Vector3(0.6, 0.7, 0.15),
    impactColor: Vector3(0.8, 0.5, 0.2),
    impactSize: 1.4,
    aoeRadius: 6.0,
    manaColor: ManaColor.green,
    manaCost: 30.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 25.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Regenerative Bark — HoT on self or ally, 30 HP over 10 seconds.
  /// Gentle nature magic that mends wounds over time.
  static final regenerativeBark = AbilityData(
    name: 'Regenerative Bark',
    description: 'Coat a target in regenerative bark that heals 30 HP over 10 seconds',
    type: AbilityType.buff,
    cooldown: 12.0,
    healAmount: 30.0,
    color: Vector3(0.45, 0.65, 0.3),
    impactColor: Vector3(0.5, 0.75, 0.35),
    impactSize: 0.8,
    statusEffect: StatusEffect.regen,
    statusDuration: 10.0,
    dotTicks: 5,
    manaColor: ManaColor.green,
    manaCost: 20.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Totem of the Wild — Place a spirit totem that buffs nearby allies.
  /// +15% damage to allies within 8 yards for 15 seconds.
  static final totemOfTheWild = AbilityData(
    name: 'Totem of the Wild',
    description: 'Plant a spirit totem that empowers nearby allies with +15% damage for 15 seconds',
    type: AbilityType.summon,
    cooldown: 25.0,
    duration: 15.0,
    color: Vector3(0.5, 0.6, 0.25),
    impactColor: Vector3(0.6, 0.7, 0.3),
    impactSize: 1.0,
    statusEffect: StatusEffect.strength,
    statusStrength: 1.15,
    statusDuration: 15.0,
    aoeRadius: 8.0,
    manaColor: ManaColor.green,
    manaCost: 40.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  // ==================== MELEE COMBO ABILITIES ====================
  // Combo: Thornbite -> Barkhide Slam -> Bloodfang Rush -> Primal Rend

  /// Thornbite — Quick bite with nature DoT
  static final thornbite = AbilityData(
    name: 'Thornbite',
    description: 'Snap with thorn-laced jaws, applying a nature poison',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 2.0,
    range: 2.0,
    color: Vector3(0.4, 0.65, 0.2),
    impactColor: Vector3(0.5, 0.75, 0.3),
    impactSize: 0.4,
    statusEffect: StatusEffect.poison,
    statusDuration: 3.0,
    dotTicks: 2,
    manaColor: ManaColor.green,
    manaCost: 6.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Barkhide Slam — Bark-hardened fist slam that slows
  static final barkhideSlam = AbilityData(
    name: 'Barkhide Slam',
    description: 'Slam with a bark-encased fist, slowing the target',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 4.5,
    range: 2.5,
    color: Vector3(0.45, 0.55, 0.25),
    impactColor: Vector3(0.55, 0.65, 0.3),
    impactSize: 0.6,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    manaColor: ManaColor.green,
    manaCost: 10.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Bloodfang Rush — Gap-closer with forward movement
  static final bloodfangRush = AbilityData(
    name: 'Bloodfang Rush',
    description: 'Charge forward in a blood-fueled feral rush to close the gap',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 5.0,
    range: 7.0,
    color: Vector3(0.7, 0.25, 0.2),
    impactColor: Vector3(0.8, 0.3, 0.25),
    impactSize: 0.5,
    manaColor: ManaColor.red,
    manaCost: 15.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Primal Rend — Dual-mana finisher with windup and bleed
  static final primalRend = AbilityData(
    name: 'Primal Rend',
    description: 'Channel primal fury into a savage rending strike that causes deep bleeding',
    type: AbilityType.melee,
    damage: 38.0,
    cooldown: 9.0,
    range: 3.0,
    color: Vector3(0.6, 0.5, 0.2),
    impactColor: Vector3(0.7, 0.3, 0.15),
    impactSize: 0.8,
    statusEffect: StatusEffect.bleed,
    statusDuration: 5.0,
    dotTicks: 3,
    windupTime: 0.6,
    windupMovementSpeed: 0.4,
    manaColor: ManaColor.green,
    manaCost: 15.0,
    secondaryManaColor: ManaColor.red,
    secondaryManaCost: 10.0,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Basic no-mana melee: claw attack
  static final clawRake = AbilityData(
    name: 'Claw Rake',
    description: 'A quick, manaless claw rake.',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(0.5, 0.8, 0.3),
    impactColor: Vector3(0.6, 0.9, 0.4),
    impactSize: 0.4,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Basic no-mana melee: fang snap
  static final fangSnap = AbilityData(
    name: 'Fang Snap',
    description: 'A vicious bite attack.',
    type: AbilityType.melee,
    damage: 14.0,
    cooldown: 1.0,
    range: 2.5,
    color: Vector3(0.4, 0.7, 0.2),
    impactColor: Vector3(0.5, 0.8, 0.3),
    impactSize: 0.5,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
  );

  /// Medium-cooldown permanent nature vulnerability
  static final naturesMark = AbilityData(
    name: 'Nature\'s Mark',
    description: 'A nature-infused strike that permanently exposes the target to nature damage.',
    type: AbilityType.melee,
    damage: 8.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(0.3, 0.7, 0.1),
    impactColor: Vector3(0.4, 0.8, 0.2),
    impactSize: 0.6,
    category: 'spiritkin',
    damageSchool: DamageSchool.nature,
    appliesPermanentVulnerability: true,
  );

  /// All spiritkin abilities as a list
  static List<AbilityData> get all => [
    primalRoar,
    spiritClaws,
    verdantBulwark,
    bloodrootSurge,
    feralLunge,
    aspectOfTheBeast,
    vineLash,
    naturesCataclysm,
    regenerativeBark,
    totemOfTheWild,
    thornbite,
    barkhideSlam,
    bloodfangRush,
    primalRend,
    clawRake,
    fangSnap,
    naturesMark,
  ];
}
