import 'package:vector_math/vector_math.dart';
import 'ability_types.dart';

/// Starbreaker abilities — 3 melee + 10 black mana abilities.
///
/// Design theme: **Escalating entropy** — a warrior who tears power from
/// collapsing stars. Health slowly drains while the stance is active, but each
/// ability draws from the comet's dark energy to devastate enemies. The class
/// rewards aggressive, high-risk play near comet events and meteor craters.
///
/// Melee abilities build shadow vulnerability stacks on the target. Black mana
/// abilities exploit those vulnerabilities with wide-area and channeled effects.
class StarbreakerAbilities {
  StarbreakerAbilities._();

  // ── Colour palette ─────────────────────────────────────────────────────────
  static final _col = Vector3(0.55, 0.05, 0.80); // deep void-violet
  static final _mel = Vector3(0.45, 0.00, 0.58); // dark shadow-purple (melee)
  static final _imp = Vector3(0.78, 0.15, 1.00); // bright violet flash (impact)
  static final _cor = Vector3(0.18, 0.00, 0.38); // near-black void (void bolt)

  // ==================== MELEE ABILITIES (3) ====================

  /// Void Strike — heavy shadow melee that permanently strips shadow resistance.
  static final voidStrike = AbilityData(
    name: 'Void Strike',
    description:
        'Crushes the target with void-infused force, permanently searing '
        'their resistance to shadow damage. Build this stacks before unleashing black mana abilities.',
    type: AbilityType.melee,
    damage: 50.0,
    cooldown: 3.5,
    range: 2.5,
    color: _mel,
    impactColor: _imp,
    impactSize: 0.75,
    windupTime: 0.40,
    windupMovementSpeed: 0.5,
    damageSchool: DamageSchool.shadow,
    appliesPermanentVulnerability: true,
    category: 'starbreaker',
  );

  /// Soul Rend — rapid raking strikes that shred the target's damage output.
  static final soulRend = AbilityData(
    name: 'Soul Rend',
    description:
        'Rakes the target\'s soul with void claws, inflicting Weakness and '
        'reducing their damage output for 6 seconds.',
    type: AbilityType.melee,
    damage: 28.0,
    cooldown: 5.0,
    range: 2.2,
    color: _mel,
    impactColor: _imp,
    impactSize: 0.55,
    statusEffect: StatusEffect.weakness,
    statusDuration: 6.0,
    statusStrength: 0.35,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  /// Entropy Smash — downward void slam, AoE stun on impact.
  static final entropySmash = AbilityData(
    name: 'Entropy Smash',
    description:
        'Slams the ground with condensed void energy, stunning all nearby '
        'enemies on impact. Long windup — use after a Singularity pull.',
    type: AbilityType.melee,
    damage: 40.0,
    cooldown: 9.0,
    range: 2.0,
    color: _mel,
    impactColor: _imp,
    impactSize: 1.0,
    windupTime: 0.70,
    windupMovementSpeed: 0.2,
    aoeRadius: 3.5,
    statusEffect: StatusEffect.stun,
    statusDuration: 1.8,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  // ==================== BLACK MANA ABILITIES (10) ====================

  /// Singularity — collapses gravity at target point, pulling all enemies in.
  static final singularity = AbilityData(
    name: 'Singularity',
    description:
        'Collapses gravity at target location, pulling all enemies inward '
        'and crushing them with shadow damage. Pairs with Entropy Smash.',
    type: AbilityType.aoe,
    damage: 68.0,
    cooldown: 14.0,
    range: 16.0,
    color: _col,
    impactColor: _imp,
    impactSize: 1.25,
    aoeRadius: 5.0,
    knockbackForce: -7.0, // negative = pull toward centre
    castTime: 0.5,
    manaColor: ManaColor.black,
    manaCost: 30.0,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  /// Void Bolt — piercing projectile that heals caster for each enemy struck.
  static final voidBolt = AbilityData(
    name: 'Void Bolt',
    description:
        'Launches a piercing bolt of void energy through all enemies in a '
        'line, drawing life from each one struck.',
    type: AbilityType.ranged,
    damage: 58.0,
    cooldown: 5.5,
    range: 22.0,
    color: _col,
    impactColor: _cor,
    impactSize: 0.60,
    projectileSpeed: 28.0,
    projectileSize: 0.35,
    piercing: true,
    healAmount: 18.0,
    manaColor: ManaColor.black,
    manaCost: 20.0,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  /// Death Mark — brands target; consumes them with a burning void DoT.
  static final deathMark = AbilityData(
    name: 'Death Mark',
    description:
        'Brands the target with a void sigil that burns their life force '
        'over 6 seconds. Shadow-vulnerable targets take greatly amplified damage.',
    type: AbilityType.dot,
    damage: 20.0,
    cooldown: 16.0,
    range: 18.0,
    duration: 6.0,
    color: _col,
    impactColor: _imp,
    impactSize: 0.55,
    statusEffect: StatusEffect.burn,
    statusDuration: 6.0,
    statusStrength: 20.0,
    dotTicks: 6,
    castTime: 0.4,
    manaColor: ManaColor.black,
    manaCost: 25.0,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  /// Entropic Field — channeled zone of collapse dealing continuous shadow damage.
  static final entropicField = AbilityData(
    name: 'Entropic Field',
    description:
        'Channels a zone of dimensional collapse around the caster, '
        'continuously tearing at all enemies within. Requires standing still.',
    type: AbilityType.channeled,
    damage: 24.0,
    cooldown: 20.0,
    range: 0.0, // self-centred AoE
    color: _col,
    impactColor: _cor,
    impactSize: 1.6,
    aoeRadius: 5.5,
    castTime: 3.5,
    channelEffect: ChannelEffect.earthquake,
    manaColor: ManaColor.black,
    manaCost: 45.0,
    damageSchool: DamageSchool.shadow,
    requiresStationary: true,
    category: 'starbreaker',
  );

  /// Soul Drain — channeled lifesteal beam that heals caster while dealing damage.
  static final soulDrain = AbilityData(
    name: 'Soul Drain',
    description:
        'Channels a beam of life-force extraction at the target, healing '
        'the caster for a portion of shadow damage dealt each tick.',
    type: AbilityType.channeled,
    damage: 32.0,
    cooldown: 13.0,
    range: 9.0,
    color: _col,
    impactColor: _imp,
    impactSize: 0.70,
    castTime: 2.5,
    channelEffect: ChannelEffect.lifeDrain,
    healAmount: 22.0,
    manaColor: ManaColor.black,
    manaCost: 28.0,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  /// Comet Shard — calls down a void comet fragment for massive impact damage.
  static final cometShard = AbilityData(
    name: 'Comet Shard',
    description:
        'Calls down a fragment of the void comet after a long windup, '
        'devastating a target area with catastrophic impact damage.',
    type: AbilityType.aoe,
    damage: 135.0,
    cooldown: 22.0,
    range: 22.0,
    color: _col,
    impactColor: _imp,
    impactSize: 2.2,
    aoeRadius: 3.5,
    windupTime: 1.8,
    windupMovementSpeed: 0.0,
    manaColor: ManaColor.black,
    manaCost: 55.0,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  /// Void Rift — tears open a dimensional rift, rooting enemies in a damage zone.
  static final voidRift = AbilityData(
    name: 'Void Rift',
    description:
        'Tears reality open at target location, rooting all enemies within '
        'and burning them with void energy for the duration.',
    type: AbilityType.aoe,
    damage: 46.0,
    cooldown: 17.0,
    range: 15.0,
    duration: 3.0,
    color: _col,
    impactColor: _imp,
    impactSize: 1.05,
    aoeRadius: 3.5,
    statusEffect: StatusEffect.root,
    statusDuration: 2.8,
    castTime: 0.8,
    manaColor: ManaColor.black,
    manaCost: 38.0,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  /// Entropy Cascade — shadow chain damage between clustered enemies.
  static final entropyCascade = AbilityData(
    name: 'Entropy Cascade',
    description:
        'Unleashes cascading void arcs that chain between up to 5 nearby '
        'enemies. Each jump is amplified by existing shadow vulnerability stacks.',
    type: AbilityType.aoe,
    damage: 55.0,
    cooldown: 11.0,
    range: 14.0,
    color: _col,
    impactColor: _imp,
    impactSize: 0.85,
    aoeRadius: 7.0,
    maxTargets: 5,
    manaColor: ManaColor.black,
    manaCost: 32.0,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  /// Oblivion — channeled void beam that strips all damage resistances.
  static final oblivion = AbilityData(
    name: 'Oblivion',
    description:
        'Channels pure void energy as a sustained beam, permanently stripping '
        'all damage resistances while dealing continuous shadow damage.',
    type: AbilityType.channeled,
    damage: 30.0,
    cooldown: 28.0,
    range: 13.0,
    color: _col,
    impactColor: _imp,
    impactSize: 1.05,
    castTime: 3.5,
    channelEffect: ChannelEffect.conduit,
    appliesPermanentVulnerability: true,
    manaColor: ManaColor.black,
    manaCost: 60.0,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
  );

  /// Stellar Collapse — ultimate: spend all remaining black mana for a cataclysm.
  static final stellarCollapse = AbilityData(
    name: 'Stellar Collapse',
    description:
        'Ultimate — drains all remaining black mana to trigger a catastrophic '
        'void implosion centred on the caster, devastating everything nearby '
        'and applying all damage vulnerabilities permanently.',
    type: AbilityType.aoe,
    damage: 225.0,
    cooldown: 65.0,
    range: 0.0, // self-centred
    color: _col,
    impactColor: Vector3(1.0, 0.72, 1.0),
    impactSize: 3.2,
    aoeRadius: 11.0,
    castTime: 2.5,
    knockbackForce: 9.0,
    requiresStationary: true,
    manaColor: ManaColor.black,
    manaCost: 85.0,
    damageSchool: DamageSchool.shadow,
    appliesPermanentVulnerability: true,
    category: 'starbreaker',
  );

  // ==================== CHAIN COMBO PRIMER ====================

  /// Void Cascade — Activates chain-combo mode for starbreakerss.
  /// Land 7 consecutive starbreaker strikes within 7 seconds to fire the chain combo.
  static final voidCascade = AbilityData(
    name: 'Void Cascade',
    description: 'Cascade void energy through your strikes — activate chain-combo mode. '
        'Land 7 starbreaker hits within 7 seconds to trigger a massive red and black mana surge.',
    type: AbilityType.melee,
    damage: 20.0,
    cooldown: 10.0,
    range: 2.0,
    color: _mel,
    impactColor: _imp,
    impactSize: 0.6,
    manaColor: ManaColor.black,
    manaCost: 20.0,
    damageSchool: DamageSchool.shadow,
    category: 'starbreaker',
    enablesComboChain: true,
  );

  // ==================== REGISTRY ====================

  static List<AbilityData> get all => [
        voidStrike,
        soulRend,
        entropySmash,
        singularity,
        voidBolt,
        deathMark,
        entropicField,
        soulDrain,
        cometShard,
        voidRift,
        entropyCascade,
        oblivion,
        stellarCollapse,
        voidCascade,
      ];
}
