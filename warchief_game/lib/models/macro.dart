import 'dart:convert';

/// The type of action a macro step performs.
enum MacroActionType {
  ability,     // Cast an ability by name
  wait,        // Wait for a specified duration
  consumable,  // Use a consumable item
  racial,      // Use a racial ability
  combined,    // Combined/simultaneous action (future)
}

/// One step in a macro sequence.
///
/// Each step defines an action to perform, with optional delay and
/// conditional execution. When [delay] is 0, the step executes on
/// the next GCD. When [condition] is null, the step is unconditional.
class MacroStep {
  final MacroActionType actionType;
  final String actionName;  // Ability name, item name, or empty for wait
  final double delay;       // Extra wait after previous step (seconds), 0 = next GCD
  final String? condition;  // 'has_mana', 'target_exists', 'health_above_50', null = unconditional

  const MacroStep({
    required this.actionType,
    required this.actionName,
    this.delay = 0.0,
    this.condition,
  });

  /// Create from JSON map.
  factory MacroStep.fromJson(Map<String, dynamic> json) {
    return MacroStep(
      actionType: MacroActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => MacroActionType.ability,
      ),
      actionName: json['actionName'] as String? ?? '',
      delay: (json['delay'] as num?)?.toDouble() ?? 0.0,
      condition: json['condition'] as String?,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType.name,
      'actionName': actionName,
      'delay': delay,
      if (condition != null) 'condition': condition,
    };
  }

  @override
  String toString() =>
      'MacroStep($actionType: $actionName, delay: $delay, cond: $condition)';
}

/// A named, saveable macro — ordered list of steps, optionally looping.
///
/// Macros are created by players and saved per-character. They define
/// a sequence of ability casts, waits, and conditions that the macro
/// engine executes automatically.
class Macro {
  final String id;            // UUID
  final String name;
  final List<MacroStep> steps;
  final bool loop;            // Repeat when all steps complete?
  final int? loopCount;       // null = infinite, N = stop after N loops

  const Macro({
    required this.id,
    required this.name,
    required this.steps,
    this.loop = false,
    this.loopCount,
  });

  /// Create from JSON map.
  factory Macro.fromJson(Map<String, dynamic> json) {
    return Macro(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Macro',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => MacroStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      loop: json['loop'] as bool? ?? false,
      loopCount: json['loopCount'] as int?,
    );
  }

  /// Create from JSON string.
  factory Macro.fromJsonString(String jsonString) {
    return Macro.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'steps': steps.map((s) => s.toJson()).toList(),
      'loop': loop,
      if (loopCount != null) 'loopCount': loopCount,
    };
  }

  /// Convert to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Number of ability steps (excluding waits).
  int get abilityStepCount =>
      steps.where((s) => s.actionType != MacroActionType.wait).length;

  /// Total estimated duration (delays + GCD estimates).
  double estimatedDuration(double gcdBase) {
    double total = 0.0;
    for (final step in steps) {
      if (step.actionType == MacroActionType.wait) {
        total += step.delay;
      } else {
        total += step.delay > 0 ? step.delay : gcdBase;
      }
    }
    return total;
  }

  @override
  String toString() =>
      'Macro($name, ${steps.length} steps, loop: $loop)';
}
