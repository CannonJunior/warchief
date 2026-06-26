part of 'stance_editor_panel.dart';

/// Extension that adds mechanics-specific editor fields to the stance editor.
///
/// Only visible when the stance has a non-null [StanceData.mechanics].
/// Each stance type gets its own section with the relevant fields.
extension _StanceEditorMechanics on _StanceEditorPanelState {
  /// Create controllers for all mechanics fields. Called from [_populateFromStance].
  static Map<String, TextEditingController> createMechanicsControllers(
    StanceMechanics m,
  ) {
    final c = <String, TextEditingController>{};
    // Cadence
    c['rhythmPulseInterval'] = TextEditingController(text: m.rhythmPulseInterval.toString());
    c['rhythmBeatWindow'] = TextEditingController(text: m.rhythmBeatWindow.toString());
    c['rhythmDamageBonus'] = TextEditingController(text: m.rhythmDamageBonus.toString());
    c['rhythmCooldownRefund'] = TextEditingController(text: m.rhythmCooldownRefund.toString());
    c['rhythmManaRefund'] = TextEditingController(text: m.rhythmManaRefund.toString());
    c['grooveMaxStacks'] = TextEditingController(text: m.grooveMaxStacks.toString());
    c['grooveHastePerStack'] = TextEditingController(text: m.grooveHastePerStack.toString());
    // Tempest
    c['windupReduction'] = TextEditingController(text: m.windupReduction.toString());
    c['castTimeReduction'] = TextEditingController(text: m.castTimeReduction.toString());
    c['cancelWindowDuration'] = TextEditingController(text: m.cancelWindowDuration.toString());
    c['cancelMaxChain'] = TextEditingController(text: m.cancelMaxChain.toString());
    c['channelTickSpeedBonus'] = TextEditingController(text: m.channelTickSpeedBonus.toString());
    // Warden
    c['movementForwardRangeBonus'] = TextEditingController(text: m.movementForwardRangeBonus.toString());
    c['movementForwardDamageBonus'] = TextEditingController(text: m.movementForwardDamageBonus.toString());
    c['movementBackwardDamageReduction'] = TextEditingController(text: m.movementBackwardDamageReduction.toString());
    c['movementStrafeDodgeBonus'] = TextEditingController(text: m.movementStrafeDodgeBonus.toString());
    c['movementStationaryDamageBonus'] = TextEditingController(text: m.movementStationaryDamageBonus.toString());
    c['movementStationaryAoeBonus'] = TextEditingController(text: m.movementStationaryAoeBonus.toString());
    c['movementInputWindow'] = TextEditingController(text: m.movementInputWindow.toString());
    c['predatorActivationTime'] = TextEditingController(text: m.predatorActivationTime.toString());
    c['predatorExposedDuration'] = TextEditingController(text: m.predatorExposedDuration.toString());
    c['predatorExposedDamageBonus'] = TextEditingController(text: m.predatorExposedDamageBonus.toString());
    // Crucible
    c['heatPerCast'] = TextEditingController(text: m.heatPerCast.toString());
    c['heatMaxStacks'] = TextEditingController(text: m.heatMaxStacks.toString());
    c['heatDecayRate'] = TextEditingController(text: m.heatDecayRate.toString());
    c['heatManaCostPerStack'] = TextEditingController(text: m.heatManaCostPerStack.toString());
    c['heatDamageTakenPerStack'] = TextEditingController(text: m.heatDamageTakenPerStack.toString());
    c['overheatSilenceDuration'] = TextEditingController(text: m.overheatSilenceDuration.toString());
    c['overheatCooldownPenalty'] = TextEditingController(text: m.overheatCooldownPenalty.toString());
    c['coolDownPayoffDamageBonus'] = TextEditingController(text: m.coolDownPayoffDamageBonus.toString());
    // Momentum
    c['momentumMaxStacks'] = TextEditingController(text: m.momentumMaxStacks.toString());
    c['momentumDecayInterval'] = TextEditingController(text: m.momentumDecayInterval.toString());
    c['momentumCooldownPerStack'] = TextEditingController(text: m.momentumCooldownPerStack.toString());
    c['momentumAoePerStack'] = TextEditingController(text: m.momentumAoePerStack.toString());
    c['momentumCastPerStack'] = TextEditingController(text: m.momentumCastPerStack.toString());
    c['momentumDamagePerStack'] = TextEditingController(text: m.momentumDamagePerStack.toString());
    c['momentumSplashRatio'] = TextEditingController(text: m.momentumSplashRatio.toString());
    c['momentumSplashRadius'] = TextEditingController(text: m.momentumSplashRadius.toString());
    c['kineticOverflowBonus'] = TextEditingController(text: m.kineticOverflowBonus.toString());
    // Pressure
    c['pressurePerMelee'] = TextEditingController(text: m.pressurePerMelee.toString());
    c['pressurePerRanged'] = TextEditingController(text: m.pressurePerRanged.toString());
    c['pressurePerDot'] = TextEditingController(text: m.pressurePerDot.toString());
    c['pressureDecayPerSecond'] = TextEditingController(text: m.pressureDecayPerSecond.toString());
    c['pressureComboBonus'] = TextEditingController(text: m.pressureComboBonus.toString());
    c['pressureWindupBonus'] = TextEditingController(text: m.pressureWindupBonus.toString());
    c['pressureBreakStunDuration'] = TextEditingController(text: m.pressureBreakStunDuration.toString());
    c['pressureBreakDamageBonus'] = TextEditingController(text: m.pressureBreakDamageBonus.toString());
    // Flux
    c['transitionBonusDamage'] = TextEditingController(text: m.transitionBonusDamage.toString());
    c['transitionBonusWindow'] = TextEditingController(text: m.transitionBonusWindow.toString());
    c['fluxMemoryDuration'] = TextEditingController(text: m.fluxMemoryDuration.toString());
    c['weaveThreshold'] = TextEditingController(text: m.weaveThreshold.toString());
    c['weaveWindow'] = TextEditingController(text: m.weaveWindow.toString());
    c['weaveBonusDuration'] = TextEditingController(text: m.weaveBonusDuration.toString());
    c['weaveBonusMultiplier'] = TextEditingController(text: m.weaveBonusMultiplier.toString());
    c['weaveHealPerSwitch'] = TextEditingController(text: m.weaveHealPerSwitch.toString());
    c['fluxSwitchCooldown'] = TextEditingController(text: m.fluxSwitchCooldown.toString());
    c['stagnationPenaltyTime'] = TextEditingController(text: m.stagnationPenaltyTime.toString());
    c['stagnationDamageReduction'] = TextEditingController(text: m.stagnationDamageReduction.toString());
    return c;
  }

  /// Update existing controllers with new mechanic values.
  static void updateMechanicsControllers(
    Map<String, TextEditingController> c,
    StanceMechanics m,
  ) {
    c['rhythmPulseInterval']?.text = m.rhythmPulseInterval.toString();
    c['rhythmBeatWindow']?.text = m.rhythmBeatWindow.toString();
    c['rhythmDamageBonus']?.text = m.rhythmDamageBonus.toString();
    c['rhythmCooldownRefund']?.text = m.rhythmCooldownRefund.toString();
    c['rhythmManaRefund']?.text = m.rhythmManaRefund.toString();
    c['grooveMaxStacks']?.text = m.grooveMaxStacks.toString();
    c['grooveHastePerStack']?.text = m.grooveHastePerStack.toString();
    c['windupReduction']?.text = m.windupReduction.toString();
    c['castTimeReduction']?.text = m.castTimeReduction.toString();
    c['cancelWindowDuration']?.text = m.cancelWindowDuration.toString();
    c['cancelMaxChain']?.text = m.cancelMaxChain.toString();
    c['channelTickSpeedBonus']?.text = m.channelTickSpeedBonus.toString();
    c['movementForwardRangeBonus']?.text = m.movementForwardRangeBonus.toString();
    c['movementForwardDamageBonus']?.text = m.movementForwardDamageBonus.toString();
    c['movementBackwardDamageReduction']?.text = m.movementBackwardDamageReduction.toString();
    c['movementStrafeDodgeBonus']?.text = m.movementStrafeDodgeBonus.toString();
    c['movementStationaryDamageBonus']?.text = m.movementStationaryDamageBonus.toString();
    c['movementStationaryAoeBonus']?.text = m.movementStationaryAoeBonus.toString();
    c['movementInputWindow']?.text = m.movementInputWindow.toString();
    c['predatorActivationTime']?.text = m.predatorActivationTime.toString();
    c['predatorExposedDuration']?.text = m.predatorExposedDuration.toString();
    c['predatorExposedDamageBonus']?.text = m.predatorExposedDamageBonus.toString();
    c['heatPerCast']?.text = m.heatPerCast.toString();
    c['heatMaxStacks']?.text = m.heatMaxStacks.toString();
    c['heatDecayRate']?.text = m.heatDecayRate.toString();
    c['heatManaCostPerStack']?.text = m.heatManaCostPerStack.toString();
    c['heatDamageTakenPerStack']?.text = m.heatDamageTakenPerStack.toString();
    c['overheatSilenceDuration']?.text = m.overheatSilenceDuration.toString();
    c['overheatCooldownPenalty']?.text = m.overheatCooldownPenalty.toString();
    c['coolDownPayoffDamageBonus']?.text = m.coolDownPayoffDamageBonus.toString();
    c['momentumMaxStacks']?.text = m.momentumMaxStacks.toString();
    c['momentumDecayInterval']?.text = m.momentumDecayInterval.toString();
    c['momentumCooldownPerStack']?.text = m.momentumCooldownPerStack.toString();
    c['momentumAoePerStack']?.text = m.momentumAoePerStack.toString();
    c['momentumCastPerStack']?.text = m.momentumCastPerStack.toString();
    c['momentumDamagePerStack']?.text = m.momentumDamagePerStack.toString();
    c['momentumSplashRatio']?.text = m.momentumSplashRatio.toString();
    c['momentumSplashRadius']?.text = m.momentumSplashRadius.toString();
    c['kineticOverflowBonus']?.text = m.kineticOverflowBonus.toString();
    c['pressurePerMelee']?.text = m.pressurePerMelee.toString();
    c['pressurePerRanged']?.text = m.pressurePerRanged.toString();
    c['pressurePerDot']?.text = m.pressurePerDot.toString();
    c['pressureDecayPerSecond']?.text = m.pressureDecayPerSecond.toString();
    c['pressureComboBonus']?.text = m.pressureComboBonus.toString();
    c['pressureWindupBonus']?.text = m.pressureWindupBonus.toString();
    c['pressureBreakStunDuration']?.text = m.pressureBreakStunDuration.toString();
    c['pressureBreakDamageBonus']?.text = m.pressureBreakDamageBonus.toString();
    c['transitionBonusDamage']?.text = m.transitionBonusDamage.toString();
    c['transitionBonusWindow']?.text = m.transitionBonusWindow.toString();
    c['fluxMemoryDuration']?.text = m.fluxMemoryDuration.toString();
    c['weaveThreshold']?.text = m.weaveThreshold.toString();
    c['weaveWindow']?.text = m.weaveWindow.toString();
    c['weaveBonusDuration']?.text = m.weaveBonusDuration.toString();
    c['weaveBonusMultiplier']?.text = m.weaveBonusMultiplier.toString();
    c['weaveHealPerSwitch']?.text = m.weaveHealPerSwitch.toString();
    c['fluxSwitchCooldown']?.text = m.fluxSwitchCooldown.toString();
    c['stagnationPenaltyTime']?.text = m.stagnationPenaltyTime.toString();
    c['stagnationDamageReduction']?.text = m.stagnationDamageReduction.toString();
  }

  /// Build the stance-specific mechanics section.
  Widget buildMechanicsSection(Map<String, TextEditingController> c, StanceId id) {
    return switch (id) {
      StanceId.cadence => _buildSection('CADENCE — RHYTHM', const Color(0xFFE69833), [
        _buildNumericRow('Pulse Interval (s)', c['rhythmPulseInterval']!, 'rhythmPulseInterval'),
        _buildNumericRow('Beat Window (s)', c['rhythmBeatWindow']!, 'rhythmBeatWindow'),
        _buildNumericRow('On-Beat Dmg Bonus', c['rhythmDamageBonus']!, 'rhythmDamageBonus'),
        _buildNumericRow('On-Beat CD Refund', c['rhythmCooldownRefund']!, 'rhythmCooldownRefund'),
        _buildNumericRow('On-Beat Mana Refund', c['rhythmManaRefund']!, 'rhythmManaRefund'),
        _buildNumericRow('Max Groove Stacks', c['grooveMaxStacks']!, 'grooveMaxStacks'),
        _buildNumericRow('Haste / Stack', c['grooveHastePerStack']!, 'grooveHastePerStack'),
      ]),
      StanceId.tempest => _buildSection('TEMPEST — SPEED', const Color(0xFFFF7320), [
        _buildNumericRow('Windup Reduction', c['windupReduction']!, 'windupReduction'),
        _buildNumericRow('Cast Time Reduction', c['castTimeReduction']!, 'castTimeReduction'),
        _buildNumericRow('Cancel Window (s)', c['cancelWindowDuration']!, 'cancelWindowDuration'),
        _buildNumericRow('Max Chain Depth', c['cancelMaxChain']!, 'cancelMaxChain'),
        _buildNumericRow('Channel Tick Speed', c['channelTickSpeedBonus']!, 'channelTickSpeedBonus'),
      ]),
      StanceId.warden => _buildSection('WARDEN — MOVEMENT', const Color(0xFF4D8C59), [
        _buildNumericRow('Fwd Range Bonus', c['movementForwardRangeBonus']!, 'movementForwardRangeBonus'),
        _buildNumericRow('Fwd Dmg Bonus', c['movementForwardDamageBonus']!, 'movementForwardDamageBonus'),
        _buildNumericRow('Back Dmg Reduce', c['movementBackwardDamageReduction']!, 'movementBackwardDamageReduction'),
        _buildNumericRow('Strafe Dodge', c['movementStrafeDodgeBonus']!, 'movementStrafeDodgeBonus'),
        _buildNumericRow('Still Dmg Bonus', c['movementStationaryDamageBonus']!, 'movementStationaryDamageBonus'),
        _buildNumericRow('Still AoE Bonus', c['movementStationaryAoeBonus']!, 'movementStationaryAoeBonus'),
        _buildNumericRow('Input Window (s)', c['movementInputWindow']!, 'movementInputWindow'),
        _buildNumericRow('Predator Time (s)', c['predatorActivationTime']!, 'predatorActivationTime'),
        _buildNumericRow('Exposed Duration', c['predatorExposedDuration']!, 'predatorExposedDuration'),
        _buildNumericRow('Exposed Dmg Bonus', c['predatorExposedDamageBonus']!, 'predatorExposedDamageBonus'),
      ]),
      StanceId.crucible => _buildSection('CRUCIBLE — HEAT', const Color(0xFFCC4400), [
        _buildNumericRow('Heat Per Cast', c['heatPerCast']!, 'heatPerCast'),
        _buildNumericRow('Max Heat', c['heatMaxStacks']!, 'heatMaxStacks'),
        _buildNumericRow('Heat Decay Rate', c['heatDecayRate']!, 'heatDecayRate'),
        _buildNumericRow('Mana Cost / Stack', c['heatManaCostPerStack']!, 'heatManaCostPerStack'),
        _buildNumericRow('Dmg Taken / Stack', c['heatDamageTakenPerStack']!, 'heatDamageTakenPerStack'),
        _buildNumericRow('Overheat Silence (s)', c['overheatSilenceDuration']!, 'overheatSilenceDuration'),
        _buildNumericRow('Overheat CD Penalty', c['overheatCooldownPenalty']!, 'overheatCooldownPenalty'),
        _buildNumericRow('0-Heat Payoff Dmg', c['coolDownPayoffDamageBonus']!, 'coolDownPayoffDamageBonus'),
      ]),
      StanceId.momentum => _buildSection('MOMENTUM — STACKS', const Color(0xFF335599), [
        _buildNumericRow('Max Stacks', c['momentumMaxStacks']!, 'momentumMaxStacks'),
        _buildNumericRow('Decay Interval (s)', c['momentumDecayInterval']!, 'momentumDecayInterval'),
        _buildNumericRow('CD / Stack', c['momentumCooldownPerStack']!, 'momentumCooldownPerStack'),
        _buildNumericRow('AoE / Stack', c['momentumAoePerStack']!, 'momentumAoePerStack'),
        _buildNumericRow('Cast Speed / Stack', c['momentumCastPerStack']!, 'momentumCastPerStack'),
        _buildNumericRow('Damage / Stack', c['momentumDamagePerStack']!, 'momentumDamagePerStack'),
        _buildNumericRow('Splash Ratio', c['momentumSplashRatio']!, 'momentumSplashRatio'),
        _buildNumericRow('Splash Radius', c['momentumSplashRadius']!, 'momentumSplashRadius'),
        _buildNumericRow('Kinetic Overflow', c['kineticOverflowBonus']!, 'kineticOverflowBonus'),
      ]),
      StanceId.pressure => _buildSection('PRESSURE — GAUGE', const Color(0xFFCC2222), [
        _buildNumericRow('Melee Pressure', c['pressurePerMelee']!, 'pressurePerMelee'),
        _buildNumericRow('Ranged Pressure', c['pressurePerRanged']!, 'pressurePerRanged'),
        _buildNumericRow('DoT Pressure', c['pressurePerDot']!, 'pressurePerDot'),
        _buildNumericRow('Decay / Second', c['pressureDecayPerSecond']!, 'pressureDecayPerSecond'),
        _buildNumericRow('Combo Bonus', c['pressureComboBonus']!, 'pressureComboBonus'),
        _buildNumericRow('Windup Bonus', c['pressureWindupBonus']!, 'pressureWindupBonus'),
        _buildNumericRow('Break Stun (s)', c['pressureBreakStunDuration']!, 'pressureBreakStunDuration'),
        _buildNumericRow('Break Dmg Bonus', c['pressureBreakDamageBonus']!, 'pressureBreakDamageBonus'),
      ]),
      StanceId.flux => _buildSection('FLUX — SWITCHING', const Color(0xFF6633AA), [
        _buildNumericRow('Transition Dmg', c['transitionBonusDamage']!, 'transitionBonusDamage'),
        _buildNumericRow('Transition Window', c['transitionBonusWindow']!, 'transitionBonusWindow'),
        _buildNumericRow('Memory Duration', c['fluxMemoryDuration']!, 'fluxMemoryDuration'),
        _buildNumericRow('Weave Threshold', c['weaveThreshold']!, 'weaveThreshold'),
        _buildNumericRow('Weave Window (s)', c['weaveWindow']!, 'weaveWindow'),
        _buildNumericRow('Weave Duration', c['weaveBonusDuration']!, 'weaveBonusDuration'),
        _buildNumericRow('Weave Bonus', c['weaveBonusMultiplier']!, 'weaveBonusMultiplier'),
        _buildNumericRow('Weave Heal/Switch', c['weaveHealPerSwitch']!, 'weaveHealPerSwitch'),
        _buildNumericRow('Flux Switch CD', c['fluxSwitchCooldown']!, 'fluxSwitchCooldown'),
        _buildNumericRow('Stagnation Time', c['stagnationPenaltyTime']!, 'stagnationPenaltyTime'),
        _buildNumericRow('Stagnation Penalty', c['stagnationDamageReduction']!, 'stagnationDamageReduction'),
      ]),
      _ => const SizedBox.shrink(),
    };
  }

  /// Build mechanics override map from controller values.
  /// Only includes fields that differ from the original mechanics.
  static Map<String, dynamic> buildMechanicsOverrides(
    Map<String, TextEditingController> c,
    StanceMechanics original,
  ) {
    final o = <String, dynamic>{};
    void chk(String k, String val, num orig) {
      final p = num.tryParse(val);
      if (p != null && p != orig) o[k] = p;
    }

    chk('rhythmPulseInterval', c['rhythmPulseInterval']!.text, original.rhythmPulseInterval);
    chk('rhythmBeatWindow', c['rhythmBeatWindow']!.text, original.rhythmBeatWindow);
    chk('rhythmDamageBonus', c['rhythmDamageBonus']!.text, original.rhythmDamageBonus);
    chk('rhythmCooldownRefund', c['rhythmCooldownRefund']!.text, original.rhythmCooldownRefund);
    chk('rhythmManaRefund', c['rhythmManaRefund']!.text, original.rhythmManaRefund);
    chk('grooveMaxStacks', c['grooveMaxStacks']!.text, original.grooveMaxStacks);
    chk('grooveHastePerStack', c['grooveHastePerStack']!.text, original.grooveHastePerStack);
    chk('windupReduction', c['windupReduction']!.text, original.windupReduction);
    chk('castTimeReduction', c['castTimeReduction']!.text, original.castTimeReduction);
    chk('cancelWindowDuration', c['cancelWindowDuration']!.text, original.cancelWindowDuration);
    chk('cancelMaxChain', c['cancelMaxChain']!.text, original.cancelMaxChain);
    chk('channelTickSpeedBonus', c['channelTickSpeedBonus']!.text, original.channelTickSpeedBonus);
    chk('movementForwardRangeBonus', c['movementForwardRangeBonus']!.text, original.movementForwardRangeBonus);
    chk('movementForwardDamageBonus', c['movementForwardDamageBonus']!.text, original.movementForwardDamageBonus);
    chk('movementBackwardDamageReduction', c['movementBackwardDamageReduction']!.text, original.movementBackwardDamageReduction);
    chk('movementStrafeDodgeBonus', c['movementStrafeDodgeBonus']!.text, original.movementStrafeDodgeBonus);
    chk('movementStationaryDamageBonus', c['movementStationaryDamageBonus']!.text, original.movementStationaryDamageBonus);
    chk('movementStationaryAoeBonus', c['movementStationaryAoeBonus']!.text, original.movementStationaryAoeBonus);
    chk('movementInputWindow', c['movementInputWindow']!.text, original.movementInputWindow);
    chk('predatorActivationTime', c['predatorActivationTime']!.text, original.predatorActivationTime);
    chk('predatorExposedDuration', c['predatorExposedDuration']!.text, original.predatorExposedDuration);
    chk('predatorExposedDamageBonus', c['predatorExposedDamageBonus']!.text, original.predatorExposedDamageBonus);
    chk('heatPerCast', c['heatPerCast']!.text, original.heatPerCast);
    chk('heatMaxStacks', c['heatMaxStacks']!.text, original.heatMaxStacks);
    chk('heatDecayRate', c['heatDecayRate']!.text, original.heatDecayRate);
    chk('heatManaCostPerStack', c['heatManaCostPerStack']!.text, original.heatManaCostPerStack);
    chk('heatDamageTakenPerStack', c['heatDamageTakenPerStack']!.text, original.heatDamageTakenPerStack);
    chk('overheatSilenceDuration', c['overheatSilenceDuration']!.text, original.overheatSilenceDuration);
    chk('overheatCooldownPenalty', c['overheatCooldownPenalty']!.text, original.overheatCooldownPenalty);
    chk('coolDownPayoffDamageBonus', c['coolDownPayoffDamageBonus']!.text, original.coolDownPayoffDamageBonus);
    chk('momentumMaxStacks', c['momentumMaxStacks']!.text, original.momentumMaxStacks);
    chk('momentumDecayInterval', c['momentumDecayInterval']!.text, original.momentumDecayInterval);
    chk('momentumCooldownPerStack', c['momentumCooldownPerStack']!.text, original.momentumCooldownPerStack);
    chk('momentumAoePerStack', c['momentumAoePerStack']!.text, original.momentumAoePerStack);
    chk('momentumCastPerStack', c['momentumCastPerStack']!.text, original.momentumCastPerStack);
    chk('momentumDamagePerStack', c['momentumDamagePerStack']!.text, original.momentumDamagePerStack);
    chk('momentumSplashRatio', c['momentumSplashRatio']!.text, original.momentumSplashRatio);
    chk('momentumSplashRadius', c['momentumSplashRadius']!.text, original.momentumSplashRadius);
    chk('kineticOverflowBonus', c['kineticOverflowBonus']!.text, original.kineticOverflowBonus);
    chk('pressurePerMelee', c['pressurePerMelee']!.text, original.pressurePerMelee);
    chk('pressurePerRanged', c['pressurePerRanged']!.text, original.pressurePerRanged);
    chk('pressurePerDot', c['pressurePerDot']!.text, original.pressurePerDot);
    chk('pressureDecayPerSecond', c['pressureDecayPerSecond']!.text, original.pressureDecayPerSecond);
    chk('pressureComboBonus', c['pressureComboBonus']!.text, original.pressureComboBonus);
    chk('pressureWindupBonus', c['pressureWindupBonus']!.text, original.pressureWindupBonus);
    chk('pressureBreakStunDuration', c['pressureBreakStunDuration']!.text, original.pressureBreakStunDuration);
    chk('pressureBreakDamageBonus', c['pressureBreakDamageBonus']!.text, original.pressureBreakDamageBonus);
    chk('transitionBonusDamage', c['transitionBonusDamage']!.text, original.transitionBonusDamage);
    chk('transitionBonusWindow', c['transitionBonusWindow']!.text, original.transitionBonusWindow);
    chk('fluxMemoryDuration', c['fluxMemoryDuration']!.text, original.fluxMemoryDuration);
    chk('weaveThreshold', c['weaveThreshold']!.text, original.weaveThreshold);
    chk('weaveWindow', c['weaveWindow']!.text, original.weaveWindow);
    chk('weaveBonusDuration', c['weaveBonusDuration']!.text, original.weaveBonusDuration);
    chk('weaveBonusMultiplier', c['weaveBonusMultiplier']!.text, original.weaveBonusMultiplier);
    chk('weaveHealPerSwitch', c['weaveHealPerSwitch']!.text, original.weaveHealPerSwitch);
    chk('fluxSwitchCooldown', c['fluxSwitchCooldown']!.text, original.fluxSwitchCooldown);
    chk('stagnationPenaltyTime', c['stagnationPenaltyTime']!.text, original.stagnationPenaltyTime);
    chk('stagnationDamageReduction', c['stagnationDamageReduction']!.text, original.stagnationDamageReduction);
    return o;
  }
}
