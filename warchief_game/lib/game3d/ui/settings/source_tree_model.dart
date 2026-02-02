import 'dart:convert';
import 'package:flutter/services.dart';

/// Model for source tree JSON data
class SourceTreeData {
  final String generatedAt;
  final String projectName;
  final String root;
  final SourceTreeTotals totals;
  final SourceTreeNode tree;

  SourceTreeData({
    required this.generatedAt,
    required this.projectName,
    required this.root,
    required this.totals,
    required this.tree,
  });

  factory SourceTreeData.fromJson(Map<String, dynamic> json) {
    return SourceTreeData(
      generatedAt: json['generated_at'] ?? '',
      projectName: json['project_name'] ?? 'Unknown',
      root: json['root'] ?? '',
      totals: SourceTreeTotals.fromJson(json['totals'] ?? {}),
      tree: SourceTreeNode.fromJson(json['tree'] ?? {}),
    );
  }

  /// Load source tree from assets
  static Future<SourceTreeData?> load() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/source-tree.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SourceTreeData.fromJson(json);
    } catch (e) {
      print('Failed to load source tree: $e');
      return null;
    }
  }
}

/// Totals from the source tree
class SourceTreeTotals {
  final int files;
  final int directories;
  final int lines;
  final int size;

  SourceTreeTotals({
    required this.files,
    required this.directories,
    required this.lines,
    required this.size,
  });

  factory SourceTreeTotals.fromJson(Map<String, dynamic> json) {
    return SourceTreeTotals(
      files: json['files'] ?? 0,
      directories: json['directories'] ?? 0,
      lines: json['lines'] ?? 0,
      size: json['size'] ?? 0,
    );
  }

  /// Format size as human-readable string
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format lines with thousands separator
  String get formattedLines {
    if (lines < 1000) return '$lines';
    return '${(lines / 1000).toStringAsFixed(1)}K';
  }
}

/// A node in the source tree (file or directory)
class SourceTreeNode {
  final String name;
  final String type;
  final String path;
  final int? size;
  final int? lines;
  final String? extension;
  final String? icon;
  final List<SourceTreeNode> children;

  SourceTreeNode({
    required this.name,
    required this.type,
    required this.path,
    this.size,
    this.lines,
    this.extension,
    this.icon,
    this.children = const [],
  });

  bool get isDirectory => type == 'directory';
  bool get isFile => type == 'file';

  factory SourceTreeNode.fromJson(Map<String, dynamic> json) {
    return SourceTreeNode(
      name: json['name'] ?? '',
      type: json['type'] ?? 'file',
      path: json['path'] ?? '',
      size: json['size'],
      lines: json['lines'],
      extension: json['extension'],
      icon: json['icon'],
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => SourceTreeNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get icon for file type
  String get displayIcon {
    if (icon != null) return icon!;
    if (isDirectory) return '\u{1F4C1}'; // folder
    return '\u{1F4C4}'; // page
  }

  /// Format size as human-readable string
  String get formattedSize {
    final s = size ?? 0;
    if (s < 1024) return '$s B';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(1)} KB';
    return '${(s / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
