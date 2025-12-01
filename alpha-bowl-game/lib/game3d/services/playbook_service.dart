import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/playbook_modal.dart';

/// Service for managing Playbook formations in persistent storage
///
/// This service provides methods to add, load, and save formations
/// to SharedPreferences, allowing external systems (like video analysis)
/// to programmatically create formations in the Playbook.
class PlaybookService {
  static const String _storageKey = 'playbook_formations';

  /// Load formations from persistent storage
  static Future<List<Formation>> loadFormations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formationsString = prefs.getString(_storageKey);

      if (formationsString != null) {
        final List<dynamic> formationsJson = jsonDecode(formationsString);
        return formationsJson
            .map((f) => Formation.fromJson(f as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error loading formations: $e');
      return [];
    }
  }

  /// Save formations to persistent storage
  static Future<void> saveFormations(List<Formation> formations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formationsJson = formations.map((f) => f.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(formationsJson));
    } catch (e) {
      print('Error saving formations: $e');
    }
  }

  /// Add a new formation to the Playbook
  ///
  /// This method loads existing formations, adds the new one,
  /// and saves them back to persistent storage.
  ///
  /// Returns true if successful, false otherwise.
  static Future<bool> addFormation(Formation formation) async {
    try {
      // Load existing formations
      final formations = await loadFormations();

      // Check if a formation with this name already exists
      final existingIndex = formations.indexWhere((f) => f.name == formation.name);

      if (existingIndex != -1) {
        // Replace existing formation
        formations[existingIndex] = formation;
        print('Replaced existing formation: ${formation.name}');
      } else {
        // Add new formation
        formations.add(formation);
        print('Added new formation: ${formation.name}');
      }

      // Save updated formations
      await saveFormations(formations);

      return true;
    } catch (e) {
      print('Error adding formation: $e');
      return false;
    }
  }

  /// Remove a formation by name
  static Future<bool> removeFormation(String formationName) async {
    try {
      final formations = await loadFormations();
      formations.removeWhere((f) => f.name == formationName);
      await saveFormations(formations);
      return true;
    } catch (e) {
      print('Error removing formation: $e');
      return false;
    }
  }

  /// Get a formation by name
  static Future<Formation?> getFormation(String formationName) async {
    try {
      final formations = await loadFormations();
      final index = formations.indexWhere((f) => f.name == formationName);
      return index != -1 ? formations[index] : null;
    } catch (e) {
      print('Error getting formation: $e');
      return null;
    }
  }
}
