import 'package:flutter/material.dart';
import 'config_editor_panel.dart';
import '../../state/game_config.dart';
import '../../state/mana_config.dart';
import '../../state/wind_config.dart';
import '../../state/building_config.dart';
import '../../state/minimap_config.dart';
import '../../state/macro_config.dart';
import '../../state/goals_config.dart';

/// Tuning tab within the Settings panel.
///
/// Displays a sub-navigation for each config system (Game, Mana, Wind, etc.)
/// and renders a [ConfigEditorPanel] for the selected config.
class TuningTab extends StatefulWidget {
  const TuningTab({Key? key}) : super(key: key);

  @override
  State<TuningTab> createState() => _TuningTabState();
}

class _TuningTabState extends State<TuningTab> {
  int _selectedConfig = 0;

  static const _configs = [
    _ConfigDef(id: 'game', label: 'Game', icon: Icons.sports_esports),
    _ConfigDef(id: 'mana', label: 'Mana', icon: Icons.water_drop),
    _ConfigDef(id: 'wind', label: 'Wind', icon: Icons.air),
    _ConfigDef(id: 'building', label: 'Buildings', icon: Icons.home_work),
    _ConfigDef(id: 'minimap', label: 'Minimap', icon: Icons.map),
    _ConfigDef(id: 'macro', label: 'Macros', icon: Icons.code),
    _ConfigDef(id: 'goals', label: 'Goals', icon: Icons.flag),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSubNav(),
        Expanded(child: _buildEditor()),
      ],
    );
  }

  Widget _buildSubNav() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          for (int i = 0; i < _configs.length; i++)
            _buildSubNavItem(i, _configs[i]),
        ],
      ),
    );
  }

  Widget _buildSubNavItem(int index, _ConfigDef config) {
    final isSelected = _selectedConfig == index;
    return InkWell(
      onTap: () => setState(() => _selectedConfig = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyan.withOpacity(0.12)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.cyan : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              config.icon,
              color: isSelected ? Colors.cyan : Colors.white38,
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                config.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final config = _configs[_selectedConfig];
    switch (config.id) {
      case 'game':
        return _buildGameEditor();
      case 'mana':
        return _buildManaEditor();
      case 'wind':
        return _buildWindEditor();
      case 'building':
        return _buildBuildingEditor();
      case 'minimap':
        return _buildMinimapEditor();
      case 'macro':
        return _buildMacroEditor();
      case 'goals':
        return _buildGoalsEditor();
      default:
        return const SizedBox();
    }
  }

  // ==================== GAME CONFIG ====================

  Widget _buildGameEditor() {
    final cfg = globalGameConfig;
    if (cfg == null) return _noConfig('Game');
    return ConfigEditorPanel(
      key: const ValueKey('game'),
      title: 'Game Configuration',
      callbacks: ConfigCallbacks(
        getValue: (key) => cfg.getDefault(key),
        getDefault: (key) => cfg.getDefault(key),
        setOverride: cfg.setOverride,
        clearAllOverrides: cfg.clearAllOverrides,
        hasAnyOverrides: () => cfg.overrides.isNotEmpty,
      ),
      sections: const [
        ConfigSectionDef(title: 'TERRAIN', color: Colors.brown, fields: [
          ConfigFieldDef(label: 'Grid Size', dotKey: 'terrain.gridSize', type: ConfigFieldType.int_, tooltip: 'Size of terrain grid (NxN tiles)'),
          ConfigFieldDef(label: 'Tile Size', dotKey: 'terrain.tileSize', type: ConfigFieldType.double_, tooltip: 'Size of each terrain tile in world units'),
          ConfigFieldDef(label: 'Max Height', dotKey: 'terrain.maxHeight', type: ConfigFieldType.double_, tooltip: 'Maximum terrain elevation'),
          ConfigFieldDef(label: 'Noise Scale', dotKey: 'terrain.noiseScale', type: ConfigFieldType.double_, tooltip: 'Terrain noise frequency (smaller = larger features)'),
          ConfigFieldDef(label: 'Noise Octaves', dotKey: 'terrain.noiseOctaves', type: ConfigFieldType.int_, tooltip: 'Number of noise detail layers'),
          ConfigFieldDef(label: 'Noise Persistence', dotKey: 'terrain.noisePersistence', type: ConfigFieldType.double_, tooltip: 'How much each octave contributes'),
        ]),
        ConfigSectionDef(title: 'PLAYER', color: Colors.lightBlue, fields: [
          ConfigFieldDef(label: 'Speed', dotKey: 'player.speed', type: ConfigFieldType.double_, tooltip: 'Movement speed (units/sec)'),
          ConfigFieldDef(label: 'Rotation Speed', dotKey: 'player.rotationSpeed', type: ConfigFieldType.double_, tooltip: 'Turn speed (degrees/sec)'),
          ConfigFieldDef(label: 'Size', dotKey: 'player.size', type: ConfigFieldType.double_, tooltip: 'Player mesh radius'),
          ConfigFieldDef(label: 'Start X', dotKey: 'player.startPositionX', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Start Y', dotKey: 'player.startPositionY', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Start Z', dotKey: 'player.startPositionZ', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Start Rotation', dotKey: 'player.startRotation', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'MONSTER', color: Colors.red, fields: [
          ConfigFieldDef(label: 'Max Health', dotKey: 'monster.maxHealth', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Size', dotKey: 'monster.size', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'AI Interval', dotKey: 'monster.aiInterval', type: ConfigFieldType.double_, tooltip: 'Seconds between AI decisions'),
          ConfigFieldDef(label: 'Move Thresh Min', dotKey: 'monster.moveThresholdMin', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Move Thresh Max', dotKey: 'monster.moveThresholdMax', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Heal Threshold', dotKey: 'monster.healThreshold', type: ConfigFieldType.double_, tooltip: 'HP % below which monster heals'),
        ]),
        ConfigSectionDef(title: 'MONSTER ABILITIES', color: Colors.deepPurple, fields: [
          ConfigFieldDef(label: 'Melee Cooldown', dotKey: 'monsterAbilities.ability1CooldownMax', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Melee Damage', dotKey: 'monsterAbilities.ability1Damage', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Melee Range', dotKey: 'monsterAbilities.ability1Range', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Ranged Cooldown', dotKey: 'monsterAbilities.ability2CooldownMax', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Ranged Damage', dotKey: 'monsterAbilities.ability2Damage', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Heal Cooldown', dotKey: 'monsterAbilities.ability3CooldownMax', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Heal Amount', dotKey: 'monsterAbilities.ability3HealAmount', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'ALLY', color: Colors.green, fields: [
          ConfigFieldDef(label: 'Max Health', dotKey: 'ally.maxHealth', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Size', dotKey: 'ally.size', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Ability Cooldown', dotKey: 'ally.abilityCooldownMax', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'AI Interval', dotKey: 'ally.aiInterval', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Move Threshold', dotKey: 'ally.moveThreshold', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Sword Damage', dotKey: 'ally.swordDamage', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Fireball Damage', dotKey: 'ally.fireballDamage', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Heal Amount', dotKey: 'ally.healAmount', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'PLAYER ABILITIES', color: Colors.amber, fields: [
          ConfigFieldDef(label: 'Sword Cooldown', dotKey: 'playerAbilities.ability1CooldownMax', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Sword Damage', dotKey: 'playerAbilities.ability1Damage', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Sword Range', dotKey: 'playerAbilities.ability1Range', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Fireball Cooldown', dotKey: 'playerAbilities.ability2CooldownMax', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Fireball Damage', dotKey: 'playerAbilities.ability2Damage', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Fireball Speed', dotKey: 'playerAbilities.ability2ProjectileSpeed', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Heal Cooldown', dotKey: 'playerAbilities.ability3CooldownMax', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Heal Amount', dotKey: 'playerAbilities.ability3HealAmount', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'PHYSICS', color: Colors.teal, fields: [
          ConfigFieldDef(label: 'Gravity', dotKey: 'physics.gravity', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Jump Velocity', dotKey: 'physics.jumpVelocity', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Ground Level', dotKey: 'physics.groundLevel', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'EFFECTS', color: Colors.orange, fields: [
          ConfigFieldDef(label: 'Impact Size', dotKey: 'effects.impactSize', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Impact Duration', dotKey: 'effects.impactDuration', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Impact Growth', dotKey: 'effects.impactGrowthScale', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'SELECTION', color: Colors.grey, fields: [
          ConfigFieldDef(label: 'Click Radius', dotKey: 'selection.clickSelectionRadius', type: ConfigFieldType.double_, tooltip: 'Max pixel distance for click selection'),
        ]),
      ],
    );
  }

  // ==================== MANA CONFIG ====================

  Widget _buildManaEditor() {
    final cfg = globalManaConfig;
    if (cfg == null) return _noConfig('Mana');
    return ConfigEditorPanel(
      key: const ValueKey('mana'),
      title: 'Mana Configuration',
      callbacks: ConfigCallbacks(
        getValue: (key) => cfg.getDefault(key),
        getDefault: (key) => cfg.getDefault(key),
        setOverride: cfg.setOverride,
        clearAllOverrides: cfg.clearAllOverrides,
        hasAnyOverrides: () => cfg.overrides.isNotEmpty,
      ),
      sections: const [
        ConfigSectionDef(title: 'BLUE MANA', color: Colors.blue, fields: [
          ConfigFieldDef(label: 'Max Blue Mana', dotKey: 'blue_mana.max', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Ley Line Max Dist', dotKey: 'blue_mana.ley_line_max_regen_distance', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Ley Line Optimal', dotKey: 'blue_mana.ley_line_optimal_distance', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Base Regen', dotKey: 'blue_mana.base_regen_rate', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Max Regen', dotKey: 'blue_mana.max_regen_rate', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Power Node Radius', dotKey: 'blue_mana.power_node_radius', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Power Node Frac', dotKey: 'blue_mana.power_node_fraction', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'RED MANA', color: Colors.red, fields: [
          ConfigFieldDef(label: 'Max Red Mana', dotKey: 'red_mana.max', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Mana per Damage', dotKey: 'red_mana.mana_per_damage', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Decay Rate', dotKey: 'red_mana.decay_rate', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Decay Delay', dotKey: 'red_mana.decay_delay', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'GREEN MANA', color: Colors.green, fields: [
          ConfigFieldDef(label: 'Max Green Mana', dotKey: 'green_mana.max', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Grass Base Regen', dotKey: 'green_mana.grass_base_regen', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Proximity Regen', dotKey: 'green_mana.proximity_regen_per_user', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Proximity Radius', dotKey: 'green_mana.proximity_radius', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Spirit Bonus', dotKey: 'green_mana.spirit_being_regen_bonus', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Spirit Radius', dotKey: 'green_mana.spirit_being_radius', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Decay Rate', dotKey: 'green_mana.decay_rate', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Decay Delay', dotKey: 'green_mana.decay_delay', type: ConfigFieldType.double_),
        ]),
      ],
    );
  }

  // ==================== WIND CONFIG ====================

  Widget _buildWindEditor() {
    final cfg = globalWindConfig;
    if (cfg == null) return _noConfig('Wind');
    return ConfigEditorPanel(
      key: const ValueKey('wind'),
      title: 'Wind Configuration',
      callbacks: ConfigCallbacks(
        getValue: (key) => cfg.getDefault(key),
        getDefault: (key) => cfg.getDefault(key),
        setOverride: cfg.setOverride,
        clearAllOverrides: cfg.clearAllOverrides,
        hasAnyOverrides: () => cfg.overrides.isNotEmpty,
      ),
      sections: const [
        ConfigSectionDef(title: 'WIND', color: Colors.lightBlue, fields: [
          ConfigFieldDef(label: 'Base Strength', dotKey: 'wind.baseStrength', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Max Strength', dotKey: 'wind.maxStrength', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Drift Speed', dotKey: 'wind.driftSpeed', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Gust Frequency', dotKey: 'wind.gustFrequency', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Gust Amplitude', dotKey: 'wind.gustAmplitude', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Dir Drift Speed', dotKey: 'wind.directionDriftSpeed', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'WHITE MANA', color: Colors.white70, fields: [
          ConfigFieldDef(label: 'Max White Mana', dotKey: 'whiteMana.maxMana', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Base Regen', dotKey: 'whiteMana.baseRegen', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Wind Exposure Regen', dotKey: 'whiteMana.windExposureRegen', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Strength Mult', dotKey: 'whiteMana.windStrengthMultiplier', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Decay Rate', dotKey: 'whiteMana.decayRate', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Shelter Threshold', dotKey: 'whiteMana.shelterThreshold', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'MOVEMENT', color: Colors.teal, fields: [
          ConfigFieldDef(label: 'Headwind Factor', dotKey: 'movement.headwindFactor', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Tailwind Factor', dotKey: 'movement.tailwindFactor', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Crosswind Factor', dotKey: 'movement.crosswindFactor', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'FLIGHT', color: Colors.cyan, fields: [
          ConfigFieldDef(label: 'Flight Speed', dotKey: 'flight.flightSpeed', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Pitch Rate', dotKey: 'flight.pitchRate', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Max Pitch', dotKey: 'flight.maxPitchAngle', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Boost Mult', dotKey: 'flight.boostMultiplier', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Brake Mult', dotKey: 'flight.brakeMultiplier', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Mana Drain Rate', dotKey: 'flight.manaDrainRate', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Initial Mana Cost', dotKey: 'flight.initialManaCost', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Bank Rate', dotKey: 'flight.bankRate', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Max Bank Angle', dotKey: 'flight.maxBankAngle', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Barrel Roll Rate', dotKey: 'flight.barrelRollRate', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Dbl-Tap Window', dotKey: 'flight.doubleTapWindow', type: ConfigFieldType.double_, tooltip: 'Seconds between taps for hard bank'),
          ConfigFieldDef(label: 'Hard Bank Rate', dotKey: 'flight.hardBankRateMultiplier', type: ConfigFieldType.double_, tooltip: 'Bank rate multiplier on double-tap'),
          ConfigFieldDef(label: 'Hard Bank Max', dotKey: 'flight.hardBankMaxAngle', type: ConfigFieldType.double_, tooltip: 'Max bank angle on double-tap'),
          ConfigFieldDef(label: 'Space Boost', dotKey: 'flight.spaceBoostMultiplier', type: ConfigFieldType.double_, tooltip: 'Speed multiplier from spacebar'),
          ConfigFieldDef(label: 'Space Mana/s', dotKey: 'flight.spaceBoostManaCostPerSecond', type: ConfigFieldType.double_, tooltip: 'White mana cost per second for space boost'),
          ConfigFieldDef(label: 'Turn Spd Loss', dotKey: 'flight.turnSpeedReductionFactor', type: ConfigFieldType.double_, tooltip: 'Max speed reduction fraction when turning'),
        ]),
        ConfigSectionDef(title: 'DERECHO', color: Colors.indigo, fields: [
          ConfigFieldDef(label: 'Avg Interval', dotKey: 'derecho.averageInterval', type: ConfigFieldType.double_, tooltip: 'Average seconds between derecho events'),
          ConfigFieldDef(label: 'Duration Min', dotKey: 'derecho.durationMin', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Duration Max', dotKey: 'derecho.durationMax', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Strength Mult', dotKey: 'derecho.strengthMultiplier', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Mana Regen Mult', dotKey: 'derecho.manaRegenMultiplier', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Ramp Up Time', dotKey: 'derecho.rampUpTime', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Ramp Down Time', dotKey: 'derecho.rampDownTime', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'PARTICLES', color: Colors.grey, fields: [
          ConfigFieldDef(label: 'Count', dotKey: 'particles.count', type: ConfigFieldType.int_),
          ConfigFieldDef(label: 'Speed', dotKey: 'particles.speed', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Lifetime', dotKey: 'particles.lifetime', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Fade Distance', dotKey: 'particles.fadeDistance', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Size', dotKey: 'particles.size', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'TRAILS', color: Colors.purple, fields: [
          ConfigFieldDef(label: 'Enabled', dotKey: 'trails.enabled', type: ConfigFieldType.bool_),
          ConfigFieldDef(label: 'Length', dotKey: 'trails.length', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Width', dotKey: 'trails.width', type: ConfigFieldType.double_),
        ]),
      ],
    );
  }

  // ==================== BUILDING CONFIG ====================

  Widget _buildBuildingEditor() {
    final cfg = globalBuildingConfig;
    if (cfg == null) return _noConfig('Building');
    return ConfigEditorPanel(
      key: const ValueKey('building'),
      title: 'Building Configuration',
      callbacks: ConfigCallbacks(
        getValue: (key) => cfg.getDefault(key),
        getDefault: (key) => cfg.getDefault(key),
        setOverride: cfg.setOverride,
        clearAllOverrides: cfg.clearAllOverrides,
        hasAnyOverrides: () => cfg.overrides.isNotEmpty,
      ),
      sections: const [
        ConfigSectionDef(title: 'BUILDINGS', color: Colors.brown, fields: [
          ConfigFieldDef(label: 'Interact Range', dotKey: 'interaction_range', type: ConfigFieldType.double_, tooltip: 'Range for player-building interaction'),
          ConfigFieldDef(label: 'Grid Size', dotKey: 'placement_grid_size', type: ConfigFieldType.double_, tooltip: 'Snap grid for building placement'),
          ConfigFieldDef(label: 'Ley Bonus Radius', dotKey: 'ley_line_bonus_radius', type: ConfigFieldType.double_, tooltip: 'Proximity radius for ley line bonus'),
          ConfigFieldDef(label: 'Ley Bonus Mult', dotKey: 'ley_line_bonus_multiplier', type: ConfigFieldType.double_, tooltip: 'Multiplier when near ley line'),
        ]),
      ],
    );
  }

  // ==================== MINIMAP CONFIG ====================

  Widget _buildMinimapEditor() {
    final cfg = globalMinimapConfig;
    if (cfg == null) return _noConfig('Minimap');
    return ConfigEditorPanel(
      key: const ValueKey('minimap'),
      title: 'Minimap Configuration',
      callbacks: ConfigCallbacks(
        getValue: (key) => cfg.getDefault(key),
        getDefault: (key) => cfg.getDefault(key),
        setOverride: cfg.setOverride,
        clearAllOverrides: cfg.clearAllOverrides,
        hasAnyOverrides: () => cfg.overrides.isNotEmpty,
      ),
      sections: const [
        ConfigSectionDef(title: 'DISPLAY', color: Colors.blue, fields: [
          ConfigFieldDef(label: 'Size', dotKey: 'minimap.size', type: ConfigFieldType.int_),
          ConfigFieldDef(label: 'Border Width', dotKey: 'minimap.borderWidth', type: ConfigFieldType.int_),
        ]),
        ConfigSectionDef(title: 'TERRAIN', color: Colors.brown, fields: [
          ConfigFieldDef(label: 'Cache Resolution', dotKey: 'terrain.cacheResolution', type: ConfigFieldType.int_),
          ConfigFieldDef(label: 'Refresh Threshold', dotKey: 'terrain.refreshThresholdFraction', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Sand Threshold', dotKey: 'terrain.sandThreshold', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Rock Threshold', dotKey: 'terrain.rockThreshold', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'LEY LINES', color: Colors.purple, fields: [
          ConfigFieldDef(label: 'Show Ley Lines', dotKey: 'leyLines.show', type: ConfigFieldType.bool_),
          ConfigFieldDef(label: 'Line Width', dotKey: 'leyLines.lineWidth', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Node Radius', dotKey: 'leyLines.nodeRadius', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'ENTITIES', color: Colors.green, fields: [
          ConfigFieldDef(label: 'Player Size', dotKey: 'entities.playerSize', type: ConfigFieldType.int_),
          ConfigFieldDef(label: 'Ally Size', dotKey: 'entities.allySize', type: ConfigFieldType.int_),
          ConfigFieldDef(label: 'Enemy Size', dotKey: 'entities.enemySize', type: ConfigFieldType.int_),
          ConfigFieldDef(label: 'Boss Size', dotKey: 'entities.bossSize', type: ConfigFieldType.int_),
        ]),
        ConfigSectionDef(title: 'ZOOM', color: Colors.teal, fields: [
          ConfigFieldDef(label: 'Default Level', dotKey: 'zoom.defaultLevel', type: ConfigFieldType.int_),
        ]),
        ConfigSectionDef(title: 'PING', color: Colors.yellow, fields: [
          ConfigFieldDef(label: 'Decay Duration', dotKey: 'ping.decayDuration', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Ring Count', dotKey: 'ping.ringCount', type: ConfigFieldType.int_),
          ConfigFieldDef(label: 'Max Ring Radius', dotKey: 'ping.maxRingRadius', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Max Active Pings', dotKey: 'ping.maxActivePings', type: ConfigFieldType.int_),
        ]),
        ConfigSectionDef(title: 'CLOCK', color: Colors.orange, fields: [
          ConfigFieldDef(label: 'Show by Default', dotKey: 'clock.showByDefault', type: ConfigFieldType.bool_),
          ConfigFieldDef(label: 'Font Size', dotKey: 'clock.fontSize', type: ConfigFieldType.int_),
          ConfigFieldDef(label: 'Warchief Time', dotKey: 'clock.warchiefTimeEnabled', type: ConfigFieldType.bool_),
        ]),
        ConfigSectionDef(title: 'WIND DISPLAY', color: Colors.lightBlue, fields: [
          ConfigFieldDef(label: 'Show on Border', dotKey: 'wind.showOnBorder', type: ConfigFieldType.bool_),
          ConfigFieldDef(label: 'Arrow Size', dotKey: 'wind.arrowSize', type: ConfigFieldType.int_),
        ]),
      ],
    );
  }

  // ==================== MACRO CONFIG ====================

  Widget _buildMacroEditor() {
    final cfg = globalMacroConfig;
    if (cfg == null) return _noConfig('Macro');
    return ConfigEditorPanel(
      key: const ValueKey('macro'),
      title: 'Macro Configuration',
      callbacks: ConfigCallbacks(
        getValue: (key) => cfg.getDefault(key),
        getDefault: (key) => cfg.getDefault(key),
        setOverride: cfg.setOverride,
        clearAllOverrides: cfg.clearAllOverrides,
        hasAnyOverrides: () => cfg.overrides.isNotEmpty,
      ),
      sections: const [
        ConfigSectionDef(title: 'GCD', color: Colors.cyan, fields: [
          ConfigFieldDef(label: 'Base GCD', dotKey: 'gcd.base', type: ConfigFieldType.double_, tooltip: 'Global cooldown base (seconds)'),
          ConfigFieldDef(label: 'Minimum GCD', dotKey: 'gcd.minimum', type: ConfigFieldType.double_, tooltip: 'Minimum global cooldown (seconds)'),
        ]),
        ConfigSectionDef(title: 'ALERTS', color: Colors.orange, fields: [
          ConfigFieldDef(label: 'Low Mana Thresh', dotKey: 'alerts.lowManaThreshold', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Low Health Thresh', dotKey: 'alerts.lowHealthThreshold', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Alert Cooldown', dotKey: 'alerts.alertCooldownSeconds', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Damage Window', dotKey: 'alerts.underAttackDamageWindow', type: ConfigFieldType.double_),
        ]),
        ConfigSectionDef(title: 'EXECUTION', color: Colors.green, fields: [
          ConfigFieldDef(label: 'Max Active', dotKey: 'execution.maxActiveMacros', type: ConfigFieldType.int_),
          ConfigFieldDef(label: 'Retry on CD', dotKey: 'execution.retryOnCooldown', type: ConfigFieldType.bool_),
          ConfigFieldDef(label: 'Retry Interval', dotKey: 'execution.retryIntervalSeconds', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Skip on Fail', dotKey: 'execution.skipOnConditionFail', type: ConfigFieldType.bool_),
        ]),
      ],
    );
  }

  // ==================== GOALS CONFIG ====================

  Widget _buildGoalsEditor() {
    final cfg = globalGoalsConfig;
    if (cfg == null) return _noConfig('Goals');
    return ConfigEditorPanel(
      key: const ValueKey('goals'),
      title: 'Goals / Warrior Spirit',
      callbacks: ConfigCallbacks(
        getValue: (key) => cfg.getDefault(key),
        getDefault: (key) => cfg.getDefault(key),
        setOverride: cfg.setOverride,
        clearAllOverrides: cfg.clearAllOverrides,
        hasAnyOverrides: () => cfg.overrides.isNotEmpty,
      ),
      sections: const [
        ConfigSectionDef(title: 'WARRIOR SPIRIT', color: Colors.amber, fields: [
          ConfigFieldDef(label: 'Model', dotKey: 'warrior_spirit.model', type: ConfigFieldType.string_, tooltip: 'Ollama model name'),
          ConfigFieldDef(label: 'Temperature', dotKey: 'warrior_spirit.temperature', type: ConfigFieldType.double_, tooltip: 'LLM creativity (0.0-2.0)'),
          ConfigFieldDef(label: 'Check Interval', dotKey: 'warrior_spirit.goal_check_interval_seconds', type: ConfigFieldType.double_),
          ConfigFieldDef(label: 'Max Active Goals', dotKey: 'warrior_spirit.max_active_goals', type: ConfigFieldType.int_),
        ]),
      ],
    );
  }

  Widget _noConfig(String name) {
    return Center(
      child: Text(
        '$name config not initialized',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }
}

class _ConfigDef {
  final String id;
  final String label;
  final IconData icon;

  const _ConfigDef({
    required this.id,
    required this.label,
    required this.icon,
  });
}
