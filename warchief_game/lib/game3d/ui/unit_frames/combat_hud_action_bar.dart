part of 'combat_hud.dart';

extension _CombatHUDActionBar on CombatHUD {

  /// Check if an ability in a slot is out of range of current target
  bool _isSlotOutOfRange(int slotIndex, double? distanceToTarget) {
    if (actionBarConfig == null || distanceToTarget == null) return false;
    final abilityData = actionBarConfig!.getSlotAbilityData(slotIndex);
    if (abilityData.isSelfCast) return false;
    if (abilityData.range <= 0) return false;
    return distanceToTarget > abilityData.range;
  }

  Widget _buildActionBar() {
    // Reason: Summoned units get only 5 action bar slots vs 10 for player characters
    final visibleSlots = gameState?.activeActionBarSlots ?? 10;

    // Get colors from action bar config if available
    final slotColors = List.generate(10, (i) =>
      actionBarConfig?.getSlotColor(i) ?? const Color(0xFFB3B3CC));

    // Compute distance to current target once for range checking
    final distanceToTarget = gameState?.getDistanceToCurrentTarget();

    // Define slot data for all 10 slots
    final slots = [
      (label: '1', cooldown: abilityCooldowns[0], maxCooldown: abilityCooldownMaxes[0], onPressed: onAbility1Pressed),
      (label: '2', cooldown: abilityCooldowns[1], maxCooldown: abilityCooldownMaxes[1], onPressed: onAbility2Pressed),
      (label: '3', cooldown: abilityCooldowns[2], maxCooldown: abilityCooldownMaxes[2], onPressed: onAbility3Pressed),
      (label: '4', cooldown: abilityCooldowns[3], maxCooldown: abilityCooldownMaxes[3], onPressed: onAbility4Pressed),
      (label: '5', cooldown: abilityCooldowns[4], maxCooldown: abilityCooldownMaxes[4], onPressed: onAbility5Pressed),
      (label: '6', cooldown: abilityCooldowns[5], maxCooldown: abilityCooldownMaxes[5], onPressed: onAbility6Pressed),
      (label: '7', cooldown: abilityCooldowns[6], maxCooldown: abilityCooldownMaxes[6], onPressed: onAbility7Pressed),
      (label: '8', cooldown: abilityCooldowns[7], maxCooldown: abilityCooldownMaxes[7], onPressed: onAbility8Pressed),
      (label: '9', cooldown: abilityCooldowns[8], maxCooldown: abilityCooldownMaxes[8], onPressed: onAbility9Pressed),
      (label: '0', cooldown: abilityCooldowns[9], maxCooldown: abilityCooldownMaxes[9], onPressed: onAbility10Pressed),
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
              return Padding(
                padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                child: _buildDraggableSlot(
                  slotIndex: i,
                  label: slot.label,
                  color: slotColors[i],
                  cooldown: slot.cooldown,
                  maxCooldown: slot.maxCooldown,
                  onPressed: slot.onPressed ?? () {},
                  isOutOfRange: _isSlotOutOfRange(i, distanceToTarget),
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
                return Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  child: _buildDraggableSlot(
                    slotIndex: slotIdx,
                    label: slot.label,
                    color: slotColors[slotIdx],
                    cooldown: slot.cooldown,
                    maxCooldown: slot.maxCooldown,
                    onPressed: slot.onPressed ?? () {},
                    isOutOfRange: _isSlotOutOfRange(slotIdx, distanceToTarget),
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
