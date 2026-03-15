import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Necromancer abilities — Life drain, curses, and shadow combo chains.
///
/// Combo chain: Curse of Weakness → Grave Touch → Soul Scythe → Soul Rot → Life Drain.
/// Fear and Null Bolt open punish windows for the melee follow-up chain.
class NecromancerAbilities {
  NecromancerAbilities._();

  /// Life Drain — Channeled damage and heal.
  static final lifeDrain = AbilityData(
    name: 'Life Drain',
    description: 'Drains life from enemy, healing self.',
    type: AbilityType.channeled,
    damage: 6.0,
    cooldown: 10.0,
    duration: 3.0,
    range: 40.0,
    healAmount: 4.0,
    color: Vector3(0.5, 0.0, 0.2),
    impactColor: Vector3(0.6, 0.1, 0.3),
    impactSize: 0.5,
    dotTicks: 6,
    channelEffect: ChannelEffect.lifeDrain,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
    comboPrimes: ['Curse of Weakness', 'Soul Scythe'],
  );

  /// Curse of Weakness — Reduce enemy damage output.
  static final curseOfWeakness = AbilityData(
    name: 'Curse of Weakness',
    description: 'Curses enemy, reducing their damage output.',
    type: AbilityType.debuff,
    cooldown: 16.0,
    duration: 10.0,
    range: 40.0,
    color: Vector3(0.3, 0.0, 0.3),
    impactColor: Vector3(0.4, 0.1, 0.4),
    impactSize: 0.8,
    statusEffect: StatusEffect.weakness,
    statusStrength: 0.75,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
    comboPrimes: ['Soul Scythe', 'Life Drain'],
  );

  /// Fear — Makes enemy flee.
  static final fear = AbilityData(
    name: 'Fear',
    description: 'Terrifies enemy, causing them to flee.',
    type: AbilityType.debuff,
    cooldown: 20.0,
    duration: 4.0,
    range: 40.0,
    color: Vector3(0.2, 0.0, 0.2),
    impactColor: Vector3(0.3, 0.0, 0.3),
    impactSize: 0.7,
    statusEffect: StatusEffect.fear,
    statusDuration: 4.0,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
    comboPrimes: ['Soul Rot', 'Curse of Weakness'],
  );

  /// Soul Rot — Dark projectile applying a damage-over-time curse.
  static final soulRot = AbilityData(
    name: 'Soul Rot',
    description: 'Launches a bolt of necrotic energy that rots the target\'s soul, dealing damage over time.',
    type: AbilityType.dot,
    damage: 60.0,
    cooldown: 12.0,
    duration: 10.0,
    range: 40.0,
    color: Vector3(0.4, 0.1, 0.5),
    impactColor: Vector3(0.5, 0.2, 0.6),
    impactSize: 0.6,
    projectileSpeed: 10.0,
    projectileSize: 0.35,
    statusEffect: StatusEffect.poison,
    statusDuration: 10.0,
    dotTicks: 5,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
    comboPrimes: ['Life Drain', 'Soul Scythe'],
  );

  /// Summon Skeleton — Creates temporary melee ally.
  static final summonSkeleton = AbilityData(
    name: 'Summon Skeleton',
    description: 'Raises a skeleton warrior with red mana melee abilities.',
    type: AbilityType.summon,
    cooldown: 25.0,
    duration: 60.0,
    color: Vector3(0.8, 0.8, 0.7),
    impactColor: Vector3(0.9, 0.9, 0.8),
    impactSize: 1.0,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
  );

  /// Summon Skeleton Mage — Creates temporary caster ally.
  static final summonSkeletonMage = AbilityData(
    name: 'Summon Skeleton Mage',
    description: 'Raises a skeleton mage with blue mana ranged abilities.',
    type: AbilityType.summon,
    cooldown: 30.0,
    duration: 60.0,
    color: Vector3(0.5, 0.6, 0.9),
    impactColor: Vector3(0.6, 0.7, 1.0),
    impactSize: 1.0,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
  );

  // ==================== MELEE ABILITIES ====================

  /// Grave Touch — Necrotic palm strike with weakness debuff.
  static final graveTouch = AbilityData(
    name: 'Grave Touch',
    description: 'Touch the target with grave-cold hands, sapping their strength.',
    type: AbilityType.melee,
    damage: 14.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(0.4, 0.15, 0.3),
    impactColor: Vector3(0.5, 0.2, 0.4),
    impactSize: 0.5,
    statusEffect: StatusEffect.weakness,
    statusStrength: 0.8,
    statusDuration: 4.0,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
    comboPrimes: ['Soul Scythe', 'Soul Chain'],
  );

  /// Soul Scythe — Spectral scythe swing with bleed.
  static final soulScythe = AbilityData(
    name: 'Soul Scythe',
    description: 'Sweep a spectral scythe through the target, causing deep bleeding wounds.',
    type: AbilityType.melee,
    damage: 28.0,
    cooldown: 7.0,
    range: 3.0,
    color: Vector3(0.3, 0.05, 0.25),
    impactColor: Vector3(0.5, 0.1, 0.4),
    impactSize: 0.7,
    statusEffect: StatusEffect.bleed,
    statusDuration: 4.0,
    dotTicks: 2,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
    comboPrimes: ['Soul Rot', 'Null Bolt'],
  );

  /// Soul Fracture — Shadow strike applying permanent vulnerability.
  static final soulFracture = AbilityData(
    name: 'Soul Fracture',
    description: 'A shadow-infused strike that permanently exposes the target to shadow damage.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(0.4, 0.1, 0.5),
    impactColor: Vector3(0.5, 0.2, 0.6),
    impactSize: 0.6,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
    appliesPermanentVulnerability: true,
    comboPrimes: ['Soul Scythe', 'Life Drain'],
  );

  // ==================== INTERRUPT ====================

  /// Null Bolt — Void bolt that interrupts spellcasting.
  static final nullBolt = AbilityData(
    name: 'Null Bolt',
    description: 'Fire a bolt of void-null energy that interrupts the target\'s spellcasting for 3 seconds.',
    type: AbilityType.ranged,
    damage: 14.0,
    cooldown: 24.0,
    range: 20.0,
    color: Vector3(0.35, 0.05, 0.28),
    impactColor: Vector3(0.55, 0.12, 0.42),
    impactSize: 0.5,
    projectileSpeed: 26.0,
    projectileSize: 0.22,
    statusEffect: StatusEffect.interrupt,
    statusDuration: 3.0,
    manaColor: ManaColor.black,
    manaCost: 22.0,
    damageSchool: DamageSchool.shadow,
    category: 'necromancer',
    comboPrimes: ['Grave Touch', 'Soul Scythe'],
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Soul Chain — Activates chain-combo mode.
  static final soulChain = AbilityData(
    name: 'Soul Chain',
    description: 'Link your strikes with soul-chains — activate chain-combo mode. '
        'Land 7 necromancer hits within 7 seconds to trigger a red mana surge and weakness debuff.',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 10.0,
    range: 2.0,
    color: Vector3(0.35, 0.08, 0.28),
    impactColor: Vector3(0.55, 0.15, 0.45),
    impactSize: 0.55,
    manaColor: ManaColor.black,
    manaCost: 20.0,
    damageSchool: DamageSchool.shadow,
    category: 'necromancer',
    enablesComboChain: true,
    comboPrimes: ['Grave Touch', 'Soul Scythe'],
  );

  /// Death Shroud — Aura wrapping in undead protection.
  static final deathShroud = AbilityData(
    name: 'Death Shroud',
    description: 'Envelop yourself in a shroud of death energy that absorbs incoming damage.',
    type: AbilityType.buff,
    cooldown: 5.0,
    duration: 3600.0,
    color: Vector3(0.4, 0.0, 0.5),
    impactColor: Vector3(0.5, 0.1, 0.6),
    impactSize: 1.2,
    statusEffect: StatusEffect.shield,
    statusStrength: 30.0,
    manaColor: ManaColor.black,
    manaCost: 25.0,
    category: 'necromancer',
    damageSchool: DamageSchool.shadow,
  );

  /// All necromancer abilities as a list.
  /// Ordered short→long cooldown; slots 11-12 hold the longest cooldowns.
  static List<AbilityData> get all => [
    graveTouch,          //  1  1.0s  melee weakness debuff
    deathShroud,         //  2  5.0s  shield aura
    soulScythe,          //  3  7.0s  melee bleed
    soulChain,           //  4 10.0s  chain combo primer
    lifeDrain,           //  5 10.0s  channeled lifesteal
    soulRot,             //  6 12.0s  DoT ranged
    soulFracture,        //  7 12.0s  permanent vulnerability
    curseOfWeakness,     //  8 16.0s  CC damage reduction
    fear,                //  9 20.0s  CC flee
    nullBolt,            // 10 24.0s  interrupt ranged
    summonSkeleton,      // 11 25.0s  summon melee ally
    summonSkeletonMage,  // 12 30.0s  summon caster ally
  ];
}
