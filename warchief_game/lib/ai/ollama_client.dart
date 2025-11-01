import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Ollama HTTP client for LLM-based AI decision-making
///
/// Communicates with local Ollama server (http://localhost:11434)
/// to generate AI decisions for allies and monster entities.
class OllamaClient {
  static const String baseUrl = 'http://localhost:11434';
  static const Duration timeout = Duration(seconds: 5);

  /// Generate a response from Ollama
  ///
  /// [model] - The Ollama model to use (e.g., 'llama2', 'mistral')
  /// [prompt] - The prompt describing the game state and decision options
  /// [temperature] - Creativity level (0.0 = deterministic, 1.0 = creative)
  ///
  /// Returns the model's text response, or a fallback command if Ollama fails.
  Future<String> generate({
    required String model,
    required String prompt,
    double temperature = 0.7,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'model': model,
              'prompt': prompt,
              'stream': false,
              'temperature': temperature,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseText = data['response'] as String;
        debugPrint('Ollama response ($model): $responseText');
        return responseText.trim();
      } else {
        debugPrint('Ollama error: HTTP ${response.statusCode}');
        return 'HOLD_POSITION'; // Fallback
      }
    } catch (e) {
      debugPrint('Ollama connection error: $e');
      return 'HOLD_POSITION'; // Fallback when Ollama unavailable
    }
  }

  /// Check if Ollama server is available
  ///
  /// Returns true if the Ollama server responds, false otherwise.
  Future<bool> isAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
