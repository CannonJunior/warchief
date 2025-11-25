import 'package:vector_math/vector_math.dart';

/// Route Types for receivers
enum RouteType {
  go, // Straight upfield
  post, // Diagonal toward center
  corner, // Diagonal toward sideline
  slant, // Quick diagonal inside
  out, // Quick break to sideline
  insideBreak, // Quick break to center (renamed from 'in' due to keyword)
  curl, // Run upfield then turn back
  comeback, // Deep then turn back
  screen, // Short pass behind line
  flat, // Run parallel to line of scrimmage
  block, // Stay and block defenders
}

/// Formation Types
enum FormationType {
  iFormation, // Traditional I-formation (RB behind QB)
  shotgun, // QB in shotgun, RB beside
  spread, // 4-5 wide receivers
  singleBack, // One RB, multiple receivers
  goalLine, // Heavy formation near goal line
}

/// Play Types
enum PlayType {
  run, // Running play
  pass, // Passing play
  playAction, // Fake run, then pass
  screen, // Screen pass
  draw, // Fake pass, then run
}

/// Player Position
enum PlayerPosition {
  quarterback, // QB (ball carrier in this game)
  runningBack, // RB
  wideReceiver, // WR
  tightEnd, // TE
  offensiveLine, // OL (center, guards, tackles)
}

/// Route Definition
class Route {
  final RouteType type;
  final double depth; // Yards upfield
  final double width; // Yards from center (negative = left, positive = right)
  final double duration; // Seconds to complete route

  const Route({
    required this.type,
    required this.depth,
    required this.width,
    this.duration = 2.0,
  });

  /// Get the target position for this route from a starting position
  Vector3 getTargetPosition(Vector3 startPosition) {
    switch (type) {
      case RouteType.go:
        return Vector3(startPosition.x, startPosition.y, startPosition.z + depth);
      case RouteType.post:
        return Vector3(width, startPosition.y, startPosition.z + depth);
      case RouteType.corner:
        return Vector3(startPosition.x + width, startPosition.y, startPosition.z + depth);
      case RouteType.slant:
        return Vector3(startPosition.x + width * 0.5, startPosition.y, startPosition.z + depth * 0.5);
      case RouteType.out:
        return Vector3(startPosition.x + width, startPosition.y, startPosition.z + depth * 0.3);
      case RouteType.insideBreak:
        return Vector3(width, startPosition.y, startPosition.z + depth * 0.3);
      case RouteType.curl:
        return Vector3(startPosition.x, startPosition.y, startPosition.z + depth * 0.8);
      case RouteType.comeback:
        return Vector3(startPosition.x, startPosition.y, startPosition.z + depth * 0.7);
      case RouteType.screen:
        return Vector3(startPosition.x + width, startPosition.y, startPosition.z + depth * 0.2);
      case RouteType.flat:
        return Vector3(startPosition.x + width, startPosition.y, startPosition.z);
      case RouteType.block:
        return startPosition; // Stay in place
    }
  }

  @override
  String toString() => 'Route(type: $type, depth: $depth, width: $width)';
}

/// Player Assignment in a play
class PlayerAssignment {
  final PlayerPosition position;
  final Route route;
  final bool isPrimaryReceiver; // Main target for QB

  const PlayerAssignment({
    required this.position,
    required this.route,
    this.isPrimaryReceiver = false,
  });
}

/// Offensive Play Definition
class OffensivePlay {
  final String name;
  final String description;
  final FormationType formation;
  final PlayType playType;
  final List<PlayerAssignment> assignments;
  final String situation; // e.g., "3rd & Long", "Goal Line", "Any"

  const OffensivePlay({
    required this.name,
    required this.description,
    required this.formation,
    required this.playType,
    required this.assignments,
    this.situation = "Any",
  });

  /// Get primary receiver assignment
  PlayerAssignment? get primaryReceiver {
    try {
      return assignments.firstWhere((a) => a.isPrimaryReceiver);
    } catch (e) {
      return null;
    }
  }

  /// Get all receiver assignments (excluding blockers)
  List<PlayerAssignment> get receivers {
    return assignments.where((a) => a.route.type != RouteType.block).toList();
  }

  @override
  String toString() => 'Play: $name ($playType from $formation)';
}

/// Playbook Configuration
///
/// Contains all offensive plays organized by situation and formation.
class PlaybookConfig {
  PlaybookConfig._(); // Private constructor

  // ==================== FORMATIONS ====================

  /// I-Formation positions (relative to QB at 0,0)
  static final Map<PlayerPosition, Vector3> iFormationPositions = {
    PlayerPosition.offensiveLine: Vector3(0, 0, 0), // Multiple OL around center
    PlayerPosition.runningBack: Vector3(0, 0, -3), // Behind QB
    PlayerPosition.tightEnd: Vector3(6, 0, 0), // On the line
    PlayerPosition.wideReceiver: Vector3(-15, 0, 0), // Split wide
  };

  /// Shotgun formation positions
  static final Map<PlayerPosition, Vector3> shotgunPositions = {
    PlayerPosition.offensiveLine: Vector3(0, 0, 0),
    PlayerPosition.runningBack: Vector3(-3, 0, -5), // Beside QB
    PlayerPosition.tightEnd: Vector3(6, 0, 0),
    PlayerPosition.wideReceiver: Vector3(-12, 0, 0),
  };

  /// Spread formation positions (4-5 wide receivers)
  static final Map<PlayerPosition, Vector3> spreadPositions = {
    PlayerPosition.offensiveLine: Vector3(0, 0, 0),
    PlayerPosition.wideReceiver: Vector3(-20, 0, 0), // Spread out wide
  };

  // ==================== PASSING PLAYS ====================

  /// Hail Mary - Deep pass downfield
  static const OffensivePlay hailMary = OffensivePlay(
    name: "Hail Mary",
    description: "Deep pass to end zone. All receivers run go routes.",
    formation: FormationType.spread,
    playType: PlayType.pass,
    situation: "4th & Long",
    assignments: [
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.go, depth: 50, width: -15),
        isPrimaryReceiver: true,
      ),
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.go, depth: 50, width: 0),
      ),
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.go, depth: 50, width: 15),
      ),
      PlayerAssignment(
        position: PlayerPosition.tightEnd,
        route: Route(type: RouteType.go, depth: 45, width: 8),
      ),
    ],
  );

  /// Quick Slant - Short quick pass
  static const OffensivePlay quickSlant = OffensivePlay(
    name: "Quick Slant",
    description: "Fast slant route for quick completion.",
    formation: FormationType.shotgun,
    playType: PlayType.pass,
    situation: "3rd & Short",
    assignments: [
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.slant, depth: 8, width: 5),
        isPrimaryReceiver: true,
      ),
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.go, depth: 20, width: -15),
      ),
      PlayerAssignment(
        position: PlayerPosition.tightEnd,
        route: Route(type: RouteType.block, depth: 0, width: 0),
      ),
    ],
  );

  /// Post Pattern - Deep middle pass
  static const OffensivePlay postPattern = OffensivePlay(
    name: "Post Pattern",
    description: "Receiver runs post route to middle of field.",
    formation: FormationType.iFormation,
    playType: PlayType.pass,
    situation: "2nd & Long",
    assignments: [
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.post, depth: 25, width: 0),
        isPrimaryReceiver: true,
      ),
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.corner, depth: 20, width: 10),
      ),
      PlayerAssignment(
        position: PlayerPosition.runningBack,
        route: Route(type: RouteType.flat, depth: 5, width: -8),
      ),
    ],
  );

  /// Screen Pass - Short pass with blockers
  static const OffensivePlay screenPass = OffensivePlay(
    name: "Screen Pass",
    description: "Short pass behind blockers for big gain.",
    formation: FormationType.shotgun,
    playType: PlayType.screen,
    situation: "2nd & Long",
    assignments: [
      PlayerAssignment(
        position: PlayerPosition.runningBack,
        route: Route(type: RouteType.screen, depth: 2, width: -5),
        isPrimaryReceiver: true,
      ),
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.block, depth: 3, width: -8),
      ),
    ],
  );

  /// Four Verticals - All receivers go deep
  static const OffensivePlay fourVerticals = OffensivePlay(
    name: "Four Verticals",
    description: "Four receivers run vertical routes.",
    formation: FormationType.spread,
    playType: PlayType.pass,
    situation: "3rd & Long",
    assignments: [
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.go, depth: 30, width: -20),
      ),
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.go, depth: 30, width: -8),
        isPrimaryReceiver: true,
      ),
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.go, depth: 30, width: 8),
      ),
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.go, depth: 30, width: 20),
      ),
    ],
  );

  // ==================== RUNNING PLAYS ====================

  /// Dive - Quick run up the middle
  static const OffensivePlay dive = OffensivePlay(
    name: "Dive",
    description: "Quick run straight ahead through the middle.",
    formation: FormationType.iFormation,
    playType: PlayType.run,
    situation: "3rd & Short",
    assignments: [
      PlayerAssignment(
        position: PlayerPosition.runningBack,
        route: Route(type: RouteType.go, depth: 5, width: 0),
      ),
      PlayerAssignment(
        position: PlayerPosition.offensiveLine,
        route: Route(type: RouteType.block, depth: 0, width: 0),
      ),
    ],
  );

  /// Sweep - Run to the outside
  static const OffensivePlay sweep = OffensivePlay(
    name: "Sweep",
    description: "Run to the outside behind blockers.",
    formation: FormationType.iFormation,
    playType: PlayType.run,
    situation: "1st & 10",
    assignments: [
      PlayerAssignment(
        position: PlayerPosition.runningBack,
        route: Route(type: RouteType.out, depth: 3, width: 10),
      ),
      PlayerAssignment(
        position: PlayerPosition.offensiveLine,
        route: Route(type: RouteType.block, depth: 2, width: 8),
      ),
    ],
  );

  /// Draw Play - Fake pass, then run
  static const OffensivePlay drawPlay = OffensivePlay(
    name: "Draw",
    description: "Fake pass, then hand off for run.",
    formation: FormationType.shotgun,
    playType: PlayType.draw,
    situation: "2nd & Medium",
    assignments: [
      PlayerAssignment(
        position: PlayerPosition.runningBack,
        route: Route(type: RouteType.go, depth: 8, width: 0),
      ),
      PlayerAssignment(
        position: PlayerPosition.wideReceiver,
        route: Route(type: RouteType.go, depth: 15, width: -15),
      ),
    ],
  );

  // ==================== PLAYBOOK COLLECTION ====================

  /// All available plays
  static final List<OffensivePlay> allPlays = [
    hailMary,
    quickSlant,
    postPattern,
    screenPass,
    fourVerticals,
    dive,
    sweep,
    drawPlay,
  ];

  /// Get plays filtered by situation
  static List<OffensivePlay> getPlaysForSituation(String situation) {
    return allPlays.where((play) => play.situation == situation || play.situation == "Any").toList();
  }

  /// Get plays filtered by play type
  static List<OffensivePlay> getPlaysByType(PlayType type) {
    return allPlays.where((play) => play.playType == type).toList();
  }

  /// Get plays filtered by formation
  static List<OffensivePlay> getPlaysByFormation(FormationType formation) {
    return allPlays.where((play) => play.formation == formation).toList();
  }

  /// Get a random play
  static OffensivePlay getRandomPlay() {
    return allPlays[DateTime.now().millisecondsSinceEpoch % allPlays.length];
  }
}
