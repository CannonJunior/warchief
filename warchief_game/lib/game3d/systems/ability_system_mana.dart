part of 'ability_system.dart';

// ==================== DEFERRED MANA STATE ====================

/// Pending secondary mana cost for dual-mana abilities (deferred during cast/windup).
double _pendingSecondaryManaCost = 0.0;

/// Pending secondary mana type index (0=blue, 1=red, 2=white, 3=green).
int _pendingSecondaryManaType = 0;

// ==================== MANA COLOR CONVERSION ====================

_ManaType _manaColorToType(ManaColor color) {
  switch (color) {
    case ManaColor.blue: return _ManaType.blue;
    case ManaColor.red: return _ManaType.red;
    case ManaColor.white: return _ManaType.white;
    case ManaColor.green: return _ManaType.green;
    case ManaColor.black: return _ManaType.black;
    case ManaColor.none: return _ManaType.none;
  }
}

ManaColor _manaTypeToColor(_ManaType type) {
  switch (type) {
    case _ManaType.blue: return ManaColor.blue;
    case _ManaType.red: return ManaColor.red;
    case _ManaType.white: return ManaColor.white;
    case _ManaType.green: return ManaColor.green;
    case _ManaType.black: return ManaColor.black;
    case _ManaType.none: return ManaColor.none;
  }
}

/// Convert _ManaType to index (0=blue, 1=red, 2=white, 3=green, 4=black).
int _manaTypeToIndex(_ManaType type) {
  switch (type) {
    case _ManaType.blue: return 0;
    case _ManaType.red: return 1;
    case _ManaType.white: return 2;
    case _ManaType.green: return 3;
    case _ManaType.black: return 4;
    case _ManaType.none: return 0;
  }
}

// ==================== MANA VALIDATION ====================

/// Check if the active character has enough mana of [type]; logs a warning if not.
bool _activeHasMana(GameState gameState, _ManaType type, double cost, String abilityName) {
  if (cost <= 0) return true;
  switch (type) {
    case _ManaType.blue:
      if (!gameState.activeHasBlueMana(cost)) {
        gameState.addConsoleLog('$abilityName: not enough blue mana (need ${cost.toStringAsFixed(0)}, have ${gameState.activeBlueMana.toStringAsFixed(0)})', level: ConsoleLogLevel.warn);
        return false;
      }
      return true;
    case _ManaType.red:
      if (!gameState.activeHasRedMana(cost)) {
        gameState.addConsoleLog('$abilityName: not enough red mana (need ${cost.toStringAsFixed(0)}, have ${gameState.activeRedMana.toStringAsFixed(0)})', level: ConsoleLogLevel.warn);
        return false;
      }
      return true;
    case _ManaType.white:
      if (!gameState.activeHasWhiteMana(cost)) {
        gameState.addConsoleLog('$abilityName: not enough white mana (need ${cost.toStringAsFixed(0)}, have ${gameState.activeWhiteMana.toStringAsFixed(0)})', level: ConsoleLogLevel.warn);
        return false;
      }
      return true;
    case _ManaType.green:
      if (!gameState.activeHasGreenMana(cost)) {
        gameState.addConsoleLog('$abilityName: not enough green mana (need ${cost.toStringAsFixed(0)}, have ${gameState.activeGreenMana.toStringAsFixed(0)})', level: ConsoleLogLevel.warn);
        return false;
      }
      return true;
    case _ManaType.black:
      if (!gameState.activeHasBlackMana(cost)) {
        gameState.addConsoleLog('$abilityName: not enough black mana (need ${cost.toStringAsFixed(0)}, have ${gameState.activeBlackMana.toStringAsFixed(0)})', level: ConsoleLogLevel.warn);
        return false;
      }
      return true;
    case _ManaType.none:
      return true;
  }
}

// ==================== MANA SPENDING ====================

/// Deduct mana of [type] from the active character.
void _spendManaByType(GameState gameState, _ManaType type, double cost, String abilityName) {
  if (cost <= 0) return;
  switch (type) {
    case _ManaType.blue:
      gameState.activeSpendBlueMana(cost);
      print('[MANA] Spent $cost blue mana for $abilityName');
      break;
    case _ManaType.red:
      gameState.activeSpendRedMana(cost);
      print('[MANA] Spent $cost red mana for $abilityName');
      break;
    case _ManaType.white:
      gameState.activeSpendWhiteMana(cost);
      print('[MANA] Spent $cost white mana for $abilityName');
      break;
    case _ManaType.green:
      gameState.activeSpendGreenMana(cost);
      print('[MANA] Spent $cost green mana for $abilityName');
      break;
    case _ManaType.black:
      gameState.activeSpendBlackMana(cost);
      print('[MANA] Spent $cost black mana for $abilityName');
      break;
    case _ManaType.none:
      break;
  }
}

/// Spend the pending mana stored in [gameState] (deferred from cast/windup start).
void _spendPendingMana(GameState gameState, String abilityName) {
  final cost = gameState.pendingManaCost;
  if (cost > 0) {
    final stance = gameState.activeStance;
    if (stance.usesHpForMana) {
      final hpCost = cost * stance.hpForManaRatio;
      gameState.activeHealth = (gameState.activeHealth - hpCost).clamp(1.0, gameState.activeMaxHealth);
      print('[BLOOD WEAVE] $abilityName spent ${hpCost.toStringAsFixed(1)} HP instead of mana');
      gameState.pendingManaCost = 0.0;
      _pendingSecondaryManaCost = 0.0;
      return;
    }
    // Reason: pendingManaType distinguishes blue(0), red(1), white(2), green(3), black(4)
    switch (gameState.pendingManaType) {
      case 4:
        gameState.activeSpendBlackMana(cost);
        print('[MANA] Spent $cost black mana for $abilityName');
        break;
      case 3:
        gameState.activeSpendGreenMana(cost);
        print('[MANA] Spent $cost green mana for $abilityName');
        break;
      case 2:
        gameState.activeSpendWhiteMana(cost);
        print('[MANA] Spent $cost white mana for $abilityName');
        break;
      case 1:
        gameState.activeSpendRedMana(cost);
        print('[MANA] Spent $cost red mana for $abilityName');
        break;
      default:
        gameState.activeSpendBlueMana(cost);
        print('[MANA] Spent $cost blue mana for $abilityName');
        break;
    }
    gameState.pendingManaCost = 0.0;
  }

  final secondaryCost = _pendingSecondaryManaCost;
  if (secondaryCost > 0) {
    switch (_pendingSecondaryManaType) {
      case 4:
        gameState.activeSpendBlackMana(secondaryCost);
        print('[MANA] Spent $secondaryCost black mana (secondary) for $abilityName');
        break;
      case 3:
        gameState.activeSpendGreenMana(secondaryCost);
        print('[MANA] Spent $secondaryCost green mana (secondary) for $abilityName');
        break;
      case 2:
        gameState.activeSpendWhiteMana(secondaryCost);
        print('[MANA] Spent $secondaryCost white mana (secondary) for $abilityName');
        break;
      case 1:
        gameState.activeSpendRedMana(secondaryCost);
        print('[MANA] Spent $secondaryCost red mana (secondary) for $abilityName');
        break;
      default:
        gameState.activeSpendBlueMana(secondaryCost);
        print('[MANA] Spent $secondaryCost blue mana (secondary) for $abilityName');
        break;
    }
    _pendingSecondaryManaCost = 0.0;
  }
}

// ==================== LEGACY COOLDOWN / COST LOOKUPS ====================

/// Hardcoded cooldown fallback for built-in cast-time/windup abilities.
double _getAbilityCooldown(String abilityName) {
  switch (abilityName) {
    case 'Lightning Bolt': return 5.0;
    case 'Pyroblast': return 12.0;
    case 'Arcane Missile': return 3.5;
    case 'Frost Nova': return 15.0;
    case 'Greater Heal': return 15.0;
    case 'Meteor': return 30.0;
    case 'Heavy Strike': return 4.0;
    case 'Whirlwind': return 8.0;
    case 'Crushing Blow': return 10.0;
    default: return 5.0;
  }
}

/// Hardcoded mana cost + type for built-in abilities (fallback when AbilityData fields absent).
(double, _ManaType) _getManaCostAndType(String abilityName) {
  switch (abilityName) {
    case 'Fireball': return (15.0, _ManaType.blue);
    case 'Ice Shard': return (10.0, _ManaType.blue);
    case 'Frost Bolt': return (12.0, _ManaType.blue);
    case 'Lightning Bolt': return (35.0, _ManaType.blue);
    case 'Pyroblast': return (60.0, _ManaType.blue);
    case 'Arcane Missile': return (25.0, _ManaType.blue);
    case 'Meteor': return (80.0, _ManaType.blue);
    case 'Chain Lightning': return (40.0, _ManaType.blue);
    case 'Blizzard': return (50.0, _ManaType.blue);
    case 'Frost Nova': return (40.0, _ManaType.blue);
    case 'Flame Wave': return (35.0, _ManaType.blue);
    case 'Earthquake': return (45.0, _ManaType.blue);
    case 'Heal': return (20.0, _ManaType.blue);
    case 'Greater Heal': return (45.0, _ManaType.blue);
    case 'Holy Light': return (30.0, _ManaType.blue);
    case 'Rejuvenation': return (25.0, _ManaType.blue);
    case 'Circle of Healing': return (55.0, _ManaType.blue);
    case 'Arcane Strike': return (12.0, _ManaType.blue);
    case 'Frost Strike': return (18.0, _ManaType.blue);
    case 'Life Drain': return (25.0, _ManaType.blue);
    case 'Arcane Shield': return (30.0, _ManaType.blue);
    case 'Blessing of Strength': return (20.0, _ManaType.blue);
    case 'Curse of Weakness': return (20.0, _ManaType.blue);
    case 'Thorns': return (15.0, _ManaType.blue);
    case 'Fear': return (35.0, _ManaType.blue);
    case 'Purify': return (15.0, _ManaType.blue);
    case 'Teleport': return (25.0, _ManaType.blue);
    case 'Shadow Step': return (20.0, _ManaType.blue);
    case 'Soul Rot': return (30.0, _ManaType.blue);
    case 'Summon Skeleton': return (50.0, _ManaType.blue);
    case 'Summon Skeleton Mage': return (60.0, _ManaType.blue);
    case 'Heavy Strike': return (20.0, _ManaType.red);
    case 'Whirlwind': return (30.0, _ManaType.red);
    case 'Crushing Blow': return (45.0, _ManaType.red);
    case 'Sword':
    case 'Dash Attack':
    case 'Shield Bash':
    case 'Charge':
    case 'Backstab':
    case 'Poison Blade':
    case 'Fan of Knives':
    case 'Taunt':
    case 'Fortify':
    case 'Sprint':
    case 'Battle Shout':
    case 'Smoke Bomb':
    case 'Entangling Roots':
    case 'Nature\'s Wrath':
      return (0.0, _ManaType.none);
    default: return (0.0, _ManaType.none);
  }
}

/// Legacy helper — returns blue mana cost only.
double _getManaCost(String abilityName) {
  final (cost, type) = _getManaCostAndType(abilityName);
  return type == _ManaType.blue ? cost : 0.0;
}

/// Legacy helper — returns red mana cost only.
double _getRedManaCost(String abilityName) {
  final (cost, type) = _getManaCostAndType(abilityName);
  return type == _ManaType.red ? cost : 0.0;
}
