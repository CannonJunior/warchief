/// Advanced stance mechanics for the 7 playstyle-altering stances.
///
/// Referenced by [StanceData.mechanics]. Legacy stat-multiplier stances
/// have `mechanics: null`. See `STANCE_REVAMP.md` for full design docs.
class StanceMechanics {
  // ==================== CADENCE (Rhythm Pulse) ====================
  final double rhythmPulseInterval;
  final double rhythmBeatWindow;
  final double rhythmDamageBonus;
  final double rhythmCooldownRefund;
  final double rhythmManaRefund;
  final int grooveMaxStacks;
  final double grooveHastePerStack;

  // ==================== TEMPEST (Animation Acceleration) ====================
  final double windupReduction;
  final double castTimeReduction;
  final double cancelWindowDuration;
  final int cancelMaxChain;
  final List<double> cancelChainDamageScale;
  final double channelTickSpeedBonus;

  // ==================== WARDEN (Tactical Movement) ====================
  final double movementForwardRangeBonus;
  final double movementForwardDamageBonus;
  final double movementBackwardDamageReduction;
  final double movementBackwardKnockbackBonus;
  final double movementStrafeDodgeBonus;
  final bool movementStrafePiercing;
  final double movementStationaryDamageBonus;
  final double movementStationaryAoeBonus;
  final double movementInputWindow;
  final double predatorActivationTime;
  final double predatorExposedDuration;
  final double predatorExposedDamageBonus;

  // ==================== CRUCIBLE (Burst Overload) ====================
  final int heatPerCast;
  final int heatMaxStacks;
  final double heatDecayRate;
  final double heatManaCostPerStack;
  final double heatDamageTakenPerStack;
  final double overheatSilenceDuration;
  final double overheatCooldownPenalty;
  final double coolDownPayoffDamageBonus;

  // ==================== MOMENTUM (Combo Escalation) ====================
  final int momentumMaxStacks;
  final double momentumDecayInterval;
  final double momentumCooldownPerStack;
  final double momentumAoePerStack;
  final double momentumCastPerStack;
  final double momentumDamagePerStack;
  final bool momentumSplashAtMax;
  final double momentumSplashRatio;
  final double momentumSplashRadius;
  final double kineticOverflowBonus;

  // ==================== PRESSURE (Aggression Gauge) ====================
  final double pressurePerMelee;
  final double pressurePerRanged;
  final double pressurePerDot;
  final double pressureDecayPerSecond;
  final double pressureComboBonus;
  final double pressureWindupBonus;
  final double pressureBreakStunDuration;
  final double pressureBreakDamageBonus;
  final bool pressureBreakResetsAllCooldowns;

  // ==================== FLUX (Stance-Dance Synergy) ====================
  final double transitionBonusDamage;
  final double transitionBonusWindow;
  final bool transitionInstantCast;
  final bool transitionNoManaCost;
  final double fluxMemoryDuration;
  final int weaveThreshold;
  final double weaveWindow;
  final double weaveBonusDuration;
  final double weaveBonusMultiplier;
  final double weaveHealPerSwitch;
  final double fluxSwitchCooldown;
  final double stagnationPenaltyTime;
  final double stagnationDamageReduction;

  const StanceMechanics({
    // Cadence
    this.rhythmPulseInterval = 0.0,
    this.rhythmBeatWindow = 0.0,
    this.rhythmDamageBonus = 0.0,
    this.rhythmCooldownRefund = 0.0,
    this.rhythmManaRefund = 0.0,
    this.grooveMaxStacks = 0,
    this.grooveHastePerStack = 0.0,
    // Tempest
    this.windupReduction = 0.0,
    this.castTimeReduction = 0.0,
    this.cancelWindowDuration = 0.0,
    this.cancelMaxChain = 0,
    this.cancelChainDamageScale = const [],
    this.channelTickSpeedBonus = 0.0,
    // Warden
    this.movementForwardRangeBonus = 0.0,
    this.movementForwardDamageBonus = 0.0,
    this.movementBackwardDamageReduction = 0.0,
    this.movementBackwardKnockbackBonus = 0.0,
    this.movementStrafeDodgeBonus = 0.0,
    this.movementStrafePiercing = false,
    this.movementStationaryDamageBonus = 0.0,
    this.movementStationaryAoeBonus = 0.0,
    this.movementInputWindow = 0.0,
    this.predatorActivationTime = 0.0,
    this.predatorExposedDuration = 0.0,
    this.predatorExposedDamageBonus = 0.0,
    // Crucible
    this.heatPerCast = 0,
    this.heatMaxStacks = 0,
    this.heatDecayRate = 0.0,
    this.heatManaCostPerStack = 0.0,
    this.heatDamageTakenPerStack = 0.0,
    this.overheatSilenceDuration = 0.0,
    this.overheatCooldownPenalty = 0.0,
    this.coolDownPayoffDamageBonus = 0.0,
    // Momentum
    this.momentumMaxStacks = 0,
    this.momentumDecayInterval = 0.0,
    this.momentumCooldownPerStack = 0.0,
    this.momentumAoePerStack = 0.0,
    this.momentumCastPerStack = 0.0,
    this.momentumDamagePerStack = 0.0,
    this.momentumSplashAtMax = false,
    this.momentumSplashRatio = 0.0,
    this.momentumSplashRadius = 0.0,
    this.kineticOverflowBonus = 0.0,
    // Pressure
    this.pressurePerMelee = 0.0,
    this.pressurePerRanged = 0.0,
    this.pressurePerDot = 0.0,
    this.pressureDecayPerSecond = 0.0,
    this.pressureComboBonus = 0.0,
    this.pressureWindupBonus = 0.0,
    this.pressureBreakStunDuration = 0.0,
    this.pressureBreakDamageBonus = 0.0,
    this.pressureBreakResetsAllCooldowns = false,
    // Flux
    this.transitionBonusDamage = 0.0,
    this.transitionBonusWindow = 0.0,
    this.transitionInstantCast = false,
    this.transitionNoManaCost = false,
    this.fluxMemoryDuration = 0.0,
    this.weaveThreshold = 0,
    this.weaveWindow = 0.0,
    this.weaveBonusDuration = 0.0,
    this.weaveBonusMultiplier = 0.0,
    this.weaveHealPerSwitch = 0.0,
    this.fluxSwitchCooldown = 0.0,
    this.stagnationPenaltyTime = 0.0,
    this.stagnationDamageReduction = 0.0,
  });

  /// Parse from JSON map. Only fields present in the map are set;
  /// absent fields keep their defaults.
  factory StanceMechanics.fromJson(Map<String, dynamic> j) {
    return StanceMechanics(
      // Cadence
      rhythmPulseInterval: _d(j, 'rhythmPulseInterval'),
      rhythmBeatWindow: _d(j, 'rhythmBeatWindow'),
      rhythmDamageBonus: _d(j, 'rhythmDamageBonus'),
      rhythmCooldownRefund: _d(j, 'rhythmCooldownRefund'),
      rhythmManaRefund: _d(j, 'rhythmManaRefund'),
      grooveMaxStacks: _i(j, 'grooveMaxStacks'),
      grooveHastePerStack: _d(j, 'grooveHastePerStack'),
      // Tempest
      windupReduction: _d(j, 'windupReduction'),
      castTimeReduction: _d(j, 'castTimeReduction'),
      cancelWindowDuration: _d(j, 'cancelWindowDuration'),
      cancelMaxChain: _i(j, 'cancelMaxChain'),
      cancelChainDamageScale: _dl(j, 'cancelChainDamageScale'),
      channelTickSpeedBonus: _d(j, 'channelTickSpeedBonus'),
      // Warden
      movementForwardRangeBonus: _d(j, 'movementForwardRangeBonus'),
      movementForwardDamageBonus: _d(j, 'movementForwardDamageBonus'),
      movementBackwardDamageReduction: _d(j, 'movementBackwardDamageReduction'),
      movementBackwardKnockbackBonus: _d(j, 'movementBackwardKnockbackBonus'),
      movementStrafeDodgeBonus: _d(j, 'movementStrafeDodgeBonus'),
      movementStrafePiercing: _b(j, 'movementStrafePiercing'),
      movementStationaryDamageBonus: _d(j, 'movementStationaryDamageBonus'),
      movementStationaryAoeBonus: _d(j, 'movementStationaryAoeBonus'),
      movementInputWindow: _d(j, 'movementInputWindow'),
      predatorActivationTime: _d(j, 'predatorActivationTime'),
      predatorExposedDuration: _d(j, 'predatorExposedDuration'),
      predatorExposedDamageBonus: _d(j, 'predatorExposedDamageBonus'),
      // Crucible
      heatPerCast: _i(j, 'heatPerCast'),
      heatMaxStacks: _i(j, 'heatMaxStacks'),
      heatDecayRate: _d(j, 'heatDecayRate'),
      heatManaCostPerStack: _d(j, 'heatManaCostPerStack'),
      heatDamageTakenPerStack: _d(j, 'heatDamageTakenPerStack'),
      overheatSilenceDuration: _d(j, 'overheatSilenceDuration'),
      overheatCooldownPenalty: _d(j, 'overheatCooldownPenalty'),
      coolDownPayoffDamageBonus: _d(j, 'coolDownPayoffDamageBonus'),
      // Momentum
      momentumMaxStacks: _i(j, 'momentumMaxStacks'),
      momentumDecayInterval: _d(j, 'momentumDecayInterval'),
      momentumCooldownPerStack: _d(j, 'momentumCooldownPerStack'),
      momentumAoePerStack: _d(j, 'momentumAoePerStack'),
      momentumCastPerStack: _d(j, 'momentumCastPerStack'),
      momentumDamagePerStack: _d(j, 'momentumDamagePerStack'),
      momentumSplashAtMax: _b(j, 'momentumSplashAtMax'),
      momentumSplashRatio: _d(j, 'momentumSplashRatio'),
      momentumSplashRadius: _d(j, 'momentumSplashRadius'),
      kineticOverflowBonus: _d(j, 'kineticOverflowBonus'),
      // Pressure
      pressurePerMelee: _d(j, 'pressurePerMelee'),
      pressurePerRanged: _d(j, 'pressurePerRanged'),
      pressurePerDot: _d(j, 'pressurePerDot'),
      pressureDecayPerSecond: _d(j, 'pressureDecayPerSecond'),
      pressureComboBonus: _d(j, 'pressureComboBonus'),
      pressureWindupBonus: _d(j, 'pressureWindupBonus'),
      pressureBreakStunDuration: _d(j, 'pressureBreakStunDuration'),
      pressureBreakDamageBonus: _d(j, 'pressureBreakDamageBonus'),
      pressureBreakResetsAllCooldowns: _b(j, 'pressureBreakResetsAllCooldowns'),
      // Flux
      transitionBonusDamage: _d(j, 'transitionBonusDamage'),
      transitionBonusWindow: _d(j, 'transitionBonusWindow'),
      transitionInstantCast: _b(j, 'transitionInstantCast'),
      transitionNoManaCost: _b(j, 'transitionNoManaCost'),
      fluxMemoryDuration: _d(j, 'fluxMemoryDuration'),
      weaveThreshold: _i(j, 'weaveThreshold'),
      weaveWindow: _d(j, 'weaveWindow'),
      weaveBonusDuration: _d(j, 'weaveBonusDuration'),
      weaveBonusMultiplier: _d(j, 'weaveBonusMultiplier'),
      weaveHealPerSwitch: _d(j, 'weaveHealPerSwitch'),
      fluxSwitchCooldown: _d(j, 'fluxSwitchCooldown'),
      stagnationPenaltyTime: _d(j, 'stagnationPenaltyTime'),
      stagnationDamageReduction: _d(j, 'stagnationDamageReduction'),
    );
  }

  static double _d(Map<String, dynamic> j, String k) =>
      (j[k] as num?)?.toDouble() ?? 0.0;
  static int _i(Map<String, dynamic> j, String k) =>
      (j[k] as num?)?.toInt() ?? 0;
  static bool _b(Map<String, dynamic> j, String k) =>
      j[k] as bool? ?? false;
  static List<double> _dl(Map<String, dynamic> j, String k) =>
      (j[k] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const [];

  /// Serialize all non-default fields to a JSON map.
  Map<String, dynamic> toJson() {
    final j = <String, dynamic>{};
    void d(String k, double v) { if (v != 0.0) j[k] = v; }
    void i(String k, int v) { if (v != 0) j[k] = v; }
    void b(String k, bool v) { if (v) j[k] = v; }
    d('rhythmPulseInterval', rhythmPulseInterval);
    d('rhythmBeatWindow', rhythmBeatWindow);
    d('rhythmDamageBonus', rhythmDamageBonus);
    d('rhythmCooldownRefund', rhythmCooldownRefund);
    d('rhythmManaRefund', rhythmManaRefund);
    i('grooveMaxStacks', grooveMaxStacks);
    d('grooveHastePerStack', grooveHastePerStack);
    d('windupReduction', windupReduction);
    d('castTimeReduction', castTimeReduction);
    d('cancelWindowDuration', cancelWindowDuration);
    i('cancelMaxChain', cancelMaxChain);
    if (cancelChainDamageScale.isNotEmpty) j['cancelChainDamageScale'] = cancelChainDamageScale;
    d('channelTickSpeedBonus', channelTickSpeedBonus);
    d('movementForwardRangeBonus', movementForwardRangeBonus);
    d('movementForwardDamageBonus', movementForwardDamageBonus);
    d('movementBackwardDamageReduction', movementBackwardDamageReduction);
    d('movementBackwardKnockbackBonus', movementBackwardKnockbackBonus);
    d('movementStrafeDodgeBonus', movementStrafeDodgeBonus);
    b('movementStrafePiercing', movementStrafePiercing);
    d('movementStationaryDamageBonus', movementStationaryDamageBonus);
    d('movementStationaryAoeBonus', movementStationaryAoeBonus);
    d('movementInputWindow', movementInputWindow);
    d('predatorActivationTime', predatorActivationTime);
    d('predatorExposedDuration', predatorExposedDuration);
    d('predatorExposedDamageBonus', predatorExposedDamageBonus);
    i('heatPerCast', heatPerCast);
    i('heatMaxStacks', heatMaxStacks);
    d('heatDecayRate', heatDecayRate);
    d('heatManaCostPerStack', heatManaCostPerStack);
    d('heatDamageTakenPerStack', heatDamageTakenPerStack);
    d('overheatSilenceDuration', overheatSilenceDuration);
    d('overheatCooldownPenalty', overheatCooldownPenalty);
    d('coolDownPayoffDamageBonus', coolDownPayoffDamageBonus);
    i('momentumMaxStacks', momentumMaxStacks);
    d('momentumDecayInterval', momentumDecayInterval);
    d('momentumCooldownPerStack', momentumCooldownPerStack);
    d('momentumAoePerStack', momentumAoePerStack);
    d('momentumCastPerStack', momentumCastPerStack);
    d('momentumDamagePerStack', momentumDamagePerStack);
    b('momentumSplashAtMax', momentumSplashAtMax);
    d('momentumSplashRatio', momentumSplashRatio);
    d('momentumSplashRadius', momentumSplashRadius);
    d('kineticOverflowBonus', kineticOverflowBonus);
    d('pressurePerMelee', pressurePerMelee);
    d('pressurePerRanged', pressurePerRanged);
    d('pressurePerDot', pressurePerDot);
    d('pressureDecayPerSecond', pressureDecayPerSecond);
    d('pressureComboBonus', pressureComboBonus);
    d('pressureWindupBonus', pressureWindupBonus);
    d('pressureBreakStunDuration', pressureBreakStunDuration);
    d('pressureBreakDamageBonus', pressureBreakDamageBonus);
    b('pressureBreakResetsAllCooldowns', pressureBreakResetsAllCooldowns);
    d('transitionBonusDamage', transitionBonusDamage);
    d('transitionBonusWindow', transitionBonusWindow);
    b('transitionInstantCast', transitionInstantCast);
    b('transitionNoManaCost', transitionNoManaCost);
    d('fluxMemoryDuration', fluxMemoryDuration);
    i('weaveThreshold', weaveThreshold);
    d('weaveWindow', weaveWindow);
    d('weaveBonusDuration', weaveBonusDuration);
    d('weaveBonusMultiplier', weaveBonusMultiplier);
    d('weaveHealPerSwitch', weaveHealPerSwitch);
    d('fluxSwitchCooldown', fluxSwitchCooldown);
    d('stagnationPenaltyTime', stagnationPenaltyTime);
    d('stagnationDamageReduction', stagnationDamageReduction);
    return j;
  }

  /// Merge sparse overrides onto an existing mechanics, producing a new instance.
  static StanceMechanics merge(
    StanceMechanics base,
    Map<String, dynamic> overrides,
  ) {
    final merged = <String, dynamic>{...base.toJson(), ...overrides};
    return StanceMechanics.fromJson(merged);
  }

  /// Tooltip lines describing active mechanics.
  List<String> get mechanicsSummary {
    final lines = <String>[];

    // Cadence
    if (rhythmPulseInterval > 0) {
      final bpm = (60.0 / rhythmPulseInterval).round();
      lines.add('Rhythm pulse: $bpm BPM (+-${(rhythmBeatWindow * 1000).round()}ms window)');
      lines.add('On-beat: +${(rhythmDamageBonus * 100).round()}% dmg, '
          '-${(rhythmCooldownRefund * 100).round()}% CD, '
          '${(rhythmManaRefund * 100).round()}% mana refund');
      lines.add('Groove: up to $grooveMaxStacks stacks (+${(grooveHastePerStack * 100).round()}% haste each)');
    }

    // Tempest
    if (cancelWindowDuration > 0) {
      lines.add('Windup -${(windupReduction * 100).round()}%, cast time -${(castTimeReduction * 100).round()}%');
      lines.add('${(cancelWindowDuration * 1000).round()}ms cancel window, chains up to $cancelMaxChain deep');
      if (cancelChainDamageScale.isNotEmpty) {
        final scales = cancelChainDamageScale
            .map((s) => '${(s * 100).round()}%')
            .join(' -> ');
        lines.add('Chain damage: $scales');
      }
    }

    // Warden
    if (movementInputWindow > 0) {
      lines.add('W: +${(movementForwardRangeBonus * 100).round()}% range, +${(movementForwardDamageBonus * 100).round()}% dmg');
      lines.add('S: -${(movementBackwardDamageReduction * 100).round()}% dmg taken');
      lines.add('A/D: +${(movementStrafeDodgeBonus * 100).round()}% dodge${movementStrafePiercing ? ', piercing' : ''}');
      lines.add('Still: +${(movementStationaryDamageBonus * 100).round()}% dmg, +${(movementStationaryAoeBonus * 100).round()}% AoE');
      if (predatorActivationTime > 0) {
        lines.add('Predator\'s Eye: ${predatorActivationTime.toStringAsFixed(0)}s setup, +${(predatorExposedDamageBonus * 100).round()}% Exposed');
      }
    }

    // Crucible
    if (heatMaxStacks > 0) {
      lines.add('Heat: +${(heatManaCostPerStack * 100).round()}% mana/stack, +${(heatDamageTakenPerStack * 100).round()}% dmg taken/stack');
      lines.add('Overheat at $heatMaxStacks: ${overheatSilenceDuration.toStringAsFixed(0)}s silence');
      lines.add('0-Heat opener: +${(coolDownPayoffDamageBonus * 100).round()}% damage');
    }

    // Momentum
    if (momentumMaxStacks > 0) {
      lines.add('Per stack: -${(momentumCooldownPerStack * 100).round()}% CD, +${(momentumDamagePerStack * 100).round()}% dmg, '
          '+${(momentumAoePerStack * 100).round()}% AoE');
      lines.add('Max $momentumMaxStacks stacks, decay 1/${momentumDecayInterval.toStringAsFixed(1)}s');
      if (momentumSplashAtMax) {
        lines.add('At max: ${(momentumSplashRatio * 100).round()}% splash in ${momentumSplashRadius.toStringAsFixed(0)}u');
      }
      if (kineticOverflowBonus > 0) {
        lines.add('Kinetic Overflow: +${(kineticOverflowBonus * 100).round()}% cross-domain bonus at max');
      }
    }

    // Pressure
    if (pressureBreakStunDuration > 0) {
      lines.add('Pressure: melee ${(pressurePerMelee * 100).round()}%, ranged ${(pressurePerRanged * 100).round()}%, DoT ${(pressurePerDot * 100).round()}%');
      lines.add('Break: ${pressureBreakStunDuration.toStringAsFixed(0)}s stun, +${(pressureBreakDamageBonus * 100).round()}% dmg');
      if (pressureBreakResetsAllCooldowns) lines.add('Break resets all cooldowns');
      lines.add('Decay: ${(pressureDecayPerSecond * 100).round()}%/s when not hitting');
    }

    // Flux
    if (transitionBonusWindow > 0) {
      lines.add('Transition: +${(transitionBonusDamage * 100).round()}% dmg${transitionInstantCast ? ', instant' : ''}${transitionNoManaCost ? ', free' : ''}');
      lines.add('Memory: return within ${fluxMemoryDuration.toStringAsFixed(0)}s for CD reset');
      lines.add('Weave State: $weaveThreshold switches in ${weaveWindow.toStringAsFixed(0)}s = +${(weaveBonusMultiplier * 100).round()}% all');
      lines.add('Stagnation: -${(stagnationDamageReduction * 100).round()}% dmg after ${stagnationPenaltyTime.toStringAsFixed(0)}s');
    }

    return lines;
  }
}
