import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/macro.dart';

/// CRUD manager for saved macros with per-character persistence.
///
/// Each character (Warchief = index 0, allies = index 1+) has its own
/// list of saved macros stored via SharedPreferences.
class MacroManager extends ChangeNotifier {
  /// Character index → list of saved macros
  final Map<int, List<Macro>> _macrosByCharacter = {};

  /// Get all macros saved for a specific character.
  List<Macro> getMacrosForCharacter(int index) {
    return _macrosByCharacter[index] ?? [];
  }

  /// Save (add or update) a macro for a character.
  ///
  /// If a macro with the same [Macro.id] already exists, it is replaced.
  void saveMacro(int characterIndex, Macro macro) {
    final macros = _macrosByCharacter.putIfAbsent(characterIndex, () => []);

    // Replace existing macro with same ID, or add new
    final existingIndex = macros.indexWhere((m) => m.id == macro.id);
    if (existingIndex >= 0) {
      macros[existingIndex] = macro;
    } else {
      macros.add(macro);
    }

    _persistMacros();
    notifyListeners();
    print('[MacroManager] Saved macro "${macro.name}" for character $characterIndex');
  }

  /// Delete a macro by ID for a specific character.
  void deleteMacro(int characterIndex, String macroId) {
    final macros = _macrosByCharacter[characterIndex];
    if (macros == null) return;

    macros.removeWhere((m) => m.id == macroId);
    _persistMacros();
    notifyListeners();
    print('[MacroManager] Deleted macro $macroId for character $characterIndex');
  }

  /// Find a macro by ID across all characters.
  Macro? getMacroById(String id) {
    for (final macros in _macrosByCharacter.values) {
      for (final macro in macros) {
        if (macro.id == id) return macro;
      }
    }
    return null;
  }

  /// Load all macros from SharedPreferences.
  Future<void> loadMacros() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Scan for all macro keys (macros_char_0, macros_char_1, ...)
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (!key.startsWith('macros_char_')) continue;

        final charIndex = int.tryParse(key.replaceFirst('macros_char_', ''));
        if (charIndex == null) continue;

        final jsonString = prefs.getString(key);
        if (jsonString == null || jsonString.isEmpty) continue;

        try {
          final list = jsonDecode(jsonString) as List<dynamic>;
          final macros = list
              .map((e) => Macro.fromJson(e as Map<String, dynamic>))
              .toList();
          _macrosByCharacter[charIndex] = macros;
        } catch (e) {
          print('[MacroManager] Error parsing macros for key $key: $e');
        }
      }

      print('[MacroManager] Loaded macros for ${_macrosByCharacter.length} characters');
      notifyListeners();
    } catch (e) {
      print('[MacroManager] Error loading macros: $e');
    }
  }

  /// Persist all macros to SharedPreferences.
  Future<void> _persistMacros() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final entry in _macrosByCharacter.entries) {
        final key = 'macros_char_${entry.key}';
        final jsonList = entry.value.map((m) => m.toJson()).toList();
        await prefs.setString(key, jsonEncode(jsonList));
      }
    } catch (e) {
      print('[MacroManager] Error saving macros: $e');
    }
  }

  /// Total macro count across all characters.
  int get totalMacroCount =>
      _macrosByCharacter.values.fold(0, (sum, list) => sum + list.length);
}

/// Global macro manager instance (initialized in game3d_widget.dart)
MacroManager? globalMacroManager;
