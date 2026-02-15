import '../state/game_state.dart';
import '../state/macro_config.dart';
import '../state/abilities_config.dart';
import '../state/action_bar_config.dart' show globalActionBarConfigManager;
import '../../models/macro.dart';
import '../../models/ally.dart';
import '../../models/raid_chat_message.dart';
import '../ai/ally_strategy.dart';
import 'ability_system.dart';

/// Runtime state for one executing macro.
///
/// Tracks which step we're on, GCD timing, loop progress,
/// and per-category alert cooldowns to avoid spam.
class MacroExecution {
  final Macro macro;
  final int characterIndex;   // 0=Warchief, 1+=ally
  int currentStep = 0;
  double stepTimer = 0.0;
  double gcdTimer = 0.0;      // Tracks GCD between ability casts
  int loopsCompleted = 0;
  bool isPaused = false;
  bool isCancelled = false;

  /// Per-category alert cooldowns: category name → seconds remaining
  final Map<String, double> alertCooldowns = {};

  MacroExecution({
    required this.macro,
    required this.characterIndex,
  });

  /// Get the character's display name for alerts.
  ///
  /// Matches the Character Panel format:
  /// Warchief: 'Warchief · Lv10 Warrior · "The Commander"'
  /// Ally:     'Ally N · LvX Class · "Title"'
  String getCharacterName(GameState gs) {
    if (characterIndex == 0) {
      return 'Warchief · Lv10 Warrior · "The Commander"';
    }
    final allyIndex = characterIndex - 1;
    if (allyIndex < gs.allies.length) {
      final ally = gs.allies[allyIndex];
      final cls = _getAllyClass(ally);
      final title = _getAllyTitle(ally);
      return 'Ally $characterIndex · Lv${5 + characterIndex} $cls · "$title"';
    }
    return 'Unknown';
  }

  static String _getAllyClass(Ally ally) {
    switch (ally.abilityIndex) {
      case 0: return 'Fighter';
      case 1: return 'Mage';
      case 2: return 'Healer';
      default: return 'Fighter';
    }
  }

  static String _getAllyTitle(Ally ally) {
    switch (ally.strategyType) {
      case AllyStrategyType.aggressive: return 'The Berserker';
      case AllyStrategyType.defensive: return 'The Guardian';
      case AllyStrategyType.support: return 'The Protector';
      case AllyStrategyType.balanced: return 'The Companion';
      case AllyStrategyType.berserker: return 'The Reckless';
    }
  }
}

/// Macro execution engine.
///
/// Manages starting, stopping, and updating macro executions.
/// Called each frame from [game3d_widget._update()]. Produces
/// [RaidChatMessage] alerts when conditions are met.
class MacroSystem {
  MacroSystem._();

  static final List<MacroExecution> _activeExecutions = [];

  /// Whether any macros are currently executing.
  static bool get hasActiveExecutions => _activeExecutions.isNotEmpty;

  /// Number of active macro executions.
  static int get activeCount => _activeExecutions.length;

  /// Whether a macro is currently running on a specific character.
  static bool isRunningOnCharacter(int characterIndex) =>
      _activeExecutions.any((e) => e.characterIndex == characterIndex);

  /// Start executing a macro on a character.
  ///
  /// Stops any existing macro on the same character first.
  /// Respects [MacroConfig.maxActiveMacros] limit.
  static void startMacro(Macro macro, int characterIndex, GameState gs) {
    final config = globalMacroConfig;
    final maxActive = config?.maxActiveMacros ?? 5;

    // Stop existing macro on this character
    stopMacro(characterIndex);

    // Check active limit
    if (_activeExecutions.length >= maxActive) {
      _postAlert(
        gs, null, RaidAlertCategory.rotation, RaidAlertType.warning,
        'System', 'Cannot start macro — max active macros reached ($maxActive)',
      );
      return;
    }

    final execution = MacroExecution(
      macro: macro,
      characterIndex: characterIndex,
    );

    _activeExecutions.add(execution);
    _postAlert(
      gs, execution, RaidAlertCategory.rotation, RaidAlertType.info,
      execution.getCharacterName(gs),
      'Started rotation: ${macro.name}',
    );

    print('[MacroSystem] Started macro "${macro.name}" on character $characterIndex');
  }

  /// Stop a macro for a specific character.
  static void stopMacro(int characterIndex) {
    _activeExecutions.removeWhere((e) => e.characterIndex == characterIndex);
  }

  /// Stop all macro executions.
  static void stopAll() {
    _activeExecutions.clear();
  }

  /// Main update loop — called from game3d_widget._update().
  ///
  /// For each active execution:
  /// 1. Decrement GCD timer; if not ready, wait.
  /// 2. Check step delay; if not elapsed, wait.
  /// 3. Check step condition; if fails, alert and wait/skip.
  /// 4. Execute the step (ability, wait, etc.).
  /// 5. Advance to next step; handle looping.
  /// 6. Check alert conditions (low mana, low health).
  static void update(double dt, GameState gs) {
    if (_activeExecutions.isEmpty) return;

    final config = globalMacroConfig;
    final gcdBase = config?.gcdBase ?? 1.5;
    final retryOnCooldown = config?.retryOnCooldown ?? true;
    final skipOnConditionFail = config?.skipOnConditionFail ?? false;

    // Process in reverse so removals are safe
    for (int i = _activeExecutions.length - 1; i >= 0; i--) {
      final execution = _activeExecutions[i];
      if (execution.isCancelled || execution.isPaused) continue;

      // Decrement alert cooldowns
      for (final key in execution.alertCooldowns.keys.toList()) {
        execution.alertCooldowns[key] =
            (execution.alertCooldowns[key]! - dt).clamp(0.0, double.infinity);
      }

      // 1. GCD timer
      if (execution.gcdTimer > 0) {
        execution.gcdTimer -= dt;
        continue;
      }

      // Validate character still exists
      if (execution.characterIndex > 0) {
        final allyIndex = execution.characterIndex - 1;
        if (allyIndex >= gs.allies.length || gs.allies[allyIndex].health <= 0) {
          _postAlert(
            gs, execution, RaidAlertCategory.rotation, RaidAlertType.warning,
            execution.getCharacterName(gs),
            'Rotation stopped — character unavailable',
          );
          _activeExecutions.removeAt(i);
          continue;
        }
      }

      // Get current step
      if (execution.currentStep >= execution.macro.steps.length) {
        // All steps complete
        if (execution.macro.loop) {
          final maxLoops = execution.macro.loopCount;
          if (maxLoops != null && execution.loopsCompleted >= maxLoops) {
            _postAlert(
              gs, execution, RaidAlertCategory.rotation, RaidAlertType.success,
              execution.getCharacterName(gs),
              'Rotation "${execution.macro.name}" completed ($maxLoops loops)',
            );
            _activeExecutions.removeAt(i);
            continue;
          }
          execution.currentStep = 0;
          execution.loopsCompleted++;
        } else {
          _postAlert(
            gs, execution, RaidAlertCategory.rotation, RaidAlertType.success,
            execution.getCharacterName(gs),
            'Rotation "${execution.macro.name}" completed',
          );
          _activeExecutions.removeAt(i);
          continue;
        }
      }

      final step = execution.macro.steps[execution.currentStep];

      // 2. Step delay
      if (step.delay > 0) {
        execution.stepTimer += dt;
        if (execution.stepTimer < step.delay) continue;
        execution.stepTimer = 0.0;
      }

      // 3. Check condition
      if (step.condition != null) {
        if (!_checkCondition(step.condition!, execution.characterIndex, gs)) {
          if (skipOnConditionFail) {
            execution.currentStep++;
            continue;
          }
          // Wait and retry next frame
          continue;
        }
      }

      // 4. Execute the step
      switch (step.actionType) {
        case MacroActionType.ability:
          final success = _executeAbilityForCharacter(
            step.actionName, execution.characterIndex, gs,
          );
          if (success) {
            execution.gcdTimer = gcdBase;
            execution.currentStep++;
          } else if (retryOnCooldown) {
            // Retry next frame
          } else {
            execution.currentStep++;
          }
          break;

        case MacroActionType.wait:
          // Already handled by step delay above; just advance
          execution.currentStep++;
          break;

        case MacroActionType.consumable:
        case MacroActionType.racial:
        case MacroActionType.combined:
          // Future: not yet implemented, skip
          execution.currentStep++;
          break;
      }

      // 6. Check alert conditions (throttled)
      _checkAlertConditions(execution, gs);
    }
  }

  /// Execute an ability by name on a specific character.
  ///
  /// When the target character IS the active character, delegates to
  /// [AbilitySystem.executeSlotAbility] for full animations/projectiles.
  /// Uses the target character's action bar config (not the active one)
  /// to find the correct slot. For non-active allies, executes directly
  /// using the ally's cooldown and mana pool.
  static bool _executeAbilityForCharacter(
    String abilityName, int characterIndex, GameState gs,
  ) {
    // Look up ability data
    final abilityData = AbilityRegistry.findByName(abilityName);
    if (abilityData == null) {
      print('[MacroSystem] Unknown ability: $abilityName');
      return false;
    }

    // Active character: pre-check before calling executeSlotAbility
    if (characterIndex == gs.activeCharacterIndex) {
      // Reason: Use the TARGET character's config, not globalActionBarConfig
      // which returns the active character's config (could differ if switched
      // between macro creation and execution).
      final config = globalActionBarConfigManager?.getConfig(characterIndex);
      if (config == null) return false;

      // Find the slot for this ability
      int? foundSlot;
      for (int slot = 0; slot < 10; slot++) {
        if (config.getSlotAbility(slot).toLowerCase() == abilityName.toLowerCase()) {
          foundSlot = slot;
          break;
        }
      }
      if (foundSlot == null) {
        print('[MacroSystem] Ability "$abilityName" not on action bar');
        return false;
      }

      // Pre-check 1: Cooldown
      final cooldown = AbilitySystem.getCooldownForSlot(foundSlot, gs);
      if (cooldown > 0) return false;

      // Pre-check 2: Already casting or winding up
      if (gs.isCasting || gs.isWindingUp) return false;

      // Pre-check 3: Mana cost
      if (abilityData.requiresMana && abilityData.manaCost > 0) {
        switch (abilityData.manaColor) {
          case ManaColor.blue:
            if (!gs.activeHasBlueMana(abilityData.manaCost)) return false;
            break;
          case ManaColor.red:
            if (!gs.activeHasRedMana(abilityData.manaCost)) return false;
            break;
          case ManaColor.white:
            if (!gs.activeHasWhiteMana(abilityData.manaCost)) return false;
            break;
          default:
            break;
        }
      }

      // All pre-checks passed — execute the ability
      AbilitySystem.executeSlotAbility(foundSlot, gs);
      return true;
    }

    // Non-active ally: direct execution (cooldown + mana only, no animations)
    if (characterIndex > 0) {
      final allyIndex = characterIndex - 1;
      if (allyIndex >= gs.allies.length) return false;

      final ally = gs.allies[allyIndex];
      if (ally.health <= 0) return false;

      // Check cooldown
      if (ally.abilityCooldown > 0) return false;

      // Check mana cost
      if (abilityData.manaCost > 0) {
        switch (abilityData.manaColor) {
          case ManaColor.blue:
            if (ally.blueMana < abilityData.manaCost) return false;
            ally.blueMana -= abilityData.manaCost;
            break;
          case ManaColor.red:
            if (ally.redMana < abilityData.manaCost) return false;
            ally.redMana -= abilityData.manaCost;
            break;
          case ManaColor.white:
            if (ally.whiteMana < abilityData.manaCost) return false;
            ally.whiteMana -= abilityData.manaCost;
            break;
          default:
            break;
        }
      }

      // Set cooldown
      ally.abilityCooldown = abilityData.cooldown;

      print('[MacroSystem] Ally ${allyIndex + 1} casts ${abilityData.name}');
      return true;
    }

    // Non-active Warchief: cannot execute full abilities
    print('[MacroSystem] Cannot execute "$abilityName" — Warchief is not the active character');
    return false;
  }

  /// Check a condition string against the character's current state.
  static bool _checkCondition(
    String condition, int characterIndex, GameState gs,
  ) {
    switch (condition) {
      case 'has_mana':
        return _getCharacterManaPercent(characterIndex, gs) > 0.05;
      case 'target_exists':
        return gs.currentTargetId != null;
      case 'health_above_50':
        return _getCharacterHealthPercent(characterIndex, gs) > 0.5;
      case 'health_below_50':
        return _getCharacterHealthPercent(characterIndex, gs) < 0.5;
      case 'health_below_30':
        return _getCharacterHealthPercent(characterIndex, gs) < 0.3;
      default:
        return true; // Unknown condition = pass
    }
  }

  /// Get a character's health as a percentage (0.0–1.0).
  static double _getCharacterHealthPercent(int charIndex, GameState gs) {
    if (charIndex == 0) {
      return gs.playerMaxHealth > 0
          ? gs.playerHealth / gs.playerMaxHealth
          : 0.0;
    }
    final allyIndex = charIndex - 1;
    if (allyIndex >= gs.allies.length) return 0.0;
    final ally = gs.allies[allyIndex];
    return ally.maxHealth > 0 ? ally.health / ally.maxHealth : 0.0;
  }

  /// Get a character's primary (blue) mana as a percentage (0.0–1.0).
  static double _getCharacterManaPercent(int charIndex, GameState gs) {
    if (charIndex == 0) {
      return gs.maxBlueMana > 0 ? gs.blueMana / gs.maxBlueMana : 0.0;
    }
    final allyIndex = charIndex - 1;
    if (allyIndex >= gs.allies.length) return 0.0;
    final ally = gs.allies[allyIndex];
    return ally.maxBlueMana > 0 ? ally.blueMana / ally.maxBlueMana : 0.0;
  }

  /// Check alert conditions for a character and post throttled alerts.
  static void _checkAlertConditions(MacroExecution execution, GameState gs) {
    final config = globalMacroConfig;
    final lowManaThresh = config?.lowManaThreshold ?? 0.2;
    final lowHealthThresh = config?.lowHealthThreshold ?? 0.3;
    final charName = execution.getCharacterName(gs);

    // Low mana alert
    final manaPercent = _getCharacterManaPercent(
      execution.characterIndex, gs,
    );
    if (manaPercent > 0 && manaPercent < lowManaThresh) {
      _postThrottledAlert(
        gs, execution, 'mana',
        RaidAlertCategory.mana, RaidAlertType.warning,
        charName,
        '$charName is running low on mana (${(manaPercent * 100).toInt()}%)',
      );
    }

    // Low health alert
    final healthPercent = _getCharacterHealthPercent(
      execution.characterIndex, gs,
    );
    if (healthPercent > 0 && healthPercent < lowHealthThresh) {
      _postThrottledAlert(
        gs, execution, 'health',
        RaidAlertCategory.health, RaidAlertType.critical,
        charName,
        '$charName health critical (${(healthPercent * 100).toInt()}%)',
      );
    }
  }

  /// Post a throttled alert (only if cooldown for this category has expired).
  static void _postThrottledAlert(
    GameState gs,
    MacroExecution execution,
    String throttleKey,
    RaidAlertCategory category,
    RaidAlertType type,
    String sender,
    String text,
  ) {
    final cooldown = execution.alertCooldowns[throttleKey] ?? 0.0;
    if (cooldown > 0) return;

    final alertCooldownSeconds =
        globalMacroConfig?.alertCooldownSeconds ?? 5.0;
    execution.alertCooldowns[throttleKey] = alertCooldownSeconds;

    _postAlert(gs, execution, category, type, sender, text);
  }

  /// Post an alert to the game state's raid chat messages.
  static void _postAlert(
    GameState gs,
    MacroExecution? execution,
    RaidAlertCategory category,
    RaidAlertType type,
    String sender,
    String text,
  ) {
    gs.raidChatMessages.add(RaidChatMessage(
      senderName: sender,
      text: text,
      type: type,
      category: category,
    ));

    // Cap message history at 100
    if (gs.raidChatMessages.length > 100) {
      gs.raidChatMessages.removeAt(0);
    }

    print('[RaidChat] [$sender] $text');
  }
}
