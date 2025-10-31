import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game3d/game3d_widget.dart';

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
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make background transparent for canvas
      body: Stack(
        children: [
          // 3D WebGL Game
          Game3D(),

          // Version info (top-right corner)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
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
          ),

          // Settings button (top-right corner, below version)
          Positioned(
            top: 70,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // TODO: Open settings screen
                debugPrint('Settings button pressed');
              },
            ),
          ),
        ],
      ),
    );
  }
}
