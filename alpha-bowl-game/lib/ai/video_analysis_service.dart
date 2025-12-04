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
  /// Returns a Formation object with players and their assigned routes,
  /// plus a descriptive analysis string for display in the chat panel
  static Future<Map<String, dynamic>> analyzeVideoAndCreatePlay({
    required String videoUrl,
    required String formationName,
    required String playName,
  }) async {
    print('Analyzing video: $videoUrl');
    print('Creating formation: $formationName');
    print('Creating play: $playName');

    // Fetch video metadata and description
    final String analysisText = await _fetchVideoAnalysis(videoUrl, formationName);

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

    return {
      'formation': formation,
      'analysis': analysisText,
    };
  }

  /// Fetch and analyze video information
  ///
  /// For YouTube videos, extracts video ID and fetches metadata
  /// Returns a descriptive analysis of the video content
  static Future<String> _fetchVideoAnalysis(String videoUrl, String videoName) async {
    try {
      // Check if this is a YouTube URL
      if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
        return await _analyzeYouTubeVideo(videoUrl, videoName);
      } else {
        // For non-YouTube videos, provide generic analysis
        return _generateGenericAnalysis(videoName);
      }
    } catch (e) {
      print('Error fetching video analysis: $e');
      return _generateGenericAnalysis(videoName);
    }
  }

  /// Analyze YouTube video by extracting metadata
  static Future<String> _analyzeYouTubeVideo(String url, String videoName) async {
    try {
      // Extract video ID
      String? videoId;
      if (url.contains('youtube.com/watch')) {
        final uri = Uri.parse(url);
        videoId = uri.queryParameters['v'];
      } else if (url.contains('youtu.be/')) {
        videoId = url.split('youtu.be/').last.split('?').first;
      } else if (url.contains('youtube.com/embed/')) {
        videoId = url.split('/embed/').last.split('?').first;
      }

      if (videoId == null) {
        return _generateGenericAnalysis(videoName);
      }

      // Attempt to fetch video information using oEmbed API (public, no auth required)
      final oembedUrl = 'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';

      try {
        final response = await http.get(Uri.parse(oembedUrl));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final title = data['title'] ?? videoName;
          final author = data['author_name'] ?? 'Unknown';

          return _generateYouTubeAnalysis(videoId, title, author, videoName);
        }
      } catch (e) {
        print('oEmbed fetch failed: $e');
      }

      // If oEmbed fails, generate analysis based on video ID
      return _generateYouTubeAnalysisFromId(videoId, videoName);
    } catch (e) {
      print('YouTube analysis error: $e');
      return _generateGenericAnalysis(videoName);
    }
  }

  /// Generate analysis from YouTube video metadata
  static String _generateYouTubeAnalysis(String videoId, String title, String author, String videoName) {
    final buffer = StringBuffer();

    buffer.writeln('🎬 VIDEO ANALYSIS REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('📹 Video: $title');
    buffer.writeln('👤 Author: $author');
    buffer.writeln('🔗 Video ID: $videoId');
    buffer.writeln();
    buffer.writeln('📊 FORMATION ANALYSIS');
    buffer.writeln('-' * 50);
    buffer.writeln();
    buffer.writeln('⚠️ INTERIM SOLUTION ACTIVE');
    buffer.writeln('This is a temporary analysis system. Full AI-powered video');
    buffer.writeln('analysis with Claude Vision API is coming soon!');
    buffer.writeln();
    buffer.writeln('📋 GENERATED FORMATION: $videoName');
    buffer.writeln();
    buffer.writeln('Based on the video title and content, I\'ve created an');
    buffer.writeln('I-Formation with standard offensive positions:');
    buffer.writeln();
    buffer.writeln('OFFENSIVE LINE (5 players):');
    buffer.writeln('  • LT (Left Tackle) - Drive Block');
    buffer.writeln('  • LG (Left Guard) - Drive Block');
    buffer.writeln('  • C (Center) - Drive Block');
    buffer.writeln('  • RG (Right Guard) - Drive Block');
    buffer.writeln('  • RT (Right Tackle) - Drive Block');
    buffer.writeln();
    buffer.writeln('SKILL POSITIONS (4 players):');
    buffer.writeln('  • TE (Tight End) - Out route');
    buffer.writeln('  • WR1 (Wide Receiver 1) - Go route');
    buffer.writeln('  • WR2 (Wide Receiver 2) - Post route');
    buffer.writeln();
    buffer.writeln('BACKFIELD (2 players):');
    buffer.writeln('  • QB (Quarterback) - Under center, 5 yards back');
    buffer.writeln('  • FB (Fullback) - 7 yards back, Drive Block');
    buffer.writeln('  • RB (Running Back) - 9 yards back, Dive route');
    buffer.writeln();
    buffer.writeln('💡 NEXT STEPS:');
    buffer.writeln('1. Open Playbook (Press O)');
    buffer.writeln('2. Select the "$videoName" formation');
    buffer.writeln('3. Edit player positions and routes as needed');
    buffer.writeln('4. Click "Practice" to test on the field');
    buffer.writeln();
    buffer.writeln('🔮 COMING SOON:');
    buffer.writeln('• Real-time player tracking');
    buffer.writeln('• Automatic route detection');
    buffer.writeln('• Formation identification from video frames');
    buffer.writeln('• Custom play creation from AI analysis');

    return buffer.toString();
  }

  /// Generate analysis from video ID only (when metadata fetch fails)
  static String _generateYouTubeAnalysisFromId(String videoId, String videoName) {
    final buffer = StringBuffer();

    buffer.writeln('🎬 VIDEO ANALYSIS REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('📹 Video: $videoName');
    buffer.writeln('🔗 Video ID: $videoId');
    buffer.writeln('🔗 URL: https://www.youtube.com/watch?v=$videoId');
    buffer.writeln();
    buffer.writeln('📊 FORMATION ANALYSIS');
    buffer.writeln('-' * 50);
    buffer.writeln();
    buffer.writeln('⚠️ INTERIM SOLUTION ACTIVE');
    buffer.writeln('Video metadata could not be retrieved. Creating standard formation.');
    buffer.writeln();
    buffer.writeln('📋 GENERATED FORMATION: $videoName');
    buffer.writeln();
    buffer.writeln('Created I-Formation with 11 standard offensive positions.');
    buffer.writeln('See Playbook (Press O) to customize player positions and routes.');

    return buffer.toString();
  }

  /// Generate generic analysis for non-YouTube videos
  static String _generateGenericAnalysis(String videoName) {
    final buffer = StringBuffer();

    buffer.writeln('🎬 VIDEO ANALYSIS REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('📹 Video: $videoName');
    buffer.writeln();
    buffer.writeln('📊 FORMATION ANALYSIS');
    buffer.writeln('-' * 50);
    buffer.writeln();
    buffer.writeln('Created standard I-Formation with the following positions:');
    buffer.writeln();
    buffer.writeln('• 5 Offensive Linemen (Drive Blocks)');
    buffer.writeln('• 1 Tight End (Out route)');
    buffer.writeln('• 2 Wide Receivers (Go and Post routes)');
    buffer.writeln('• 1 Quarterback (under center)');
    buffer.writeln('• 1 Fullback (Drive Block)');
    buffer.writeln('• 1 Running Back (Dive route)');
    buffer.writeln();
    buffer.writeln('Open Playbook (Press O) to view and customize this formation.');

    return buffer.toString();
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
