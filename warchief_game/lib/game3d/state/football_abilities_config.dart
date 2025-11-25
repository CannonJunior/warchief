import 'package:vector_math/vector_math.dart';

/// Football Abilities Configuration
///
/// Defines the three main player abilities for football:
/// 1. Juke/Spin Move - Evasive maneuver to avoid tackles
/// 2. Pass Ball - Throw the football to a teammate
/// 3. Speed Burst - Temporary speed boost
///
/// Each ability has cooldowns, durations, and gameplay effects.
class FootballAbilitiesConfig {
  FootballAbilitiesConfig._(); // Private constructor to prevent instantiation

  // ==================== ABILITY 1: JUKE/SPIN MOVE ====================

  /// Ability name
  static const String ability1Name = "Juke/Spin";

  /// Ability description
  static const String ability1Description =
      "Evasive maneuver that allows you to slip past defenders. "
      "Defenders within range have a high chance to miss their tackle.";

  /// Cooldown duration (seconds)
  static const double ability1CooldownMax = 2.0;

  /// Ability active duration (seconds)
  static const double ability1Duration = 0.3;

  /// Evasion range (yards) - affects defenders within this radius
  static const double ability1Range = 2.0;

  /// Base evasion success rate (0.0 - 1.0)
  static const double ability1BaseSuccess = 0.85;

  /// Evasion success rate per agility point
  static const double ability1SuccessPerAgility = 0.01;

  /// Movement distance during juke (yards)
  static const double ability1MovementDistance = 2.0;

  /// Visual effect color (cyan/blue)
  static final Vector3 ability1EffectColor = Vector3(0.2, 0.8, 1.0);

  /// Visual effect size
  static const double ability1EffectSize = 1.0;

  /// Visual effect duration (seconds)
  static const double ability1EffectDuration = 0.3;

  /// Stamina cost to use ability
  static const double ability1StaminaCost = 10.0;

  /// Can use while being tackled
  static const bool ability1CanUseWhileTackled = true;

  // ==================== ABILITY 2: PASS BALL ====================

  /// Ability name
  static const String ability2Name = "Pass";

  /// Ability description
  static const String ability2Description =
      "Throw the football to a teammate. Accuracy decreases with distance. "
      "Aim at a receiver and press the key to throw.";

  /// Cooldown duration (seconds)
  static const double ability2CooldownMax = 1.0;

  /// Maximum pass distance (yards)
  static const double ability2MaxRange = 50.0;

  /// Pass speed (yards per second)
  static const double ability2ProjectileSpeed = 20.0;

  /// Pass ball size
  static const double ability2ProjectileSize = 0.3;

  /// Pass ball color (brown leather)
  static final Vector3 ability2ProjectileColor = Vector3(0.6, 0.4, 0.2);

  /// Base pass accuracy at close range (0.0 - 1.0)
  static const double ability2BaseAccuracyClose = 0.95;

  /// Base pass accuracy at max range (0.0 - 1.0)
  static const double ability2BaseAccuracyFar = 0.5;

  /// Pass accuracy increase per throwing skill point
  static const double ability2AccuracyPerThrowing = 0.005;

  /// Arc height multiplier (affects trajectory)
  static const double ability2ArcHeight = 0.3;

  /// Ball spin speed (visual effect)
  static const double ability2SpinSpeed = 720.0; // degrees per second

  /// Pass impact effect color (when caught)
  static final Vector3 ability2ImpactColor = Vector3(0.0, 1.0, 0.0); // Green

  /// Pass impact effect size
  static const double ability2ImpactSize = 0.6;

  /// Incomplete pass impact color (when dropped)
  static final Vector3 ability2IncompleteColor = Vector3(0.8, 0.8, 0.0); // Yellow

  /// Stamina cost to throw
  static const double ability2StaminaCost = 5.0;

  /// Can pass while moving
  static const bool ability2CanUseWhileMoving = true;

  // ==================== ABILITY 3: SPEED BURST ====================

  /// Ability name
  static const String ability3Name = "Speed Burst";

  /// Ability description
  static const String ability3Description =
      "Activate a burst of speed for a short duration. "
      "Greatly increases movement speed but drains stamina quickly.";

  /// Cooldown duration (seconds)
  static const double ability3CooldownMax = 8.0;

  /// Ability active duration (seconds)
  static const double ability3Duration = 3.0;

  /// Speed multiplier during burst
  static const double ability3SpeedMultiplier = 1.5;

  /// Speed multiplier increase per speed stat point
  static const double ability3MultiplierPerSpeed = 0.01;

  /// Stamina cost to activate
  static const double ability3StaminaCost = 30.0;

  /// Additional stamina drain per second while active
  static const double ability3StaminaDrainPerSecond = 10.0;

  /// Visual effect color (yellow/gold)
  static final Vector3 ability3EffectColor = Vector3(1.0, 1.0, 0.0);

  /// Visual effect size
  static const double ability3EffectSize = 1.5;

  /// Trail effect while speed burst is active
  static const bool ability3ShowTrail = true;

  /// Trail color
  static final Vector3 ability3TrailColor = Vector3(1.0, 0.8, 0.0);

  /// Can use while being tackled
  static const bool ability3CanUseWhileTackled = false;

  // ==================== ABILITY UPGRADES ====================

  /// Juke upgrade levels
  static const List<String> ability1Upgrades = [
    "Increased evasion range",
    "Reduced cooldown",
    "Higher success rate",
    "Longer movement distance",
    "Break tackles on contact",
  ];

  /// Pass upgrade levels
  static const List<String> ability2Upgrades = [
    "Increased pass range",
    "Better accuracy",
    "Faster pass speed",
    "Bullet pass (no arc)",
    "Touch pass (high arc)",
  ];

  /// Speed burst upgrade levels
  static const List<String> ability3Upgrades = [
    "Longer duration",
    "Higher speed multiplier",
    "Reduced stamina cost",
    "Faster cooldown recovery",
    "Turbo mode (even faster)",
  ];

  // ==================== ABILITY KEYBINDINGS ====================

  /// Default key for Ability 1 (Juke/Spin)
  static const String ability1DefaultKey = "1";

  /// Default key for Ability 2 (Pass)
  static const String ability2DefaultKey = "2";

  /// Default key for Ability 3 (Speed Burst)
  static const String ability3DefaultKey = "3";

  // ==================== ABILITY COMBO BONUSES ====================

  /// Bonus XP for using juke successfully then scoring
  static const double jukeToTouchdownBonus = 50.0;

  /// Bonus XP for completing a pass then scoring
  static const double passToTouchdownBonus = 75.0;

  /// Bonus XP for using speed burst to outrun all defenders
  static const double speedBurstBreakawayBonus = 100.0;

  // ==================== ABILITY VISUAL SETTINGS ====================

  /// Show ability cooldown timers on HUD
  static const bool showCooldownTimers = true;

  /// Show ability hints for new players
  static const bool showAbilityHints = true;

  /// Ability icon size on HUD
  static const double abilityIconSize = 48.0;

  /// Ability button spacing on HUD
  static const double abilityButtonSpacing = 8.0;
}
