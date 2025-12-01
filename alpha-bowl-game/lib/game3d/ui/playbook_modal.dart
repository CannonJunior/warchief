import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Player Position Data
class PlayerPosition {
  String name;
  String abbreviation;
  Vector2 position;
  String? assignedAction;
  bool actionFlipped; // Whether the action is horizontally flipped

  PlayerPosition({
    required this.name,
    required this.abbreviation,
    required this.position,
    this.assignedAction,
    this.actionFlipped = false,
  });

  /// Create a copy of this player position
  PlayerPosition copy() {
    return PlayerPosition(
      name: name,
      abbreviation: abbreviation,
      position: Vector2(position.x, position.y),
      assignedAction: assignedAction,
      actionFlipped: actionFlipped,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'position': {'x': position.x, 'y': position.y},
      'assignedAction': assignedAction,
      'actionFlipped': actionFlipped,
    };
  }

  /// Create from JSON
  factory PlayerPosition.fromJson(Map<String, dynamic> json) {
    return PlayerPosition(
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
      position: Vector2(
        (json['position']['x'] as num).toDouble(),
        (json['position']['y'] as num).toDouble(),
      ),
      assignedAction: json['assignedAction'] as String?,
      actionFlipped: json['actionFlipped'] as bool? ?? false,
    );
  }
}

/// Play Data - represents a specific play configuration
class Play {
  String name;
  List<PlayerPosition> players;

  Play({
    required this.name,
    required this.players,
  });

  /// Create a copy of this play
  Play copy() {
    return Play(
      name: name,
      players: players.map((p) => p.copy()).toList(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'players': players.map((p) => p.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory Play.fromJson(Map<String, dynamic> json) {
    return Play(
      name: json['name'] as String,
      players: (json['players'] as List)
          .map((p) => PlayerPosition.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Formation Data - represents a formation with multiple plays
class Formation {
  String name;
  List<PlayerPosition> defaultPlayers;
  List<Play> plays;

  Formation({
    required this.name,
    required this.defaultPlayers,
    List<Play>? plays,
  }) : plays = plays ?? [];

  /// Create a copy of this formation
  Formation copy() {
    return Formation(
      name: name,
      defaultPlayers: defaultPlayers.map((p) => p.copy()).toList(),
      plays: plays.map((p) => p.copy()).toList(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'defaultPlayers': defaultPlayers.map((p) => p.toJson()).toList(),
      'plays': plays.map((p) => p.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory Formation.fromJson(Map<String, dynamic> json) {
    return Formation(
      name: json['name'] as String,
      defaultPlayers: (json['defaultPlayers'] as List)
          .map((p) => PlayerPosition.fromJson(p as Map<String, dynamic>))
          .toList(),
      plays: (json['plays'] as List)
          .map((p) => Play.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Action Path Segment Types
enum ActionSegmentType {
  line,      // Straight line
  arrow,     // Line ending with arrow
  block,     // Line ending with perpendicular line
}

/// Action Path Segment
class ActionPathSegment {
  final Vector2 start;
  final Vector2 end;
  final ActionSegmentType type;

  ActionPathSegment({
    required this.start,
    required this.end,
    required this.type,
  });
}

/// Action Visual Definition
class ActionVisualDefinition {
  final List<ActionPathSegment> segments;
  final bool isRoute; // true for routes, false for blocks

  ActionVisualDefinition({
    required this.segments,
    required this.isRoute,
  });

  /// Helper to create route paths (normalized coordinates)
  static ActionVisualDefinition createRoute(List<Vector2> points) {
    final segments = <ActionPathSegment>[];
    for (int i = 0; i < points.length - 1; i++) {
      segments.add(ActionPathSegment(
        start: points[i],
        end: points[i + 1],
        type: i == points.length - 2 ? ActionSegmentType.arrow : ActionSegmentType.line,
      ));
    }
    return ActionVisualDefinition(segments: segments, isRoute: true);
  }

  /// Helper to create block paths (normalized coordinates)
  static ActionVisualDefinition createBlock(List<Vector2> points) {
    final segments = <ActionPathSegment>[];
    for (int i = 0; i < points.length - 1; i++) {
      segments.add(ActionPathSegment(
        start: points[i],
        end: points[i + 1],
        type: i == points.length - 2 ? ActionSegmentType.block : ActionSegmentType.line,
      ));
    }
    return ActionVisualDefinition(segments: segments, isRoute: false);
  }
}

/// Action visual definitions map - defines the path for each action
/// Coordinates are relative: (0, 0) is player position, y increases downfield, x increases right
/// Scale: 1 unit = ~30 pixels on field
final Map<String, ActionVisualDefinition> actionVisuals = {
  // SHORT ROUTES
  'Flat': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -0.5), Vector2(-2, -0.5), // Forward then toward sideline
  ]),
  'Slant': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(1, -2), // Diagonal inward at 45°
  ]),
  'Hitch': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -1.5), Vector2(0, -1), // Forward then back
  ]),
  'Drag': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -1), Vector2(2, -1), // Forward then horizontal across
  ]),

  // INTERMEDIATE ROUTES
  'Curl': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -3), Vector2(0, -2.5), // Forward then curl back
  ]),
  'Out': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -2.5), Vector2(-2, -2.5), // Forward then 90° to sideline
  ]),
  'Dig': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -2.5), Vector2(2, -2.5), // Forward then 90° to middle
  ]),
  'Comeback': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -3), Vector2(-0.5, -2.5), // Forward then back to sideline
  ]),

  // DEEP ROUTES
  'Go / Fly': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -5), // Straight deep
  ]),
  'Post': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -3), Vector2(1.5, -5), // Forward then angle to goalposts
  ]),
  'Corner': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -3), Vector2(-1.5, -5), // Forward then angle to corner
  ]),
  'Fade': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(-1, -4), // Slight angle to sideline
  ]),

  // CONCEPT ROUTES
  'Wheel': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(-1.5, -0.5), Vector2(-1.5, -3.5), // Horizontal then vertical
  ]),
  'Seam': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -4.5), // Straight up the seam
  ]),

  // MULTIPLE MOVE ROUTES
  'Double Move': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -2), Vector2(-0.5, -2.5), Vector2(0, -4.5), // Fake cut then deep
  ]),
  'Out and Up': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -2), Vector2(-1.5, -2), Vector2(-1.5, -4), // Out then up
  ]),

  // POWER RUNS
  'Dive': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -2), // Quick hit straight up middle
  ]),
  'Power': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0.5, -0.5), Vector2(0.8, -2), // Slight angle with power
  ]),
  'Blast': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0.7, -1.8), // Strong angle to gap
  ]),

  // OUTSIDE RUNS
  'Sweep': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(-1.5, -0.3), Vector2(-2.5, -1.5), // Wide to sideline
  ]),
  'Pitch': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(-2, -0.5), Vector2(-2.5, -2), // Lateral then upfield
  ]),

  // MISDIRECTION
  'Counter': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(-0.8, -0.3), Vector2(1.2, -1.5), // Fake left, cut right
  ]),
  'Reverse': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(-2, -0.2), Vector2(2, -1), // Lateral across, reverse back
  ]),

  // ZONE/READ RUNS
  'Zone': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0.3, -0.5), Vector2(0.6, -2), // Read zone, pick lane
  ]),
  'Trap': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0.8, -0.5), Vector2(1, -1.8), // Through trap block gap
  ]),

  // QUARTERBACK RUNS
  'Quarterback Draw': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, 0.5), Vector2(0, -1.5), // Drop back then run middle
  ]),
  'Quarterback Sneak': ActionVisualDefinition.createRoute([
    Vector2(0, 0), Vector2(0, -1), // Straight ahead short
  ]),

  // RUN BLOCKS
  'Drive Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0, -1.5), // Straight forward
  ]),
  'Down Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0.7, -1), // Diagonal inside
  ]),
  'Reach Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(-1, -0.8), // Wide step outside
  ]),
  'Double-Team Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0, -1.2), // Forward (special - two players)
  ]),
  'Trap Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(1.5, -0.5), // Pull direction
  ]),
  'Cut Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0.5, -0.8), // Low angle
  ]),
  'Fold Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0.8, -0.5), Vector2(1.2, -1.2), // Step around
  ]),
  'Seal Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(-0.8, -1), // Angle to seal
  ]),
  'Scoop Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0.6, -1.5), // Angle to linebacker
  ]),
  'Wedge Block': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0, -1.3), // Forward in formation
  ]),

  // PASS BLOCKS
  'Man Protection': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0, 0.8), // Set back
  ]),
  'Slide Protection': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(-0.7, 0.5), // Angle to slide
  ]),
  'Zone Protection': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0, 0.7), // Set in zone
  ]),
  'Kick Slide': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(-0.8, 0.6), // Backward angle
  ]),
  'Full Slide': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(-1, 0.5), // Full slide direction
  ]),

  // COMBINATION BLOCKS
  'Zone Blocking': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0.5, -1), // Angle to zone
  ]),
  'Gap Schemes': ActionVisualDefinition.createBlock([
    Vector2(0, 0), Vector2(0.7, -0.8), // Angle to gap
  ]),
};

/// Playbook Modal - Formation editor with draggable player positions
///
/// Opened with the 'O' key, this panel shows:
/// - Sidebar with list of 11 player positions
/// - Main panel with 11 draggable circles representing player positions on the field
class PlaybookModal extends StatefulWidget {
  final VoidCallback onClose;
  final Function(List<PlayerPosition>, String?)? onPractice;

  const PlaybookModal({
    Key? key,
    required this.onClose,
    this.onPractice,
  }) : super(key: key);

  @override
  State<PlaybookModal> createState() => _PlaybookModalState();
}

class _PlaybookModalState extends State<PlaybookModal> {
  double _xPos = 100.0;
  double _yPos = 100.0;

  // Sidebar mode toggle
  bool _isFormationMode = false;  // false = Roster, true = Formation

  // Available position types for substitution
  final Map<String, String> availablePositions = {
    'QB': 'Quarterback',
    'RB': 'Running Back',
    'FB': 'Fullback',
    'LT': 'Left Tackle',
    'LG': 'Left Guard',
    'C': 'Center',
    'RG': 'Right Guard',
    'RT': 'Right Tackle',
    'TE': 'Tight End',
    'WR1': 'Wide Receiver 1',
    'WR2': 'Wide Receiver 2',
  };

  // Default positions for 11-man football offense (I-Formation)
  // Field represents 30 yards: 10 behind line of scrimmage (bottom), 20 downfield (top)
  // Line of scrimmage is at 2/3 from top (266.67px from top in 400px height)
  // Bottom = backfield, Top = downfield
  // All players positioned clearly behind LOS with entire circle in backfield
  List<PlayerPosition> _getDefaultPlayers() {
    final los = 266.67; // Line of scrimmage at 2/3 down the field
    final yardInPixels = 13.33; // 1 yard = 400px / 30 yards
    final circleRadius = 12.5; // Half of 25px circle diameter
    final minBackOffset = circleRadius + 5; // Ensure entire circle is behind LOS with buffer

    return [
      // QB: 5 yards behind line of scrimmage (in backfield)
      PlayerPosition(name: 'Quarterback', abbreviation: 'QB', position: Vector2(350, los + (5 * yardInPixels))),
      // RB: 7 yards behind line of scrimmage (deep backfield)
      PlayerPosition(name: 'Running Back', abbreviation: 'RB', position: Vector2(350, los + (7 * yardInPixels))),
      // FB: 6 yards behind line of scrimmage (backfield)
      PlayerPosition(name: 'Fullback', abbreviation: 'FB', position: Vector2(350, los + (6 * yardInPixels))),
      // Offensive line: Just behind the line of scrimmage (entire circle in backfield)
      PlayerPosition(name: 'Left Tackle', abbreviation: 'LT', position: Vector2(250, los + minBackOffset)),
      PlayerPosition(name: 'Left Guard', abbreviation: 'LG', position: Vector2(300, los + minBackOffset)),
      PlayerPosition(name: 'Center', abbreviation: 'C', position: Vector2(350, los + minBackOffset)),
      PlayerPosition(name: 'Right Guard', abbreviation: 'RG', position: Vector2(400, los + minBackOffset)),
      PlayerPosition(name: 'Right Tackle', abbreviation: 'RT', position: Vector2(450, los + minBackOffset)),
      // TE: Just behind the line of scrimmage, outside RT
      PlayerPosition(name: 'Tight End', abbreviation: 'TE', position: Vector2(500, los + minBackOffset)),
      // WRs: Just behind the line of scrimmage, split wide
      PlayerPosition(name: 'Wide Receiver 1', abbreviation: 'WR1', position: Vector2(100, los + minBackOffset)),
      PlayerPosition(name: 'Wide Receiver 2', abbreviation: 'WR2', position: Vector2(600, los + minBackOffset)),
    ];
  }

  // Current players being edited
  late List<PlayerPosition> players;

  // Formations database
  late List<Formation> formations;
  int? selectedFormationIndex;
  int? selectedPlayIndex;

  // Edit/Lock toggle for formation editing
  bool _isEditMode = true;  // true = Edit (draggable), false = Lock (not draggable)

  int? selectedPlayerIndex;

  @override
  void initState() {
    super.initState();
    // Initialize with default formation
    players = _getDefaultPlayers();
    formations = [
      Formation(
        name: 'Default',
        defaultPlayers: _getDefaultPlayers(),
      ),
    ];
    selectedFormationIndex = 0;
    _loadFormations();
  }

  /// Save formations to persistent storage
  Future<void> _saveFormations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formationsJson = formations.map((f) => f.toJson()).toList();
      await prefs.setString('playbook_formations', jsonEncode(formationsJson));
    } catch (e) {
      print('Error saving formations: $e');
    }
  }

  /// Load formations from persistent storage
  Future<void> _loadFormations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formationsString = prefs.getString('playbook_formations');
      if (formationsString != null) {
        final List<dynamic> formationsJson = jsonDecode(formationsString);
        setState(() {
          formations = formationsJson
              .map((f) => Formation.fromJson(f as Map<String, dynamic>))
              .toList();

          // Update the Default formation to use current correct positions
          final defaultFormationIndex = formations.indexWhere((f) => f.name == 'Default');
          if (defaultFormationIndex != -1) {
            formations[defaultFormationIndex].defaultPlayers = _getDefaultPlayers();
          }

          if (formations.isNotEmpty) {
            selectedFormationIndex = 0;
            players = formations[0].defaultPlayers.map((p) => p.copy()).toList();
          }
        });
        // Save the updated formations with corrected Default
        _saveFormations();
      }
    } catch (e) {
      print('Error loading formations: $e');
    }
  }

  // Available actions for players - organized by main category and subcategory
  final Map<String, Map<String, List<String>>> availableActionsByCategory = {
    'Routes': {
      'Short Routes': [
        'Flat',
        'Slant',
        'Hitch',
        'Drag',
      ],
      'Intermediate Routes': [
        'Curl',
        'Out',
        'Dig',
        'Comeback',
      ],
      'Deep Routes': [
        'Go / Fly',
        'Post',
        'Corner',
        'Fade',
      ],
      'Concept Routes': [
        'Wheel',
        'Seam',
      ],
      'Multiple Move Routes': [
        'Double Move',
        'Out and Up',
      ],
    },
    'Runs': {
      'Power Runs': [
        'Dive',
        'Power',
        'Blast',
      ],
      'Outside Runs': [
        'Sweep',
        'Pitch',
      ],
      'Misdirection': [
        'Counter',
        'Reverse',
      ],
      'Zone/Read': [
        'Zone',
        'Trap',
      ],
      'Quarterback Runs': [
        'Quarterback Draw',
        'Quarterback Sneak',
      ],
    },
    'Blocks': {
      'Run Blocks': [
        'Drive Block',
        'Down Block',
        'Reach Block',
        'Double-Team Block',
        'Trap Block',
        'Cut Block',
        'Fold Block',
        'Seal Block',
        'Scoop Block',
        'Wedge Block',
      ],
      'Pass Blocks': [
        'Man Protection',
        'Slide Protection',
        'Zone Protection',
        'Kick Slide',
        'Full Slide',
      ],
      'Combination Blocks': [
        'Zone Blocking',
        'Gap Schemes',
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPos += details.delta.dx;
            _yPos += details.delta.dy;
            // Clamp position to screen bounds
            _xPos = _xPos.clamp(0.0, MediaQuery.of(context).size.width - 900);
            _yPos = _yPos.clamp(0.0, MediaQuery.of(context).size.height - 600);
          });
        },
        child: Container(
          width: 900,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header (draggable area)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.drag_indicator, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'PLAYBOOK',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Press O to close',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content - Sidebar and Field
              Expanded(
                child: Row(
                  children: [
                    // Sidebar - Player List
                    Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        border: Border(
                          right: BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Sidebar Header - Toggle between ROSTER and FORMATION
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isFormationMode = !_isFormationMode;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                border: Border(
                                  bottom: BorderSide(color: Colors.green, width: 1),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isFormationMode ? 'FORMATION' : 'ROSTER',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    _isFormationMode ? Icons.people : Icons.person,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Conditional Content: Player List or Formation List
                          Expanded(
                            child: _isFormationMode
                                ? _buildFormationList()
                                : _buildPlayerList(),
                          ),
                        ],
                      ),
                    ),

                    // Main Panel - Field with Draggable Circles (EXPANDED TO FILL)
                    Expanded(
                      child: Column(
                        children: [
                          // Play Thumbnails Carousel (only show if formation selected and has plays)
                          if (selectedFormationIndex != null &&
                              formations[selectedFormationIndex!].plays.isNotEmpty)
                            _buildPlayThumbnailsCarousel(),

                          // Field Area (takes remaining space)
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final fieldWidth = constraints.maxWidth;
                                final fieldHeight = constraints.maxHeight;

                                return Container(
                                  width: fieldWidth,
                                  height: fieldHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade800.withOpacity(0.3),
                                  ),
                                  child: Builder(
                                    builder: (fieldContext) {
                                      return Stack(
                                        children: [
                                          // Field Background with yard lines
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.white38, width: 2),
                                              ),
                                              child: Stack(
                                                children: [
                                                  // Yard lines - Field shows 30 yards (10 behind, 20 ahead of LOS)
                                                  // Bottom = backfield (-10 to 0), Top = downfield (0 to +20)
                                                  // Draw yard lines every 5 yards
                                                  ...List.generate(7, (index) {
                                                    final yardage = 20 - (index * 5); // 20, 15, 10, 5, 0, -5, -10
                                                    // Convert to position (0 = top = +20, 1 = bottom = -10)
                                                    final position = (20 - yardage) / 30; // 0 to 1 range
                                                    final isLOS = yardage == 0;

                                                    return Positioned(
                                                      left: 0,
                                                      right: 0,
                                                      top: position * fieldHeight,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            height: isLOS ? 3 : 1,
                                                            width: 30,
                                                            color: isLOS
                                                                ? Colors.yellow.withOpacity(0.8)
                                                                : Colors.white.withOpacity(0.3),
                                                          ),
                                                          SizedBox(width: 5),
                                                          if (!isLOS)
                                                            Text(
                                                              '${yardage > 0 ? '+' : ''}$yardage',
                                                              style: TextStyle(
                                                                color: Colors.white.withOpacity(0.4),
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          if (isLOS)
                                                            Text(
                                                              'LOS',
                                                              style: TextStyle(
                                                                color: Colors.yellow.withOpacity(0.8),
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                                  // Full width line of scrimmage
                                                  Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    top: fieldHeight * 0.6667, // 20/30 = 2/3
                                                    child: Container(
                                                      height: 3,
                                                      color: Colors.yellow.withOpacity(0.6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Action Path Visualizations (with double-click to flip)
                                          Positioned.fill(
                                            child: GestureDetector(
                                              onDoubleTapDown: (details) {
                                                // Double-click on action path to flip it
                                                _handleActionPathDoubleTap(details.localPosition);
                                              },
                                              child: CustomPaint(
                                                painter: ActionPathPainter(
                                                  players: players,
                                                  actionVisuals: actionVisuals,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Draggable Player Circles (Edit mode) or Static with Right-Click (Lock mode)
                                          ...players.asMap().entries.map((entry) {
                                            final index = entry.key;
                                            final player = entry.value;

                                            return Positioned(
                                              left: player.position.x - 12.5,
                                              top: player.position.y - 12.5,
                                              child: GestureDetector(
                                                onSecondaryTapDown: (details) {
                                                  // Right-click to show context menu (works in both modes)
                                                  _showContextMenu(context, details.globalPosition, index);
                                                },
                                                onDoubleTap: () {
                                                  // Double-click to flip action horizontally
                                                  if (player.assignedAction != null) {
                                                    setState(() {
                                                      player.actionFlipped = !player.actionFlipped;
                                                      // Update the appropriate data structure
                                                      if (selectedFormationIndex != null) {
                                                        if (selectedPlayIndex != null) {
                                                          formations[selectedFormationIndex!].plays[selectedPlayIndex!].players =
                                                              players.map((p) => p.copy()).toList();
                                                        } else {
                                                          formations[selectedFormationIndex!].defaultPlayers =
                                                              players.map((p) => p.copy()).toList();
                                                        }
                                                      }
                                                    });
                                                    _saveFormations();
                                                  }
                                                },
                                                child: _isEditMode
                                                    ? Draggable<int>(
                                                        data: index,
                                                        feedback: _buildPlayerCircle(player, true, false),
                                                        childWhenDragging: Opacity(
                                                          opacity: 0.3,
                                                          child: _buildPlayerCircle(player, false, false),
                                                        ),
                                                        onDragEnd: (details) {
                                                          setState(() {
                                                            // Get the RenderBox of the field container
                                                            final RenderBox fieldBox = fieldContext.findRenderObject() as RenderBox;
                                                            final fieldOffset = fieldBox.localToGlobal(Offset.zero);

                                                            // Calculate position relative to field (center of circle)
                                                            // details.offset is the top-left corner of the feedback widget
                                                            // Add 12.5 to get the center since the circle is 25x25
                                                            final newX = (details.offset.dx + 12.5 - fieldOffset.dx).clamp(12.5, fieldWidth - 12.5);
                                                            final newY = (details.offset.dy + 12.5 - fieldOffset.dy).clamp(12.5, fieldHeight - 12.5);

                                                            player.position = Vector2(newX, newY);

                                                            // Update the appropriate data structure
                                                            if (selectedFormationIndex != null) {
                                                              if (selectedPlayIndex != null) {
                                                                // Update the selected play's players
                                                                formations[selectedFormationIndex!].plays[selectedPlayIndex!].players =
                                                                    players.map((p) => p.copy()).toList();
                                                              } else {
                                                                // Update formation's default players
                                                                formations[selectedFormationIndex!].defaultPlayers =
                                                                    players.map((p) => p.copy()).toList();
                                                              }
                                                            }
                                                          });
                                                          _saveFormations();
                                                        },
                                                        child: _buildPlayerCircle(player, false, selectedPlayerIndex == index),
                                                      )
                                                    : _buildPlayerCircle(player, false, selectedPlayerIndex == index),
                                              ),
                                            );
                                          }).toList(),

                                          // Edit/Lock Sliding Toggle (top-right)
                                          if (selectedFormationIndex != null && _isFormationMode)
                                            Positioned(
                                              top: 16,
                                              right: 16,
                                              child: _buildSlidingToggle(),
                                            ),

                                          // Practice Button (bottom-right, second from right)
                                          if (selectedFormationIndex != null)
                                            Positioned(
                                              bottom: 16,
                                              right: 146,
                                              child: ElevatedButton.icon(
                                                onPressed: _handlePractice,
                                                icon: Icon(Icons.sports_football, size: 16),
                                                label: Text('Practice'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green.shade700,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  elevation: 4,
                                                ),
                                              ),
                                            ),

                                          // Save Play Button (bottom-right)
                                          if (selectedFormationIndex != null)
                                            Positioned(
                                              bottom: 16,
                                              right: 16,
                                              child: ElevatedButton.icon(
                                                onPressed: _showSavePlayDialog,
                                                icon: Icon(Icons.save, size: 16),
                                                label: Text('Save Play'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue.shade700,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  elevation: 4,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  /// Handle double-tap on action path lines to flip the action
  void _handleActionPathDoubleTap(Offset tapPosition) {
    // Threshold distance in pixels for detecting tap on path
    const double tapThreshold = 25.0;

    // Check each player's action path
    for (int i = 0; i < players.length; i++) {
      final player = players[i];

      // Skip players without assigned actions
      if (player.assignedAction == null) continue;

      // Get action definition
      final actionDef = actionVisuals[player.assignedAction];
      if (actionDef == null) continue;

      // Player position
      final playerPos = player.position;

      // Check each segment of the action path
      for (final segment in actionDef.segments) {
        // Apply flip if action is currently flipped
        final flipMultiplier = player.actionFlipped ? -1.0 : 1.0;

        // Calculate segment start and end positions
        final start = Offset(
          playerPos.x + (segment.start.x * 30 * flipMultiplier),
          playerPos.y + (segment.start.y * 30),
        );
        final end = Offset(
          playerPos.x + (segment.end.x * 30 * flipMultiplier),
          playerPos.y + (segment.end.y * 30),
        );

        // Calculate distance from tap to this line segment
        final distance = _distanceToLineSegment(tapPosition, start, end);

        // If tap is close enough to this segment, flip the action
        if (distance < tapThreshold) {
          setState(() {
            player.actionFlipped = !player.actionFlipped;
            // Update the appropriate data structure
            if (selectedFormationIndex != null) {
              if (selectedPlayIndex != null) {
                formations[selectedFormationIndex!].plays[selectedPlayIndex!].players =
                    players.map((p) => p.copy()).toList();
              } else {
                formations[selectedFormationIndex!].defaultPlayers =
                    players.map((p) => p.copy()).toList();
              }
            }
          });
          _saveFormations();
          return; // Only flip one action per double-click
        }
      }
    }
  }

  /// Calculate distance from a point to a line segment
  double _distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    // If the line segment is actually a point
    if (dx == 0 && dy == 0) {
      return (point - lineStart).distance;
    }

    // Calculate the parameter t that determines the closest point on the line segment
    final t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / (dx * dx + dy * dy);

    // Clamp t to [0, 1] to stay within the line segment
    final tClamped = t.clamp(0.0, 1.0);

    // Calculate the closest point on the line segment
    final closestPoint = Offset(
      lineStart.dx + tClamped * dx,
      lineStart.dy + tClamped * dy,
    );

    // Return distance from the tap point to the closest point
    return (point - closestPoint).distance;
  }

  void _showContextMenu(BuildContext context, Offset position, int playerIndex) {
    final List<PopupMenuEntry> menuItems = <PopupMenuEntry>[
      PopupMenuItem(
        enabled: false,
        child: Text(
          players[playerIndex].abbreviation,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
      PopupMenuDivider(),
      PopupMenuItem(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Assign Action'),
            Icon(Icons.arrow_right, size: 16),
          ],
        ),
        onTap: () {
          // Show submenu after a brief delay to allow first menu to close
          Future.delayed(Duration(milliseconds: 100), () {
            _showActionSubmenu(context, position, playerIndex);
          });
        },
      ),
      PopupMenuItem(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Substitute Position'),
            Icon(Icons.arrow_right, size: 16),
          ],
        ),
        onTap: () {
          // Show position substitution submenu after a brief delay
          Future.delayed(Duration(milliseconds: 100), () {
            _showPositionSubstitutionMenu(context, position, playerIndex);
          });
        },
      ),
    ];

    if (players[playerIndex].assignedAction != null) {
      menuItems.add(PopupMenuItem(
        child: Text('Clear Action'),
        onTap: () {
          setState(() {
            players[playerIndex].assignedAction = null;
            players[playerIndex].actionFlipped = false; // Reset flip state
            // Update the appropriate data structure
            if (selectedFormationIndex != null) {
              if (selectedPlayIndex != null) {
                // Update the selected play's players
                formations[selectedFormationIndex!].plays[selectedPlayIndex!].players =
                    players.map((p) => p.copy()).toList();
              } else {
                // Update formation's default players
                formations[selectedFormationIndex!].defaultPlayers =
                    players.map((p) => p.copy()).toList();
              }
            }
          });
          _saveFormations();
        },
      ));
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: menuItems,
    );
  }

  void _showActionSubmenu(BuildContext context, Offset position, int playerIndex) {
    // Show main categories: Routes and Blocks
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 150,
        position.dy,
        position.dx + 151,
        position.dy + 1,
      ),
      items: availableActionsByCategory.keys.map((mainCategory) {
        return PopupMenuItem<String>(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(mainCategory),
              Icon(Icons.arrow_right, size: 16),
            ],
          ),
          onTap: () {
            // Show subcategories for this main category after a brief delay
            Future.delayed(Duration(milliseconds: 100), () {
              _showSubcategoryMenu(context, position, playerIndex, mainCategory);
            });
          },
        );
      }).toList(),
    );
  }

  void _showSubcategoryMenu(BuildContext context, Offset position, int playerIndex, String mainCategory) {
    final subcategories = availableActionsByCategory[mainCategory] ?? {};

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 300,  // Further to the right for third-level menu
        position.dy,
        position.dx + 301,
        position.dy + 1,
      ),
      items: subcategories.keys.map((subcategory) {
        return PopupMenuItem<String>(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subcategory),
              Icon(Icons.arrow_right, size: 16),
            ],
          ),
          onTap: () {
            // Show actions for this subcategory after a brief delay
            Future.delayed(Duration(milliseconds: 100), () {
              _showActionsForSubcategory(context, position, playerIndex, mainCategory, subcategory);
            });
          },
        );
      }).toList(),
    );
  }

  void _showActionsForSubcategory(BuildContext context, Offset position, int playerIndex, String mainCategory, String subcategory) {
    final actions = availableActionsByCategory[mainCategory]?[subcategory] ?? [];

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 450,  // Further to the right for fourth-level menu
        position.dy,
        position.dx + 451,
        position.dy + 1,
      ),
      items: actions.map((action) {
        return PopupMenuItem<String>(
          child: Text(action),
          onTap: () {
            setState(() {
              players[playerIndex].assignedAction = action;
              // Update the appropriate data structure
              if (selectedFormationIndex != null) {
                if (selectedPlayIndex != null) {
                  // Update the selected play's players
                  formations[selectedFormationIndex!].plays[selectedPlayIndex!].players =
                      players.map((p) => p.copy()).toList();
                } else {
                  // Update formation's default players
                  formations[selectedFormationIndex!].defaultPlayers =
                      players.map((p) => p.copy()).toList();
                }
              }
            });
            _saveFormations();
          },
        );
      }).toList(),
    );
  }

  void _showPositionSubstitutionMenu(BuildContext context, Offset position, int playerIndex) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 150,
        position.dy,
        position.dx + 151,
        position.dy + 1,
      ),
      items: availablePositions.entries.map((entry) {
        return PopupMenuItem<String>(
          child: Text('${entry.key} - ${entry.value}'),
          onTap: () {
            setState(() {
              // Update player's position name and abbreviation
              players[playerIndex].name = entry.value;
              players[playerIndex].abbreviation = entry.key;
              // Update the appropriate data structure
              if (selectedFormationIndex != null) {
                if (selectedPlayIndex != null) {
                  // Update the selected play's players
                  formations[selectedFormationIndex!].plays[selectedPlayIndex!].players =
                      players.map((p) => p.copy()).toList();
                } else {
                  // Update formation's default players
                  formations[selectedFormationIndex!].defaultPlayers =
                      players.map((p) => p.copy()).toList();
                }
              }
            });
            _saveFormations();
          },
        );
      }).toList(),
    );
  }

  Widget _buildPlayerCircle(PlayerPosition player, bool isDragging, bool isSelected) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.yellow.shade700
            : Colors.blue.shade700,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isDragging ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ] : [],
      ),
      child: Center(
        child: Text(
          player.abbreviation,
          style: TextStyle(
            color: Colors.white,
            fontSize: 6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Build sliding toggle for Edit/Lock mode
  Widget _buildSlidingToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEditMode = !_isEditMode;
        });
      },
      child: Container(
        width: 140,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.green, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Sliding background
            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: _isEditMode ? 0 : 70,
              top: 0,
              child: Container(
                width: 70,
                height: 44,
                decoration: BoxDecoration(
                  color: _isEditMode ? Colors.orange.shade700 : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            // Labels
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: _isEditMode ? Colors.white : Colors.white54,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: _isEditMode ? Colors.white : Colors.white54,
                            fontSize: 12,
                            fontWeight: _isEditMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: !_isEditMode ? Colors.white : Colors.white54,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Lock',
                          style: TextStyle(
                            color: !_isEditMode ? Colors.white : Colors.white54,
                            fontSize: 12,
                            fontWeight: !_isEditMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build Player List view (Roster mode)
  Widget _buildPlayerList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isSelected = selectedPlayerIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedPlayerIndex = isSelected ? null : index;
            });
          },
          onSecondaryTapDown: (details) {
            _showContextMenu(context, details.globalPosition, index);
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.white24,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.abbreviation,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  player.name,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                if (player.assignedAction != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Action: ${player.assignedAction}',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build Formation List view (Formation mode)
  Widget _buildFormationList() {
    return Column(
      children: [
        // Formation list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: formations.length,
            itemBuilder: (context, index) {
              final formation = formations[index];
              final isSelected = selectedFormationIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedFormationIndex = index;
                    // Load formation's default players
                    players = formation.defaultPlayers.map((p) => p.copy()).toList();
                    selectedPlayIndex = null;
                  });
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_module,
                        color: isSelected ? Colors.green : Colors.white70,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formation.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (formation.plays.isNotEmpty) ...[
                              SizedBox(height: 2),
                              Text(
                                '${formation.plays.length} play${formation.plays.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: Colors.green.shade300,
                                  fontSize: 9,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Add Formation button
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.green, width: 1)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddFormationDialog,
              icon: Icon(Icons.add, size: 16),
              label: Text('Add Formation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show dialog to add a new formation
  void _showAddFormationDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Formation'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Formation Name',
              hintText: 'Enter formation name',
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() {
                  // Create new formation with default players
                  final newFormation = Formation(
                    name: value.trim(),
                    defaultPlayers: _getDefaultPlayers(),
                  );
                  formations.add(newFormation);
                  selectedFormationIndex = formations.length - 1;
                  players = newFormation.defaultPlayers.map((p) => p.copy()).toList();
                });
                _saveFormations();
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    // Create new formation with default players
                    final newFormation = Formation(
                      name: nameController.text.trim(),
                      defaultPlayers: _getDefaultPlayers(),
                    );
                    formations.add(newFormation);
                    selectedFormationIndex = formations.length - 1;
                    players = newFormation.defaultPlayers.map((p) => p.copy()).toList();
                  });
                  _saveFormations();
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Handle practice button click - spawn units on the field
  void _handlePractice() {
    if (widget.onPractice != null) {
      // Get play name if a play is selected
      String? playName;
      if (selectedFormationIndex != null && selectedPlayIndex != null) {
        playName = formations[selectedFormationIndex!].plays[selectedPlayIndex!].name;
      }
      // Pass current player positions and play name to the callback
      widget.onPractice!(players, playName);
      // Close the playbook modal
      widget.onClose();
    }
  }

  /// Show dialog to save current play
  void _showSavePlayDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Save Play'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Play Name',
              hintText: 'Enter play name',
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty && selectedFormationIndex != null) {
                setState(() {
                  // Create new play with current player positions
                  final newPlay = Play(
                    name: value.trim(),
                    players: players.map((p) => p.copy()).toList(),
                  );
                  formations[selectedFormationIndex!].plays.add(newPlay);
                  selectedPlayIndex = formations[selectedFormationIndex!].plays.length - 1;
                });
                _saveFormations();
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty && selectedFormationIndex != null) {
                  setState(() {
                    // Create new play with current player positions
                    final newPlay = Play(
                      name: nameController.text.trim(),
                      players: players.map((p) => p.copy()).toList(),
                    );
                    formations[selectedFormationIndex!].plays.add(newPlay);
                    selectedPlayIndex = formations[selectedFormationIndex!].plays.length - 1;
                  });
                  _saveFormations();
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Build play thumbnails carousel
  Widget _buildPlayThumbnailsCarousel() {
    if (selectedFormationIndex == null) return SizedBox.shrink();

    final formation = formations[selectedFormationIndex!];
    if (formation.plays.isEmpty) return SizedBox.shrink();

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border(
          bottom: BorderSide(color: Colors.green, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'PLAYS',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Thumbnails
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: formation.plays.length,
              itemBuilder: (context, index) {
                final play = formation.plays[index];
                final isSelected = selectedPlayIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPlayIndex = index;
                      // Load the play's player positions
                      players = play.players.map((p) => p.copy()).toList();
                    });
                  },
                  child: Container(
                    width: 100,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.shade800.withOpacity(0.5)
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Thumbnail field preview
                        Expanded(
                          child: _buildPlayThumbnail(play),
                        ),
                        // Play name
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                          ),
                          child: Text(
                            play.name,
                            style: TextStyle(
                              color: isSelected ? Colors.green : Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build miniature play thumbnail
  Widget _buildPlayThumbnail(Play play) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return CustomPaint(
          painter: PlayThumbnailPainter(
            players: play.players,
            actionVisuals: actionVisuals,
            width: width,
            height: height,
          ),
        );
      },
    );
  }
}

/// Custom Painter for play thumbnails - renders miniature version of main field
class PlayThumbnailPainter extends CustomPainter {
  final List<PlayerPosition> players;
  final Map<String, ActionVisualDefinition> actionVisuals;
  final double width;
  final double height;

  PlayThumbnailPainter({
    required this.players,
    required this.actionVisuals,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scaling factors (field is ~700x400 in main panel)
    final scaleX = size.width / 700.0;
    final scaleY = size.height / 400.0;
    final scale = (scaleX + scaleY) / 2; // Average scale for consistent sizing

    // Background
    final bgPaint = Paint()..color = Colors.green.shade800.withOpacity(0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 * scale;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // Yard lines - Field shows 30 yards (10 behind, 20 ahead of LOS)
    // Bottom = backfield (-10 to 0), Top = downfield (0 to +20)
    // Draw yard lines every 5 yards
    final yardLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.3 * scale;
    for (int i = 0; i < 7; i++) {
      final yardage = 20 - (i * 5); // 20, 15, 10, 5, 0, -5, -10
      // Convert to position (0 = top = +20, 1 = bottom = -10)
      final position = (20 - yardage) / 30; // 0 to 1 range
      final y = position * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), yardLinePaint);
    }

    // Line of scrimmage (2/3 down = 66.67%)
    final losPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..strokeWidth = 0.8 * scale;
    canvas.drawLine(
      Offset(0, size.height * 0.6667),
      Offset(size.width, size.height * 0.6667),
      losPaint,
    );

    // Draw action paths first (behind players)
    for (final player in players) {
      if (player.assignedAction != null && actionVisuals.containsKey(player.assignedAction)) {
        final actionDef = actionVisuals[player.assignedAction]!;
        final playerX = player.position.x * scaleX;
        final playerY = player.position.y * scaleY;

        final pathPaint = Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 * scale
          ..strokeCap = StrokeCap.round;

        // Draw each segment (matching main panel behavior, with optional flip)
        for (final segment in actionDef.segments) {
          // Apply horizontal flip if enabled
          final flipMultiplier = player.actionFlipped ? -1.0 : 1.0;

          final startX = playerX + (segment.start.x * 30 * scaleX * flipMultiplier);
          final startY = playerY + (segment.start.y * 30 * scaleY);
          final endX = playerX + (segment.end.x * 30 * scaleX * flipMultiplier);
          final endY = playerY + (segment.end.y * 30 * scaleY);

          final start = Offset(startX, startY);
          final end = Offset(endX, endY);

          // Draw the line
          canvas.drawLine(start, end, pathPaint);

          // Draw ending decoration based on type
          if (segment.type == ActionSegmentType.arrow) {
            _drawThumbnailArrowHead(canvas, pathPaint, start, end, scale);
          } else if (segment.type == ActionSegmentType.block) {
            _drawThumbnailBlockEnd(canvas, pathPaint, start, end, scale);
          }
        }
      }
    }

    // Draw player circles with labels
    for (final player in players) {
      final x = player.position.x * scaleX;
      final y = player.position.y * scaleY;
      final radius = 1.5 * scale;

      // Player circle
      final circlePaint = Paint()
        ..color = Colors.blue.shade700
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, circlePaint);

      // Player border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.2 * scale;
      canvas.drawCircle(Offset(x, y), radius, borderPaint);

      // Player label (abbreviation)
      final textPainter = TextPainter(
        text: TextSpan(
          text: player.abbreviation,
          style: TextStyle(
            color: Colors.white,
            fontSize: 1.25 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  /// Draw arrow head at the end of a route (thumbnail version)
  void _drawThumbnailArrowHead(Canvas canvas, Paint paint, Offset start, Offset end, double scale) {
    final arrowSize = 3.0 * scale;

    // Calculate direction vector
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    // Calculate arrow points
    final arrowPoint1 = Offset(
      end.dx - arrowSize * math.cos(angle - math.pi / 6),
      end.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    final arrowPoint2 = Offset(
      end.dx - arrowSize * math.cos(angle + math.pi / 6),
      end.dy - arrowSize * math.sin(angle + math.pi / 6),
    );

    // Draw arrow head
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  /// Draw perpendicular line at the end of a block (thumbnail version)
  void _drawThumbnailBlockEnd(Canvas canvas, Paint paint, Offset start, Offset end, double scale) {
    final blockWidth = 6.0 * scale;

    // Calculate direction vector
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    // Calculate perpendicular line points
    final perpAngle = angle + math.pi / 2;
    final blockStart = Offset(
      end.dx - blockWidth * math.cos(perpAngle),
      end.dy - blockWidth * math.sin(perpAngle),
    );
    final blockEnd = Offset(
      end.dx + blockWidth * math.cos(perpAngle),
      end.dy + blockWidth * math.sin(perpAngle),
    );

    // Draw perpendicular line
    canvas.drawLine(blockStart, blockEnd, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom Painter for drawing action paths on the field
class ActionPathPainter extends CustomPainter {
  final List<PlayerPosition> players;
  final Map<String, ActionVisualDefinition> actionVisuals;
  final double scale = 30.0; // Scale factor for converting normalized coords to pixels

  ActionPathPainter({
    required this.players,
    required this.actionVisuals,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw action path for each player that has an assigned action
    for (final player in players) {
      if (player.assignedAction == null) continue;

      final actionDef = actionVisuals[player.assignedAction];
      if (actionDef == null) continue;

      // Player position (center of circle)
      final playerPos = Offset(player.position.x, player.position.y);

      // Draw each segment (with optional horizontal flip)
      for (final segment in actionDef.segments) {
        // Apply horizontal flip if enabled
        final flipMultiplier = player.actionFlipped ? -1.0 : 1.0;

        final start = playerPos + Offset(
          segment.start.x * scale * flipMultiplier,
          segment.start.y * scale,
        );
        final end = playerPos + Offset(
          segment.end.x * scale * flipMultiplier,
          segment.end.y * scale,
        );

        // Draw the line
        canvas.drawLine(start, end, paint);

        // Draw ending decoration based on type
        if (segment.type == ActionSegmentType.arrow) {
          _drawArrowHead(canvas, paint, start, end);
        } else if (segment.type == ActionSegmentType.block) {
          _drawBlockEnd(canvas, paint, start, end);
        }
      }
    }
  }

  /// Draw arrow head at the end of a route
  void _drawArrowHead(Canvas canvas, Paint paint, Offset start, Offset end) {
    const arrowSize = 12.0;

    // Calculate direction vector
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    // Calculate arrow points
    final arrowPoint1 = Offset(
      end.dx - arrowSize * math.cos(angle - math.pi / 6),
      end.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    final arrowPoint2 = Offset(
      end.dx - arrowSize * math.cos(angle + math.pi / 6),
      end.dy - arrowSize * math.sin(angle + math.pi / 6),
    );

    // Draw arrow head
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  /// Draw perpendicular line at the end of a block
  void _drawBlockEnd(Canvas canvas, Paint paint, Offset start, Offset end) {
    const blockWidth = 25.0; // Half width of circle (50/2)

    // Calculate direction vector
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    // Calculate perpendicular line points
    final perpAngle = angle + math.pi / 2;
    final blockStart = Offset(
      end.dx - blockWidth * math.cos(perpAngle),
      end.dy - blockWidth * math.sin(perpAngle),
    );
    final blockEnd = Offset(
      end.dx + blockWidth * math.cos(perpAngle),
      end.dy + blockWidth * math.sin(perpAngle),
    );

    // Draw perpendicular line
    canvas.drawLine(blockStart, blockEnd, paint);
  }

  @override
  bool shouldRepaint(ActionPathPainter oldDelegate) {
    // Repaint if players or their actions have changed
    return true; // For simplicity, always repaint when setState is called
  }
}
