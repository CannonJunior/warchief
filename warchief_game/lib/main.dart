import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game3d/game3d_widget.dart';
import 'game3d/ui/settings/settings_panel.dart';

/// Entry point for the Warchief game
///
/// Initializes Flutter, sets up Riverpod state management,
/// and launches the game.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: WarchiefApp(),
    ),
  );
}

/// Main application widget
class WarchiefApp extends StatelessWidget {
  const WarchiefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warchief - 3D Isometric Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const GameScreen(),
    );
  }
}

/// Game screen that displays the 3D WebGL game
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showSettingsPanel = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make background transparent for canvas
      body: Stack(
        children: [
          // 3D WebGL Game
          Game3D(),

          // Version info and settings button (top-right corner)
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Settings button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showSettingsPanel = !_showSettingsPanel;
                      });
                      debugPrint('Settings button pressed: $_showSettingsPanel');
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _showSettingsPanel
                            ? const Color(0xFF4cc9f0).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: _showSettingsPanel
                            ? const Color(0xFF4cc9f0)
                            : Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Version info
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Warchief v0.2.0 - 3D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'WebGL Renderer',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Settings Panel
          if (_showSettingsPanel)
            SettingsPanel(
              onClose: () {
                setState(() {
                  _showSettingsPanel = false;
                });
              },
            ),
        ],
      ),
    );
  }
}
