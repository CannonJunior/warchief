import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ollama HTTP client for LLM-based AI decision-making
///
/// Communicates with local Ollama server (http://localhost:11434 by default).
/// The endpoint is configurable at runtime and persisted to SharedPreferences
/// under the key 'ollama_endpoint'.
class OllamaClient {
  // Reason: mutable static so the AI tab can update the endpoint at runtime
  // without recreating every subsystem that holds an OllamaClient instance.
  static String baseUrl = 'http://localhost:11434';
  static const Duration timeout = Duration(seconds: 5);

  /// Load the saved endpoint from SharedPreferences (call once at startup).
  static Future<void> loadSavedEndpoint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('ollama_endpoint');
      if (saved != null && saved.isNotEmpty) baseUrl = saved;
    } catch (_) {}
  }

  /// Save the current endpoint to SharedPreferences.
  static Future<void> saveEndpoint(String url) async {
    try {
      baseUrl = url;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ollama_endpoint', url);
    } catch (_) {}
  }

  /// Return the names of all models currently available in the Ollama server.
  Future<List<String>> listModels() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List<dynamic>? ?? [];
        return models
            .map((m) => (m as Map<String, dynamic>)['name'] as String)
            .toList();
      }
    } catch (_) {}
    return [];
  }

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

  /// Multi-turn chat using Ollama's /api/chat endpoint.
  ///
  /// Supports a system message and full conversation history.
  /// Uses a long timeout and large [numCtx] because the Spirit embeds all
  /// project docs (~40 K tokens) in the system prompt.
  ///
  /// Returns the assistant's reply, or an empty string on failure.
  Future<String> chat({
    required String model,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    int numCtx = 65536,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'model': model,
              'messages': messages,
              'stream': false,
              'options': {
                'temperature': temperature,
                'num_ctx': numCtx,
              },
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = (data['message']['content'] as String).trim();
        debugPrint('Ollama chat ($model): ${content.substring(0, content.length.clamp(0, 80))}…');
        return content;
      } else {
        final errBody = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
        debugPrint('Ollama chat error: HTTP ${response.statusCode} — $errBody');
        // Reason: return the error text so callers can surface it in the game UI
        // rather than silently collapsing to a generic fallback.
        return 'HTTP ${response.statusCode}: $errBody';
      }
    } catch (e) {
      debugPrint('Ollama chat connection error: $e');
      return '';
    }
  }

  /// Streaming multi-turn chat using Ollama's /api/chat endpoint.
  ///
  /// Yields content tokens as they arrive so callers can update the UI
  /// incrementally. Eliminates the 120-second non-streaming wait on
  /// slow CPU-only hardware.
  ///
  /// Use [numCtx] to override the context window size. Default 16384 is
  /// sufficient for the 5-doc knowledge base (~10 K tokens overhead).
  Stream<String> chatStream({
    required String model,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    int numCtx = 16384,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/api/chat'))
        ..headers['Content-Type'] = 'application/json'
        ..body = json.encode({
          'model': model,
          'messages': messages,
          'stream': true,
          'options': {'temperature': temperature, 'num_ctx': numCtx},
        });

      final streamed = await client.send(request);
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        debugPrint('Ollama chatStream error: HTTP ${streamed.statusCode} — $body');
        return;
      }

      // Ollama streams NDJSON: one JSON object per line.
      final lines = streamed.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.isEmpty) continue;
        try {
          final data = json.decode(line) as Map<String, dynamic>;
          final chunk = (data['message']?['content'] as String?) ?? '';
          if (chunk.isNotEmpty) yield chunk;
          if (data['done'] == true) break;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Ollama chatStream connection error: $e');
    } finally {
      client.close();
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
