part of 'combat_hud.dart';

extension _CombatHUDActionBar on CombatHUD {

  /// Check if an ability in a slot is out of range of current target.
  /// Accounts for the combo range multiplier when the slot is combo-primed.
  bool _isSlotOutOfRange(int slotIndex, double? distanceToTarget) {
    if (actionBarConfig == null || distanceToTarget == null) return false;
    final abilityData = actionBarConfig!.getSlotAbilityData(slotIndex);
    if (abilityData.isSelfCast) return false;
    if (abilityData.range <= 0) return false;
    final comboBonus = gameState?.activeAbilityComboGcdBonuses[slotIndex] ?? 0.0;
    final rangeMultiplier = comboBonus > 0.0
        ? (gameState?.comboRangeMultiplier ?? 1.0)
        : 1.0;
    return distanceToTarget > abilityData.range * rangeMultiplier;
  }

  Widget _buildActionBar() {
    // Reason: Summoned units get only 5 action bar slots vs 10 for player characters
    final visibleSlots = gameState?.activeActionBarSlots ?? 10;

    // Get colors from action bar config if available
    final slotColors = List.generate(10, (i) =>
      actionBarConfig?.getSlotColor(i) ?? const Color(0xFFB3B3CC));

    // Compute distance to current target once for range checking
    final distanceToTarget = gameState?.getDistanceToCurrentTarget();

    // Reason: GCD locks all slots — display whichever is greater (GCD or per-slot cd)
    // so the clock animation shows on every button for the full GCD duration.
    final gcdRemaining = gameState?.activeGcdRemaining ?? 0.0;
    final gcdMax = gameState?.activeGcdMax ?? 1.0;
    final comboGcdBonuses = gameState?.activeAbilityComboGcdBonuses;

    ({String label, double cooldown, double maxCooldown, bool isComboReady, VoidCallback? onPressed}) makeSlot(
      String label, int i, VoidCallback? onPressed,
    ) {
      final slotCd = abilityCooldowns[i];
      final slotMax = abilityCooldownMaxes[i];
      // Reason: combo bonus reduces the displayed GCD for primed slots only.
      final comboBonus = comboGcdBonuses?[i] ?? 0.0;
      final effectiveGcd = (gcdRemaining - comboBonus).clamp(0.0, double.infinity);
      // When GCD > slot cooldown, show GCD sweep so all buttons animate together.
      // When the slot's own cooldown is longer, it takes precedence.
      final cd = math.max(slotCd, effectiveGcd);
      final max = slotCd >= effectiveGcd ? slotMax : gcdMax;
      // Flag yellow tint when a combo bonus is active for this slot.
      final isComboReady = comboBonus > 0.0 && gcdRemaining > 0.0;
      return (label: label, cooldown: cd, maxCooldown: max, isComboReady: isComboReady, onPressed: onPressed);
    }

    // Define slot data for all 10 slots
    final slots = [
      makeSlot('1', 0, onAbility1Pressed),
      makeSlot('2', 1, onAbility2Pressed),
      makeSlot('3', 2, onAbility3Pressed),
      makeSlot('4', 3, onAbility4Pressed),
      makeSlot('5', 4, onAbility5Pressed),
      makeSlot('6', 5, onAbility6Pressed),
      makeSlot('7', 6, onAbility7Pressed),
      makeSlot('8', 7, onAbility8Pressed),
      makeSlot('9', 8, onAbility9Pressed),
      makeSlot('0', 9, onAbility10Pressed),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF252542),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Slots 1-5
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final slot = slots[i];
              return MouseRegion(
                onEnter: (_) => onSlotHovered?.call(i),
                onExit: (_) => onSlotHovered?.call(null),
                child: Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  child: _buildDraggableSlot(
                    slotIndex: i,
                    label: slot.label,
                    color: slotColors[i],
                    cooldown: slot.cooldown,
                    maxCooldown: slot.maxCooldown,
                    onPressed: slot.onPressed ?? () {},
                    isOutOfRange: _isSlotOutOfRange(i, distanceToTarget),
                    isComboReady: slot.isComboReady,
                  ),
                ),
              );
            }),
          ),
          // Reason: Row 2 hidden for summoned units (5-slot action bar)
          if (visibleSlots > 5) ...[
            const SizedBox(height: 4),
            // Row 2: Slots 6-10
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final slotIdx = i + 5;
                final slot = slots[slotIdx];
                return MouseRegion(
                  onEnter: (_) => onSlotHovered?.call(slotIdx),
                  onExit: (_) => onSlotHovered?.call(null),
                  child: Padding(
                    padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                    child: _buildDraggableSlot(
                      slotIndex: slotIdx,
                      label: slot.label,
                      color: slotColors[slotIdx],
                      cooldown: slot.cooldown,
                      maxCooldown: slot.maxCooldown,
                      onPressed: slot.onPressed ?? () {},
                      isOutOfRange: _isSlotOutOfRange(slotIdx, distanceToTarget),
                      isComboReady: slot.isComboReady,
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  /// Build an action bar slot that accepts ability drops
  Widget _buildDraggableSlot({
    required int slotIndex,
    required String label,
    required Color color,
    required double cooldown,
    required double maxCooldown,
    required VoidCallback onPressed,
    bool isOutOfRange = false,
    bool isComboReady = false,
  }) {
    // Get the ability name for this slot's tooltip
    final abilityName = actionBarConfig?.getSlotAbility(slotIndex);

    // If no drag support, just show normal button
    if (onAbilityDropped == null) {
      return AbilityButton(
        label: label,
        color: color,
        cooldown: cooldown,
        maxCooldown: maxCooldown,
        onPressed: onPressed,
        isOutOfRange: isOutOfRange,
        tooltipText: abilityName,
        isComboReady: isComboReady,
      );
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        onAbilityDropped!(slotIndex, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: Colors.yellow.withValues(alpha: 0.8),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              AbilityButton(
                label: label,
                color: isHovering ? Colors.yellow.shade700 : color,
                cooldown: cooldown,
                maxCooldown: maxCooldown,
                onPressed: onPressed,
                isOutOfRange: isOutOfRange,
                tooltipText: abilityName,
                isComboReady: isComboReady && !isHovering,
              ),
              // Drop indicator overlay
              if (isHovering)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.yellow,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
