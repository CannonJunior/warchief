import 'package:vector_math/vector_math.dart';

/// Football Game Configuration
///
/// Centralized configuration for all football game parameters including
/// field, player, ball carrier, defenders, teammates, and ability settings.
///
/// This replaces the RPG-themed GameConfig with football-specific values.
class FootballGameConfig {
  FootballGameConfig._(); // Private constructor to prevent instantiation

  // ==================== FIELD CONFIGURATION ====================

  /// Field length in yards (100 yards playing field)
  static const double fieldLength = 100.0;

  /// Field width in yards (53.3 yards regulation)
  static const double fieldWidth = 53.3;

  /// End zone depth in yards (10 yards each)
  static const double endZoneDepth = 10.0;

  /// Total field length including end zones (120 yards)
  static const double totalFieldLength = 120.0;

  /// Yards to world units conversion
  static const double yardsToUnits = 1.0;

  // ==================== BALL CARRIER (PLAYER) CONFIGURATION ====================

  /// Ball carrier movement speed (yards per second)
  static const double ballCarrierSpeed = 8.0; // ~8 yards/second = fast running

  /// Ball carrier sprint speed (with speed burst)
  static const double ballCarrierSprintSpeed = 12.0; // ~12 yards/second

  /// Ball carrier rotation speed (degrees per second)
  static const double ballCarrierRotationSpeed = 180.0;

  /// Ball carrier mesh size
  static const double ballCarrierSize = 0.8;

  /// Ball carrier starting position (on own 20-yard line)
  static final Vector3 ballCarrierStartPosition = Vector3(0, 0.5, -30); // 20 yards from goal

  /// Ball carrier starting rotation (degrees) - facing upfield
  static const double ballCarrierStartRotation = 0.0;

  /// Ball carrier direction indicator size
  static const double ballCarrierDirectionIndicatorSize = 0.5;

  // ==================== BALL CARRIER STATS ====================

  /// Ball carrier stamina (replaces health)
  static const double ballCarrierMaxStamina = 100.0;

  /// Stamina drain per second while sprinting
  static const double staminaDrainPerSecond = 10.0;

  /// Stamina recovery per second (when not sprinting)
  static const double staminaRecoveryPerSecond = 15.0;

  // ==================== DEFENSIVE UNIT CONFIGURATION ====================

  /// Number of defenders on the field
  static const int defenderCount = 11;

  /// Defender movement speed (yards per second)
  static const double defenderSpeed = 7.5; // Slightly slower than ball carrier

  /// Defender sprint speed (when pursuing)
  static const double defenderSprintSpeed = 10.0;

  /// Defender mesh size
  static const double defenderSize = 0.8;

  /// Defender starting formation positions (defensive line, linebackers, DBs)
  static final List<Vector3> defenderStartPositions = [
    // Defensive Line (4 players)
    Vector3(-3, 0.5, -25),
    Vector3(-1, 0.5, -25),
    Vector3(1, 0.5, -25),
    Vector3(3, 0.5, -25),
    // Linebackers (3 players)
    Vector3(-4, 0.5, -20),
    Vector3(0, 0.5, -20),
    Vector3(4, 0.5, -20),
    // Defensive Backs (4 players)
    Vector3(-8, 0.5, -15),
    Vector3(-3, 0.5, -15),
    Vector3(3, 0.5, -15),
    Vector3(8, 0.5, -15),
  ];

  /// Defender AI decision interval (seconds)
  static const double defenderAiInterval = 0.5; // More responsive than monster

  /// Tackle range (yards)
  static const double tackleRange = 1.5;

  /// Tackle success base probability
  static const double tackleSuccessBase = 0.7;

  // ==================== OFFENSIVE TEAMMATES CONFIGURATION ====================

  /// Number of offensive teammates (receivers + blockers)
  static const int teammateCount = 10; // Full 11-on-11 minus the ball carrier

  /// Teammate movement speed (yards per second)
  static const double teammateSpeed = 7.0;

  /// Teammate sprint speed (when running routes)
  static const double teammateSprintSpeed = 10.0;

  /// Teammate mesh size
  static const double teammateSize = 0.75;

  /// Teammate AI decision interval (seconds)
  static const double teammateAiInterval = 0.3;

  /// Teammate starting formation (I-formation default)
  static final List<Vector3> teammateStartPositions = [
    // Offensive Line (5 players)
    Vector3(-4, 0.5, -30),
    Vector3(-2, 0.5, -30),
    Vector3(0, 0.5, -30), // Center
    Vector3(2, 0.5, -30),
    Vector3(4, 0.5, -30),
    // Running Back
    Vector3(0, 0.5, -33),
    // Tight End
    Vector3(6, 0.5, -30),
    // Wide Receivers (3 players)
    Vector3(-15, 0.5, -30),
    Vector3(-10, 0.5, -30),
    Vector3(15, 0.5, -30),
  ];

  // ==================== BALL CONFIGURATION ====================

  /// Football size
  static const double footballSize = 0.3;

  /// Football pass speed (yards per second)
  static const double footballPassSpeed = 20.0;

  /// Football arc height multiplier for passes
  static const double footballArcHeight = 0.3;

  /// Catching range (yards)
  static const double catchingRange = 1.5;

  /// Catch success base probability
  static const double catchSuccessBase = 0.8;

  /// Interception range (yards)
  static const double interceptionRange = 2.0;

  /// Interception success base probability
  static const double interceptionSuccessBase = 0.3;

  // ==================== ABILITY 1: JUKE/SPIN MOVE ====================

  /// Juke/Spin cooldown (seconds)
  static const double jukeCooldownMax = 2.0;

  /// Juke duration (seconds)
  static const double jukeDuration = 0.3;

  /// Juke evasion range (yards) - defenders within this range are evaded
  static const double jukeEvasionRange = 2.0;

  /// Juke evasion success probability
  static const double jukeEvasionSuccess = 0.85;

  /// Juke movement distance (yards)
  static const double jukeMovementDistance = 2.0;

  /// Juke visual effect color
  static final Vector3 jukeEffectColor = Vector3(0.2, 0.8, 1.0); // Cyan

  /// Juke visual effect size
  static const double jukeEffectSize = 1.0;

  // ==================== ABILITY 2: PASS BALL ====================

  /// Pass cooldown (seconds)
  static const double passCooldownMax = 1.0; // Can pass frequently

  /// Pass maximum range (yards)
  static const double passMaxRange = 50.0;

  /// Pass accuracy at max range (0.0 - 1.0)
  static const double passAccuracyAtMaxRange = 0.5;

  /// Pass accuracy at close range (0.0 - 1.0)
  static const double passAccuracyAtCloseRange = 0.95;

  /// Pass ball color
  static final Vector3 passBallColor = Vector3(0.6, 0.4, 0.2); // Brown

  // ==================== ABILITY 3: SPEED BURST ====================

  /// Speed burst cooldown (seconds)
  static const double speedBurstCooldownMax = 8.0;

  /// Speed burst duration (seconds)
  static const double speedBurstDuration = 3.0;

  /// Speed burst multiplier (2x normal speed)
  static const double speedBurstMultiplier = 1.5;

  /// Speed burst stamina cost
  static const double speedBurstStaminaCost = 30.0;

  /// Speed burst visual effect color
  static final Vector3 speedBurstEffectColor = Vector3(1.0, 1.0, 0.0); // Yellow

  /// Speed burst visual effect size
  static const double speedBurstEffectSize = 1.5;

  // ==================== TACKLE SYSTEM (replaces combat) ====================

  /// Tackle impact effect size
  static const double tackleImpactSize = 0.8;

  /// Tackle impact effect duration (seconds)
  static const double tackleImpactDuration = 0.4;

  /// Tackle impact effect color
  static final Vector3 tackleImpactColor = Vector3(1.0, 0.2, 0.0); // Red-orange

  /// Fumble chance on tackle (0.0 - 1.0)
  static const double fumbleChanceOnTackle = 0.05; // 5% chance

  /// Fumble chance on hard hit (0.0 - 1.0)
  static const double fumbleChanceOnHardHit = 0.15; // 15% chance

  // ==================== PHYSICS CONFIGURATION ====================

  /// Gravity strength (affects jump/fall physics)
  static const double gravity = 20.0;

  /// Jump velocity (units per second)
  static const double jumpVelocity = 8.0; // Lower jump for football

  /// Ground level (Y coordinate)
  static const double groundLevel = 0.5;

  // ==================== GAME PROGRESSION ====================

  /// XP per yard gained
  static const double xpPerYard = 10.0;

  /// XP per touchdown
  static const double xpPerTouchdown = 100.0;

  /// XP per completed pass
  static const double xpPerCompletedPass = 20.0;

  /// XP per broken tackle
  static const double xpPerBrokenTackle = 15.0;

  /// XP needed for level up (base)
  static const double xpPerLevel = 500.0;

  // ==================== PLAYER STATS ====================

  /// Player stat: Speed (affects movement speed)
  static const double statSpeedBase = 5.0;
  static const double statSpeedPerLevel = 0.2;

  /// Player stat: Strength (affects tackle breaking)
  static const double statStrengthBase = 5.0;
  static const double statStrengthPerLevel = 0.2;

  /// Player stat: Agility (affects juke success)
  static const double statAgilityBase = 5.0;
  static const double statAgilityPerLevel = 0.2;

  /// Player stat: Catching (affects catch success)
  static const double statCatchingBase = 5.0;
  static const double statCatchingPerLevel = 0.2;

  /// Player stat: Throwing (affects pass accuracy)
  static const double statThrowingBase = 5.0;
  static const double statThrowingPerLevel = 0.2;

  // ==================== DOWN & DISTANCE ====================

  /// Yards needed for first down
  static const double yardsForFirstDown = 10.0;

  /// Number of downs per possession
  static const int downsPerPossession = 4;

  /// Starting down
  static const int startingDown = 1;

  // ==================== VISUAL EFFECTS ====================

  /// Trail effect for ball in flight
  static const bool enableBallTrail = true;

  /// Ball trail color
  static final Vector3 ballTrailColor = Vector3(0.8, 0.6, 0.4);

  /// Ball trail segment count
  static const int ballTrailSegments = 10;

  // ==================== AI DIFFICULTY ====================

  /// AI difficulty level (1-10)
  static const int aiDifficulty = 5;

  /// AI reaction time (seconds) - lower is harder
  static const double aiReactionTime = 0.3;

  /// AI prediction accuracy (0.0 - 1.0)
  static const double aiPredictionAccuracy = 0.6;
}
