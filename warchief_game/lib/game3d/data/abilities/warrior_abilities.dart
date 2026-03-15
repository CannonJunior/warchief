import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Warrior/Tank abilities - Melee combat and defensive skills
class WarriorAbilities {
  WarriorAbilities._();

  /// Shield Bash - Melee stun attack
  static final shieldBash = AbilityData(
    name: 'Shield Bash',
    description: 'Strikes enemy with shield, stunning them briefly',
    type: AbilityType.melee,
    damage: 15.0,
    cooldown: 6.0,
    duration: 0.3,
    range: 1.5,
    color: Vector3(0.6, 0.6, 0.7),
    impactColor: Vector3(1.0, 1.0, 0.5),
    impactSize: 0.6,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.5,
    category: 'warrior',
    // Stunned target is wide open for Whirlwind or Gauntlet Jab follow-up.
    comboPrimes: ['Whirlwind', 'Gauntlet Jab'],
  );

  /// Whirlwind - Spinning AoE attack
  static final whirlwind = AbilityData(
    name: 'Whirlwind',
    description: 'Spins with weapon extended, damaging all nearby enemies',
    type: AbilityType.aoe,
    damage: 25.0,
    cooldown: 8.0,
    duration: 1.0,
    range: 3.0,
    color: Vector3(0.8, 0.8, 0.8),
    impactColor: Vector3(0.9, 0.9, 0.9),
    impactSize: 0.4,
    aoeRadius: 3.0,
    maxTargets: 5,
    category: 'warrior',
    // Scattered/slowed enemies are perfect targets for chain follow-up.
    comboPrimes: ['Rending Chains'],
  );

  /// Charge - Rush forward and knockback
  static final charge = AbilityData(
    name: 'Charge',
    description: 'Rushes toward enemy, knocking them back on impact',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 10.0,
    duration: 0.5,
    range: 8.0,
    color: Vector3(0.9, 0.7, 0.3),
    impactColor: Vector3(1.0, 0.8, 0.4),
    impactSize: 0.8,
    knockbackForce: 5.0,
    category: 'warrior',
    // Closing the gap naturally leads into a bash or jab opener.
    comboPrimes: ['Shield Bash', 'Gauntlet Jab'],
  );

  /// Taunt - Forces enemies to attack you
  static final taunt = AbilityData(
    name: 'Taunt',
    description: 'Forces nearby enemies to focus attacks on you',
    type: AbilityType.debuff,
    cooldown: 12.0,
    duration: 4.0,
    range: 40.0,
    color: Vector3(1.0, 0.3, 0.3),
    impactColor: Vector3(1.0, 0.2, 0.2),
    impactSize: 1.0,
    aoeRadius: 6.0,
    maxTargets: 3,
    category: 'warrior',
    // Taunted enemies cluster around you — Whirlwind punishes the crowd.
    comboPrimes: ['Whirlwind'],
  );

  /// Fortify - Defensive shield buff
  static final fortify = AbilityData(
    name: 'Fortify',
    description: 'Raises shield to absorb incoming damage',
    type: AbilityType.buff,
    cooldown: 15.0,
    duration: 5.0,
    color: Vector3(0.4, 0.6, 0.9),
    impactColor: Vector3(0.5, 0.7, 1.0),
    impactSize: 1.2,
    statusEffect: StatusEffect.shield,
    statusStrength: 50.0,
    category: 'warrior',
  );

  // ==================== MELEE COMBO CHAIN ====================
  // Designed flow: Gauntlet Jab → Iron Sweep → Rending Chains → Warcry Uppercut → Execution Strike

  /// Gauntlet Jab — Fast combo starter, short cooldown
  static final gauntletJab = AbilityData(
    name: 'Gauntlet Jab',
    description: 'Quick armored fist jab — fast combo starter',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 1.0,
    range: 2.0,
    color: Vector3(0.7, 0.7, 0.7),
    impactColor: Vector3(0.8, 0.8, 0.8),
    impactSize: 0.4,
    category: 'warrior',
    // First link in the melee chain.
    comboPrimes: ['Iron Sweep'],
  );

  /// Iron Sweep — Low sweep that slows the target
  static final ironSweep = AbilityData(
    name: 'Iron Sweep',
    description: 'Low sweeping kick with iron greaves, slowing the target',
    type: AbilityType.melee,
    damage: 18.0,
    cooldown: 1.0,
    range: 2.5,
    color: Vector3(0.6, 0.6, 0.65),
    impactColor: Vector3(0.7, 0.7, 0.75),
    impactSize: 0.5,
    statusEffect: StatusEffect.slow,
    statusDuration: 2.0,
    category: 'warrior',
    // Slowed target can't escape the chain follow-up.
    comboPrimes: ['Rending Chains'],
  );

  /// Rending Chains — Chain whip with extended reach and bleed DoT
  static final rendingChains = AbilityData(
    name: 'Rending Chains',
    description: 'Lash out with spiked chains, rending flesh and causing bleed',
    type: AbilityType.melee,
    damage: 22.0,
    cooldown: 6.0,
    range: 3.5,
    color: Vector3(0.5, 0.5, 0.55),
    impactColor: Vector3(0.8, 0.3, 0.2),
    impactSize: 0.6,
    statusEffect: StatusEffect.bleed,
    statusDuration: 4.0,
    dotTicks: 2,
    category: 'warrior',
    // Bleeding target is primed for the uppercut to launch them.
    comboPrimes: ['Warcry Uppercut'],
  );

  /// Warcry Uppercut — Launcher with stun and knockback, moves forward
  static final warcryUppercut = AbilityData(
    name: 'Warcry Uppercut',
    description: 'Bellowing war cry followed by a devastating uppercut that launches the target',
    type: AbilityType.melee,
    damage: 28.0,
    cooldown: 7.0,
    range: 2.0,
    color: Vector3(0.9, 0.7, 0.3),
    impactColor: Vector3(1.0, 0.8, 0.4),
    impactSize: 0.7,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.0,
    knockbackForce: 2.0,
    category: 'warrior',
    // Stunned airborne target cannot dodge the finisher.
    comboPrimes: ['Execution Strike'],
  );

  /// Execution Strike — Heavy windup combo finisher
  static final executionStrike = AbilityData(
    name: 'Execution Strike',
    description: 'Wind up a devastating overhead strike to finish the combo',
    type: AbilityType.melee,
    damage: 45.0,
    cooldown: 10.0,
    range: 2.5,
    color: Vector3(0.8, 0.2, 0.2),
    impactColor: Vector3(1.0, 0.3, 0.1),
    impactSize: 0.9,
    windupTime: 0.8,
    windupMovementSpeed: 0.3,
    category: 'warrior',
    // Finisher — no further primes.
  );

  /// Sunder Armor — Crushing strike that permanently exposes physical weakness
  static final sunderArmor = AbilityData(
    name: 'Sunder Armor',
    description: 'A crushing strike that permanently exposes the target\'s weakness to physical damage.',
    type: AbilityType.melee,
    damage: 10.0,
    cooldown: 12.0,
    range: 2.5,
    color: Vector3(0.7, 0.5, 0.3),
    impactColor: Vector3(0.8, 0.6, 0.4),
    impactSize: 0.6,
    category: 'warrior',
    appliesPermanentVulnerability: true,
    // Exposed armor invites the highest-damage finisher.
    comboPrimes: ['Execution Strike'],
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Iron Momentum — Activates chain-combo mode for warriors.
  /// Land 7 consecutive warrior strikes within 7 seconds to fire the chain combo.
  static final ironMomentum = AbilityData(
    name: 'Iron Momentum',
    description: 'Channel iron resolve — activate chain-combo mode. '
        'Land 7 warrior strikes within 7 seconds to trigger a devastating AoE knockback.',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 10.0,
    range: 2.0,
    color: Vector3(0.75, 0.6, 0.3),
    impactColor: Vector3(0.9, 0.75, 0.4),
    impactSize: 0.6,
    manaColor: ManaColor.red,
    manaCost: 20.0,
    category: 'warrior',
    enablesComboChain: true,
    // Momentum build-up drops GCD on both chain starters.
    comboPrimes: ['Gauntlet Jab', 'Whirlwind'],
  );

  /// Pummel — Shield punch that interrupts spellcasting
  static final pummel = AbilityData(
    name: 'Pummel',
    description: 'Drive your shield into the caster\'s jaw, interrupting their spellcasting for 3 seconds',
    type: AbilityType.melee,
    damage: 12.0,
    cooldown: 12.0,
    range: 2.0,
    color: Vector3(0.6, 0.6, 0.7),
    impactColor: Vector3(0.9, 0.85, 0.6),
    impactSize: 0.5,
    statusEffect: StatusEffect.interrupt,
    statusDuration: 3.0,
    category: 'warrior',
    damageSchool: DamageSchool.physical,
    // Interrupting a cast puts the enemy off-balance for a bash.
    comboPrimes: ['Shield Bash'],
  );

  /// Battle Presence — Warrior aura granting +25% damage to all nearby allies
  static final battlePresence = AbilityData(
    name: 'Battle Presence',
    description: 'The warrior\'s fighting spirit radiates outward, granting nearby '
        'allies increased combat damage for as long as the warrior stands strong.',
    type: AbilityType.buff,
    cooldown: 5.0,
    duration: 3600.0,
    color: Vector3(0.9, 0.2, 0.2),
    impactColor: Vector3(1.0, 0.3, 0.3),
    impactSize: 1.2,
    statusEffect: StatusEffect.strength,
    statusStrength: 0.25,
    manaColor: ManaColor.red,
    manaCost: 30.0,
    category: 'warrior',
    isAura: true,
    auraRange: 10.0,
  );

  /// All warrior abilities as a list
  /// Ordered short→long cooldown; slots 11-14 hold the longest cooldowns.
  static List<AbilityData> get all => [
    gauntletJab,      //  1  1.0s  combo starter
    ironSweep,        //  2  1.0s  combo 2 slow
    battlePresence,   //  3  5.0s  damage aura
    shieldBash,       //  4  6.0s  CC stun
    rendingChains,    //  5  6.0s  combo 3 bleed
    warcryUppercut,   //  6  7.0s  combo 4 stun + knockback
    whirlwind,        //  7  8.0s  AoE
    executionStrike,  //  8 10.0s  combo finisher
    ironMomentum,     //  9 10.0s  chain combo primer
    charge,           // 10 10.0s  gap closer knockback
    sunderArmor,      // 11 12.0s  permanent vulnerability
    pummel,           // 12 12.0s  interrupt
    taunt,            // 13 12.0s  CC aggro debuff
    fortify,          // 14 15.0s  buff shield
  ];
}
