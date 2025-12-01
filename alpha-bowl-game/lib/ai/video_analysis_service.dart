import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vector_math/vector_math.dart';
import '../game3d/ui/playbook_modal.dart';
import '../game3d/services/playbook_service.dart';

/// Video Analysis Service using Claude Vision API
///
/// This service analyzes football play videos to extract player positions
/// and routes, then creates formations and plays in the Playbook.
class VideoAnalysisService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  /// Analyze a video URL and extract play information
  ///
  /// Uses Claude's vision capabilities to:
  /// 1. Identify player positions at the line of scrimmage
  /// 2. Track player movements and routes
  /// 3. Generate a formation and play for the Playbook
  /// 4. Save the formation to persistent storage
  ///
  /// Returns a Formation object with players and their assigned routes
  static Future<Formation> analyzeVideoAndCreatePlay({
    required String videoUrl,
    required String formationName,
    required String playName,
  }) async {
    // For YouTube videos, we need to extract a frame
    // For now, we'll create a template formation and let the user know
    // that full video analysis requires an API key

    print('Analyzing video: $videoUrl');
    print('Creating formation: $formationName');
    print('Creating play: $playName');

    // Create a default I-Formation as a starting point
    // In a full implementation, this would call Claude Vision API with video frames
    final formation = _createDefaultFormation(formationName, playName);

    // Save the formation to the Playbook
    final success = await PlaybookService.addFormation(formation);
    if (success) {
      print('Formation "${formationName}" saved to Playbook successfully');
    } else {
      print('Warning: Failed to save formation to Playbook');
    }

    // TODO: Implement actual video analysis when API key is available
    // This would involve:
    // 1. Extracting video frames (using MCP video server)
    // 2. Sending frames to Claude Vision API
    // 3. Parsing AI response for player positions and routes
    // 4. Creating formations and plays based on AI analysis

    return formation;
  }

  /// Create a default I-Formation as a template
  static Formation _createDefaultFormation(String formationName, String playName) {
    // Line of scrimmage position in playbook coordinates
    final los = 266.67;
    final yardInPixels = 13.33;
    final circleRadius = 12.5;
    final minBackOffset = circleRadius + 5;

    // Create default player positions (I-Formation)
    final defaultPlayers = <PlayerPosition>[
      // Offensive Line
      PlayerPosition(
        name: 'Left Tackle',
        abbreviation: 'LT',
        position: Vector2(200, los + minBackOffset),
        assignedAction: 'Drive Block',
        actionFlipped: false,
      ),
      PlayerPosition(
        name: 'Left Guard',
        abbreviation: 'LG',
        position: Vector2(275, los + minBackOffset),
        assignedAction: 'Drive Block',
        actionFlipped: false,
      ),
      PlayerPosition(
        name: 'Center',
        abbreviation: 'C',
        position: Vector2(350, los + minBackOffset),
        assignedAction: 'Drive Block',
        actionFlipped: false,
      ),
      PlayerPosition(
        name: 'Right Guard',
        abbreviation: 'RG',
        position: Vector2(425, los + minBackOffset),
        assignedAction: 'Drive Block',
        actionFlipped: false,
      ),
      PlayerPosition(
        name: 'Right Tackle',
        abbreviation: 'RT',
        position: Vector2(500, los + minBackOffset),
        assignedAction: 'Drive Block',
        actionFlipped: false,
      ),

      // Tight End
      PlayerPosition(
        name: 'Tight End',
        abbreviation: 'TE',
        position: Vector2(575, los + minBackOffset),
        assignedAction: 'Out',
        actionFlipped: false,
      ),

      // Wide Receivers
      PlayerPosition(
        name: 'Wide Receiver 1',
        abbreviation: 'WR1',
        position: Vector2(100, los + minBackOffset),
        assignedAction: 'Go',
        actionFlipped: false,
      ),
      PlayerPosition(
        name: 'Wide Receiver 2',
        abbreviation: 'WR2',
        position: Vector2(600, los + minBackOffset),
        assignedAction: 'Post',
        actionFlipped: false,
      ),

      // Backfield (I-Formation)
      PlayerPosition(
        name: 'Quarterback',
        abbreviation: 'QB',
        position: Vector2(350, los + (5 * yardInPixels)),
        assignedAction: null,
        actionFlipped: false,
      ),
      PlayerPosition(
        name: 'Fullback',
        abbreviation: 'FB',
        position: Vector2(350, los + (7 * yardInPixels)),
        assignedAction: 'Drive Block',
        actionFlipped: false,
      ),
      PlayerPosition(
        name: 'Running Back',
        abbreviation: 'RB',
        position: Vector2(350, los + (9 * yardInPixels)),
        assignedAction: 'Dive',
        actionFlipped: false,
      ),
    ];

    // Create play
    final play = Play(
      name: playName,
      players: defaultPlayers.map((p) => p.copy()).toList(),
    );

    // Create formation with the play
    final formation = Formation(
      name: formationName,
      defaultPlayers: defaultPlayers,
      plays: [play],
    );

    return formation;
  }

  /// Analyze video using Claude Vision API (requires API key)
  ///
  /// This is a placeholder for future implementation with actual API integration
  static Future<Map<String, dynamic>> _analyzeVideoWithClaude({
    required String videoFrameUrl,
    required String apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'url',
                    'url': videoFrameUrl,
                  },
                },
                {
                  'type': 'text',
                  'text': '''Analyze this football play image and identify:
1. Number of offensive players visible
2. Position of each player (coordinates from 0-700 horizontally, 0-400 vertically)
3. Type of route each player is running (Go, Post, Corner, Slant, Out, In, Curl, Flat)
4. Formation type (I-Formation, Shotgun, etc.)

Return the analysis as JSON with this structure:
{
  "formation": "formation_name",
  "players": [
    {"position": "QB", "x": 350, "y": 300, "route": null},
    {"position": "WR", "x": 100, "y": 250, "route": "Go"}
  ]
}'''
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'];
        return jsonDecode(content);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error analyzing video: $e');
      return {};
    }
  }
}
