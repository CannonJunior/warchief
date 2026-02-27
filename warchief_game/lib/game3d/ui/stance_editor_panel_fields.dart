part of 'stance_editor_panel.dart';

/// Tooltip text for every stance editor field.
const Map<String, String> _tooltips = {
  'name': 'Unique identifier for this stance. Cannot be changed.',
  'description': 'Flavor text shown in stance tooltips and cards.',
  'damageMultiplier': 'Multiplier to all outgoing damage (1.0 = baseline).',
  'damageTakenMultiplier': 'Multiplier to all incoming damage (1.0 = baseline).',
  'movementSpeedMultiplier': 'Multiplier to movement speed (1.0 = baseline).',
  'cooldownMultiplier': 'Multiplier to ability cooldowns (lower = faster).',
  'manaRegenMultiplier': 'Multiplier to all mana regeneration rates.',
  'manaCostMultiplier': 'Multiplier to ability mana costs.',
  'healingMultiplier': 'Multiplier to all healing done.',
  'maxHealthMultiplier': 'Multiplier to maximum health pool.',
  'castTimeMultiplier': 'Multiplier to cast/windup times (lower = faster).',
  'healthDrainPerSecond': 'Fraction of max HP drained per second (e.g. 0.02 = 2%).',
  'damageTakenToManaRatio': 'Fraction of damage taken converted to mana.',
  'usesHpForMana': 'When true, abilities cost HP instead of mana.',
  'hpForManaRatio': 'HP-to-mana conversion ratio when usesHpForMana is true.',
  'convertsManaRegenToHeal': 'When true, mana regen heals HP instead.',
  'rerollInterval': 'Seconds between random modifier re-rolls.',
  'hasRandomModifiers': 'When true, damage/damageTaken are randomized.',
  'rerollDamageMin': 'Minimum value for random damage multiplier roll.',
  'rerollDamageMax': 'Maximum value for random damage multiplier roll.',
  'rerollDamageTakenMin': 'Minimum value for random damage taken multiplier roll.',
  'rerollDamageTakenMax': 'Maximum value for random damage taken multiplier roll.',
  'switchCooldown': 'Seconds before you can switch to another stance.',
  'spellPushbackInflicted':
      'Fraction of cast time pushed back per hit on a casting target (0.25 = 25%).',
  'spellPushbackResistance':
      'Resistance to spell pushback (1.0 = immune, 0.5 = 50% reduction).',
  'ccDurationInflicted': 'Multiplier to CC duration you apply (1.30 = 30% longer).',
  'ccDurationReceived': 'Multiplier to CC duration applied to you (0.60 = 40% shorter).',
  'lifestealRatio': 'Fraction of damage dealt that heals you (0.10 = 10%).',
  'dodgeChance': 'Chance to completely avoid an incoming attack (0.12 = 12%).',
  'manaCostDisruption':
      'Increases enemy mana costs in your aura (0.15 = 15%). PvP infrastructure.',
  'colorR': 'Red component of stance color (0.0–1.0).',
  'colorG': 'Green component of stance color (0.0–1.0).',
  'colorB': 'Blue component of stance color (0.0–1.0).',
};

// ==================== FIELD WIDGETS ====================

extension _StanceEditorFields on _StanceEditorPanelState {
  Widget _withTooltip(String tooltipKey, Widget child) {
    final tip = _tooltips[tooltipKey];
    if (tip == null) return child;
    return Tooltip(
      message: tip,
      preferBelow: false,
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: BoxDecoration(
        color: const Color(0xDD1a1a2e),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.cyan.withOpacity(0.5)),
      ),
      waitDuration: const Duration(milliseconds: 400),
      child: child,
    );
  }

  Widget _buildReadOnlyField(String label, String value, String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: _withTooltip(tooltipKey, Text(label, style: _labelStyle))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String tooltipKey,
      {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(width: 80, child: _withTooltip(tooltipKey, Text(label, style: _labelStyle))),
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: multiline ? 2 : 1,
              style: _inputStyle,
              decoration: _inputDecoration,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericRow(String label, TextEditingController ctrl, String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: _withTooltip(tooltipKey, Text(label, style: _labelStyle))),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: _inputStyle,
              decoration: _inputDecoration,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, TextEditingController rCtrl,
      TextEditingController gCtrl, TextEditingController bCtrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: _labelStyle)),
          _colorField('R', rCtrl, 'colorR'),
          const SizedBox(width: 4),
          _colorField('G', gCtrl, 'colorG'),
          const SizedBox(width: 4),
          _colorField('B', bCtrl, 'colorB'),
        ],
      ),
    );
  }

  Widget _colorField(String hint, TextEditingController ctrl, String tooltipKey) {
    return Expanded(
      child: _withTooltip(
        tooltipKey,
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: _inputStyle,
          decoration: _inputDecoration.copyWith(hintText: hint),
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
      String label, bool value, ValueChanged<bool> onChanged, String tooltipKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 150, child: _withTooltip(tooltipKey, Text(label, style: _labelStyle))),
          SizedBox(
            height: 24,
            child: Switch(
              value: value,
              onChanged: onChanged,
              // Reason: _accent is static const Colors.cyan on the state class
              activeColor: Colors.cyan,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STYLES ====================

  TextStyle get _labelStyle =>
      const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold);

  TextStyle get _inputStyle => const TextStyle(color: Colors.white, fontSize: 11);

  InputDecoration get _inputDecoration => const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        filled: true,
        fillColor: Colors.black38,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyan),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      );
}
