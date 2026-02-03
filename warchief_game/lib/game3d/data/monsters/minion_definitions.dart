/// Minion Definitions - The 4 core minion types
///
/// These represent classic humanoid adversaries from ancient mythology:
/// 1. Gnoll Marauder (DPS) - Monster Power 4
/// 2. Satyr Hexblade (Support) - Monster Power 5
/// 3. Dryad Lifebinder (Healer) - Monster Power 6
/// 4. Minotaur Bulwark (Tank) - Monster Power 7
///
/// Ability Coverage:
/// - Melee: Gnoll (Rending Bite, Savage Leap), Minotaur (Gore Charge, Earthshaker)
/// - Range: Satyr (Cursed Blade projectile)
/// - Magic: Satyr (Discordant Pipes), Dryad (all abilities)
/// - Buffs: Satyr (Wild Revelry), Gnoll (Pack Howl), Minotaur (Labyrinthine Fortitude)
/// - Debuffs: Gnoll (Rending Bite bleed), Satyr (Discordant Pipes, Cursed Blade)
/// - Auras: Satyr (Discordant Pipes), Dryad (Rejuvenation Aura), Minotaur (Intimidating Presence)
/// - Specialized: Dryad (Entangling Roots CC, Bark Shield)

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../../models/monster_ontology.dart';

/// All minion type definitions
class MinionDefinitions {
  MinionDefinitions._();

  // ============================================================
  // GNOLL MARAUDER - DPS Archetype (Monster Power 4)
  // ============================================================
  // Savage hyena-humanoid pack hunter
  // High damage output with bleed effects
  // Historic: African folklore, D&D classic
  // Modern: Aggressive melee berserker with pack tactics
  //
  // Abilities:
  // - Rending Bite: Melee attack that causes bleeding (debuff)
  // - Pack Howl: Self-buff increasing damage
  // - Savage Leap: Gap-closing melee strike
  // ============================================================
  static MonsterDefinition get gnollMarauder => MonsterDefinition(
    id: 'gnoll_marauder',
    name: 'Gnoll Marauder',
    description: 'A savage hyena-headed humanoid that hunts in packs. '
        'Its powerful jaws can rend flesh and cause grievous bleeding wounds. '
        'When it howls, nearby pack members become frenzied with bloodlust.',
    archetype: MonsterArchetype.dps,
    faction: MonsterFaction.beast,
    size: MonsterSize.medium,

    // Stats - High damage, moderate health, fast
    baseHealth: 45,
    baseDamage: 14,
    moveSpeed: 4.0,       // Fast predator
    attackRange: 2.0,     // Melee bite range
    aggroRange: 12.0,     // Keen senses

    // Monster Power 4 (DPS)
    monsterPower: 4,

    // Visual - Tawny brown fur with dark mane
    modelColor: Vector3(0.6, 0.45, 0.25),   // Tawny brown
    accentColor: Vector3(0.3, 0.2, 0.1),    // Dark brown mane
    modelScale: 1.0,
    portraitEmoji: '\u{1F43A}', // Wolf face (closest to hyena)

    // AI Behavior - Aggressive pack hunter
    aggressiveness: 0.95,  // Extremely aggressive
    groupTendency: 0.85,   // Strong pack instinct
    canFlee: true,
    fleeHealthThreshold: 0.15, // Only flees when nearly dead

    // Abilities (all 60+ second cooldowns)
    abilities: [
      // MELEE + DEBUFF: Rending Bite
      MonsterAbilityDefinition(
        id: 'rending_bite',
        name: 'Rending Bite',
        description: 'Savage bite that tears flesh, causing the target to bleed '
            'for additional damage over 10 seconds.',
        damage: 20,
        cooldown: 60.0,     // 1 minute cooldown
        range: 2.0,
        targetType: AbilityTargetType.singleEnemy,
        effectColor: const Color(0xFFCC0000),
        buffAmount: 3.0,    // Bleed damage per tick
        buffDuration: 10.0, // Bleed duration
      ),
      // BUFF: Pack Howl (self-buff)
      MonsterAbilityDefinition(
        id: 'pack_howl',
        name: 'Pack Howl',
        description: 'Lets loose a bloodcurdling howl that drives the Gnoll into '
            'a frenzy, increasing damage dealt by 75% for 15 seconds.',
        cooldown: 90.0,     // 1.5 minute cooldown
        range: 0,           // Self-cast
        castTime: 1.0,
        targetType: AbilityTargetType.self,
        effectColor: const Color(0xFFFF6600),
        buffAmount: 1.75,   // 75% damage increase
        buffDuration: 15.0,
      ),
      // MELEE: Savage Leap (gap closer)
      MonsterAbilityDefinition(
        id: 'savage_leap',
        name: 'Savage Leap',
        description: 'Leaps at a distant target with tremendous force, closing '
            'the gap and dealing heavy damage on impact.',
        damage: 25,
        cooldown: 75.0,     // 1.25 minute cooldown
        range: 8.0,         // Long leap range
        targetType: AbilityTargetType.singleEnemy,
        effectColor: const Color(0xFFFFAA00),
      ),
    ],
  );

  // ============================================================
  // SATYR HEXBLADE - Support Archetype (Monster Power 5)
  // ============================================================
  // Fey goat-humanoid wielding wild magic
  // Debuffs enemies, buffs allies through enchanted music
  // Historic: Greek mythology, woodland trickster
  // Modern: Bard-like support with curse magic
  //
  // Abilities:
  // - Discordant Pipes: AoE debuff aura reducing enemy damage
  // - Wild Revelry: Buff allies with attack speed
  // - Cursed Blade: Ranged magic projectile with curse effect
  // ============================================================
  static MonsterDefinition get satyrHexblade => MonsterDefinition(
    id: 'satyr_hexblade',
    name: 'Satyr Hexblade',
    description: 'A goat-legged fey creature that weaves wild magic through '
        'haunting pipe melodies. Its enchanted blade can hurl curses from afar, '
        'while its music strengthens allies and weakens foes.',
    archetype: MonsterArchetype.support,
    faction: MonsterFaction.beast, // Fey/beast hybrid
    size: MonsterSize.medium,

    // Stats - Balanced, stays at range
    baseHealth: 55,
    baseDamage: 10,
    moveSpeed: 3.5,       // Nimble but not rushing
    attackRange: 8.0,     // Prefers range
    aggroRange: 14.0,     // Keen fey senses

    // Monster Power 5 (Support)
    monsterPower: 5,

    // Visual - Russet fur with purple magical glow
    modelColor: Vector3(0.55, 0.35, 0.25),  // Russet brown fur
    accentColor: Vector3(0.6, 0.3, 0.7),    // Purple magic
    modelScale: 1.0,
    portraitEmoji: '\u{1F3B6}', // Musical notes

    // AI Behavior - Tactical support, avoids direct combat
    aggressiveness: 0.4,   // Prefers to support
    groupTendency: 0.95,   // Always with allies
    canFlee: true,
    fleeHealthThreshold: 0.35,

    // Abilities (all 60+ second cooldowns)
    abilities: [
      // AURA + DEBUFF: Discordant Pipes
      MonsterAbilityDefinition(
        id: 'discordant_pipes',
        name: 'Discordant Pipes',
        description: 'Plays a jarring, discordant melody that creates an aura of '
            'dissonance. All enemies within range deal 40% less damage for 20 seconds.',
        cooldown: 90.0,     // 1.5 minute cooldown
        range: 10.0,        // Large aura radius
        castTime: 2.0,      // Channel time
        targetType: AbilityTargetType.allEnemies,
        effectColor: const Color(0xFF9933CC),
        buffAmount: 0.6,    // 40% damage reduction (enemies deal 60%)
        buffDuration: 20.0,
      ),
      // BUFF: Wild Revelry
      MonsterAbilityDefinition(
        id: 'wild_revelry',
        name: 'Wild Revelry',
        description: 'Plays an intoxicating tune that fills allies with wild energy, '
            'increasing their attack speed by 50% for 18 seconds.',
        cooldown: 75.0,     // 1.25 minute cooldown
        range: 12.0,        // Wide buff range
        castTime: 1.5,
        targetType: AbilityTargetType.allAllies,
        effectColor: const Color(0xFF33FF66),
        buffAmount: 1.5,    // 50% attack speed increase
        buffDuration: 18.0,
      ),
      // RANGED MAGIC + DEBUFF: Cursed Blade
      MonsterAbilityDefinition(
        id: 'cursed_blade',
        name: 'Cursed Blade',
        description: 'Hurls a spectral blade infused with fey curses. The blade '
            'deals magic damage and hexes the target, reducing their healing received by 50%.',
        damage: 18,
        cooldown: 60.0,     // 1 minute cooldown
        range: 12.0,
        targetType: AbilityTargetType.singleEnemy,
        effectColor: const Color(0xFF7733FF),
        isProjectile: true,
        projectileSpeed: 10.0,
        buffAmount: 0.5,    // 50% healing reduction
        buffDuration: 12.0,
      ),
    ],
  );

  // ============================================================
  // DRYAD LIFEBINDER - Healer Archetype (Monster Power 6)
  // ============================================================
  // Nature spirit bound to ancient trees
  // Powerful healing and protective abilities
  // Historic: Greek mythology, forest guardian
  // Modern: HoT healer with crowd control
  //
  // Abilities:
  // - Nature's Embrace: Strong single-target heal
  // - Rejuvenation Aura: HoT aura for all nearby allies
  // - Entangling Roots: CC that immobilizes enemies
  // - Bark Shield: Damage absorption shield
  // ============================================================
  static MonsterDefinition get dryadLifebinder => MonsterDefinition(
    id: 'dryad_lifebinder',
    name: 'Dryad Lifebinder',
    description: 'A graceful nature spirit whose essence is bound to the ancient '
        'forests. She channels the vitality of the world-tree to mend wounds, '
        'while her roots can ensnare those who threaten her grove.',
    archetype: MonsterArchetype.healer,
    faction: MonsterFaction.elemental, // Nature elemental
    size: MonsterSize.medium,

    // Stats - Fragile but powerful healing
    baseHealth: 50,
    baseDamage: 6,
    moveSpeed: 3.0,       // Graceful but not fast
    attackRange: 14.0,    // Long healing range
    aggroRange: 16.0,     // Attuned to nature

    // Monster Power 6 (Healer)
    monsterPower: 6,

    // Visual - Bark brown with vibrant green leaves
    modelColor: Vector3(0.45, 0.35, 0.25),  // Bark brown
    accentColor: Vector3(0.3, 0.75, 0.3),   // Vibrant green
    modelScale: 1.0,
    portraitEmoji: '\u{1F333}', // Deciduous tree

    // AI Behavior - Avoids combat, focuses on healing
    aggressiveness: 0.15,  // Very passive
    groupTendency: 1.0,    // Always protects allies
    canFlee: true,
    fleeHealthThreshold: 0.45, // Flees early to keep healing

    // Abilities (all 60+ second cooldowns)
    abilities: [
      // MAGIC HEAL: Nature's Embrace
      MonsterAbilityDefinition(
        id: 'natures_embrace',
        name: 'Nature\'s Embrace',
        description: 'Wraps a wounded ally in healing vines and flowers, '
            'restoring a large amount of health instantly.',
        healing: 45,
        cooldown: 60.0,     // 1 minute cooldown
        range: 14.0,
        castTime: 2.0,
        targetType: AbilityTargetType.singleAlly,
        effectColor: const Color(0xFF44DD44),
      ),
      // AURA + HEAL: Rejuvenation Aura
      MonsterAbilityDefinition(
        id: 'rejuvenation_aura',
        name: 'Rejuvenation Aura',
        description: 'Creates a field of life energy that heals all allies within '
            'range for moderate amount every 2 seconds for 24 seconds.',
        healing: 8,         // Per tick
        cooldown: 120.0,    // 2 minute cooldown
        range: 10.0,
        castTime: 2.5,
        targetType: AbilityTargetType.allAllies,
        effectColor: const Color(0xFF88FF88),
        buffDuration: 24.0, // Aura duration
      ),
      // SPECIALIZED CC: Entangling Roots
      MonsterAbilityDefinition(
        id: 'entangling_roots',
        name: 'Entangling Roots',
        description: 'Summons grasping roots from the earth that immobilize all '
            'enemies in the area for 6 seconds, preventing movement.',
        cooldown: 90.0,     // 1.5 minute cooldown
        range: 12.0,
        castTime: 1.5,
        targetType: AbilityTargetType.areaOfEffect,
        effectColor: const Color(0xFF556B2F),
        buffDuration: 6.0,  // Root duration
      ),
      // SPECIALIZED SHIELD: Bark Shield
      MonsterAbilityDefinition(
        id: 'bark_shield',
        name: 'Bark Shield',
        description: 'Encases an ally in protective bark that absorbs damage. '
            'The shield absorbs up to 40 damage before breaking.',
        cooldown: 75.0,     // 1.25 minute cooldown
        range: 14.0,
        castTime: 1.0,
        targetType: AbilityTargetType.singleAlly,
        effectColor: const Color(0xFF8B4513),
        buffAmount: 40,     // Shield HP
        buffDuration: 30.0, // Shield duration if not broken
      ),
    ],
  );

  // ============================================================
  // MINOTAUR BULWARK - Tank Archetype (Monster Power 7)
  // ============================================================
  // Massive bull-headed guardian of ancient labyrinths
  // Extremely high durability with crowd control
  // Historic: Greek mythology, labyrinth guardian
  // Modern: Aggro tank with charge and AoE stun
  //
  // Abilities:
  // - Gore Charge: Gap-closing melee charge attack
  // - Intimidating Presence: Taunt aura forcing enemies to attack
  // - Labyrinthine Fortitude: Massive damage reduction self-buff
  // - Earthshaker: AoE melee stun
  // ============================================================
  static MonsterDefinition get minotaurBulwark => MonsterDefinition(
    id: 'minotaur_bulwark',
    name: 'Minotaur Bulwark',
    description: 'A towering bull-headed giant that has guarded forgotten '
        'labyrinths since ancient times. Its thunderous charge can shatter '
        'shield walls, and its mere presence strikes fear into the bravest hearts.',
    archetype: MonsterArchetype.tank,
    faction: MonsterFaction.beast,
    size: MonsterSize.large,

    // Stats - Extremely high health, slow but powerful
    baseHealth: 150,
    baseDamage: 12,
    moveSpeed: 2.2,       // Slow and heavy
    attackRange: 2.5,     // Large melee reach
    aggroRange: 12.0,

    // Monster Power 7 (Tank)
    monsterPower: 7,

    // Visual - Dark brown hide with brass-colored horns
    modelColor: Vector3(0.35, 0.25, 0.2),   // Dark brown hide
    accentColor: Vector3(0.7, 0.55, 0.3),   // Brass horns
    modelScale: 1.2,      // Larger than medium
    portraitEmoji: '\u{1F402}', // Ox (closest to bull/minotaur)

    // AI Behavior - Aggressive defender, never retreats
    aggressiveness: 0.85,  // Aggressive but measured
    groupTendency: 0.75,   // Protects others
    canFlee: false,        // Minotaurs never flee
    fleeHealthThreshold: 0.0,

    // Abilities (all 60+ second cooldowns)
    abilities: [
      // MELEE + GAP CLOSER: Gore Charge
      MonsterAbilityDefinition(
        id: 'gore_charge',
        name: 'Gore Charge',
        description: 'Lowers its massive horns and charges at a target, dealing '
            'devastating damage and knocking them back.',
        damage: 30,
        cooldown: 60.0,     // 1 minute cooldown
        range: 10.0,        // Long charge range
        targetType: AbilityTargetType.singleEnemy,
        effectColor: const Color(0xFFBB8844),
      ),
      // AURA + TAUNT: Intimidating Presence
      MonsterAbilityDefinition(
        id: 'intimidating_presence',
        name: 'Intimidating Presence',
        description: 'Lets out a terrifying bellow that forces all nearby enemies '
            'to focus their attacks on the Minotaur for 8 seconds.',
        cooldown: 90.0,     // 1.5 minute cooldown
        range: 8.0,
        castTime: 1.0,
        targetType: AbilityTargetType.allEnemies,
        effectColor: const Color(0xFFFFCC00),
        buffDuration: 8.0,  // Taunt duration
      ),
      // BUFF: Labyrinthine Fortitude (self damage reduction)
      MonsterAbilityDefinition(
        id: 'labyrinthine_fortitude',
        name: 'Labyrinthine Fortitude',
        description: 'Channels the ancient power of the labyrinth, reducing all '
            'incoming damage by 60% for 12 seconds.',
        cooldown: 120.0,    // 2 minute cooldown
        range: 0,
        targetType: AbilityTargetType.self,
        effectColor: const Color(0xFF666699),
        buffAmount: 0.4,    // Takes only 40% damage (60% reduction)
        buffDuration: 12.0,
      ),
      // MELEE AOE + CC: Earthshaker
      MonsterAbilityDefinition(
        id: 'earthshaker',
        name: 'Earthshaker',
        description: 'Slams the ground with tremendous force, dealing damage to '
            'all nearby enemies and stunning them for 3 seconds.',
        damage: 18,
        cooldown: 90.0,     // 1.5 minute cooldown
        range: 4.0,         // AoE radius
        castTime: 1.5,      // Wind-up time
        targetType: AbilityTargetType.areaOfEffect,
        effectColor: const Color(0xFF8B7355),
        buffDuration: 3.0,  // Stun duration
      ),
    ],
  );

  // ============================================================
  // BOSS MONSTER - Existing boss for reference
  // ============================================================
  static MonsterDefinition get bossMonster => MonsterDefinition(
    id: 'boss_monster',
    name: 'Boss Monster',
    description: 'A powerful boss creature. Elite difficulty.',
    archetype: MonsterArchetype.boss,
    faction: MonsterFaction.boss,
    size: MonsterSize.huge,

    baseHealth: 200,
    baseDamage: 20,
    moveSpeed: 2.5,
    attackRange: 3.0,
    aggroRange: 15.0,

    monsterPower: 9,

    modelColor: Vector3(0.6, 0.2, 0.8),     // Purple (existing)
    accentColor: Vector3(0.8, 0.4, 1.0),
    modelScale: 1.0,
    portraitEmoji: '\u{1F47E}', // Alien monster

    aggressiveness: 1.0,
    groupTendency: 0.0,
    canFlee: false,
    fleeHealthThreshold: 0.0,

    abilities: [], // Uses existing boss abilities
  );

  /// Get all minion definitions
  static List<MonsterDefinition> get allMinions => [
    gnollMarauder,
    satyrHexblade,
    dryadLifebinder,
    minotaurBulwark,
  ];

  /// Get minion by ID
  static MonsterDefinition? getById(String id) {
    switch (id) {
      case 'gnoll_marauder':
        return gnollMarauder;
      case 'satyr_hexblade':
        return satyrHexblade;
      case 'dryad_lifebinder':
        return dryadLifebinder;
      case 'minotaur_bulwark':
        return minotaurBulwark;
      case 'boss_monster':
        return bossMonster;
      default:
        return null;
    }
  }

  /// Get minions by archetype
  static List<MonsterDefinition> getByArchetype(MonsterArchetype archetype) {
    return allMinions.where((m) => m.archetype == archetype).toList();
  }

  /// Get minions by Monster Power range
  static List<MonsterDefinition> getByPowerRange(int minPower, int maxPower) {
    return allMinions
        .where((m) => m.monsterPower >= minPower && m.monsterPower <= maxPower)
        .toList();
  }
}

/// Spawn configuration for minion groups
class MinionSpawnConfig {
  final String definitionId;
  final int count;
  final double spreadRadius;  // How far apart to spawn

  const MinionSpawnConfig({
    required this.definitionId,
    required this.count,
    this.spreadRadius = 3.0,
  });
}

/// Default spawn configuration for the 4 minion types
/// Total: 8 + 4 + 2 + 1 = 15 minions
/// Total Monster Power: 8*4 + 4*5 + 2*6 + 1*7 = 32 + 20 + 12 + 7 = 71
class DefaultMinionSpawns {
  DefaultMinionSpawns._();

  static const List<MinionSpawnConfig> spawns = [
    // 8 Gnoll Marauders (DPS, Power 4) - Pack hunters spread wide
    MinionSpawnConfig(
      definitionId: 'gnoll_marauder',
      count: 8,
      spreadRadius: 5.0,
    ),
    // 4 Satyr Hexblades (Support, Power 5) - Stay together for coordination
    MinionSpawnConfig(
      definitionId: 'satyr_hexblade',
      count: 4,
      spreadRadius: 3.0,
    ),
    // 2 Dryad Lifebinders (Healer, Power 6) - Protected in back
    MinionSpawnConfig(
      definitionId: 'dryad_lifebinder',
      count: 2,
      spreadRadius: 2.0,
    ),
    // 1 Minotaur Bulwark (Tank, Power 7) - Front line
    MinionSpawnConfig(
      definitionId: 'minotaur_bulwark',
      count: 1,
      spreadRadius: 0.0,
    ),
  ];

  /// Calculate total Monster Power for all spawns
  static int get totalMonsterPower {
    int total = 0;
    for (final spawn in spawns) {
      final def = MinionDefinitions.getById(spawn.definitionId);
      if (def != null) {
        total += def.monsterPower * spawn.count;
      }
    }
    return total;
  }

  /// Get spawn summary string
  static String get summary {
    final buffer = StringBuffer('Minion Spawns (Ancient Wilds Faction):\n');
    for (final spawn in spawns) {
      final def = MinionDefinitions.getById(spawn.definitionId);
      if (def != null) {
        buffer.writeln('  ${spawn.count}x ${def.name} (${def.archetype.name.toUpperCase()}, MP ${def.monsterPower})');
      }
    }
    buffer.writeln('Total Monster Power: $totalMonsterPower');
    buffer.writeln('\nAbility Coverage:');
    buffer.writeln('  Melee: Gnoll (Rending Bite, Savage Leap), Minotaur (Gore Charge, Earthshaker)');
    buffer.writeln('  Range: Satyr (Cursed Blade)');
    buffer.writeln('  Magic: Satyr (Discordant Pipes), Dryad (all)');
    buffer.writeln('  Buffs: Gnoll (Pack Howl), Satyr (Wild Revelry), Minotaur (Labyrinthine Fortitude)');
    buffer.writeln('  Debuffs: Gnoll (Rending Bite bleed), Satyr (Discordant Pipes, Cursed Blade)');
    buffer.writeln('  Auras: Satyr (Discordant Pipes), Dryad (Rejuvenation Aura), Minotaur (Intimidating Presence)');
    buffer.writeln('  Specialized: Dryad (Entangling Roots CC, Bark Shield)');
    return buffer.toString();
  }
}
