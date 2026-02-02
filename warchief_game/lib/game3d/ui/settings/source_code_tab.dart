import 'package:flutter/material.dart';
import 'source_tree_model.dart';

/// Source Code tab showing project statistics and directory tree
class SourceCodeTab extends StatefulWidget {
  final SourceTreeData sourceTree;

  const SourceCodeTab({
    Key? key,
    required this.sourceTree,
  }) : super(key: key);

  @override
  State<SourceCodeTab> createState() => _SourceCodeTabState();
}

class _SourceCodeTabState extends State<SourceCodeTab> {
  final Set<String> _expandedPaths = {};

  @override
  void initState() {
    super.initState();
    // Expand root and first level by default
    _expandedPaths.add(widget.sourceTree.tree.path);
    for (final child in widget.sourceTree.tree.children) {
      if (child.isDirectory) {
        _expandedPaths.add(child.path);
      }
    }
  }

  void _toggleExpanded(String path) {
    setState(() {
      if (_expandedPaths.contains(path)) {
        _expandedPaths.remove(path);
      } else {
        _expandedPaths.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatistics(),
        Expanded(
          child: _buildTreeView(),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final totals = widget.sourceTree.totals;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252542),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('${totals.files}', 'Files'),
          _buildStatDivider(),
          _buildStatItem('${totals.directories}', 'Dirs'),
          _buildStatDivider(),
          _buildStatItem(totals.formattedLines, 'Lines'),
          _buildStatDivider(),
          _buildStatItem(totals.formattedSize, 'Size'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF4cc9f0),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildTreeView() {
    return Container(
      color: const Color(0xFF1a1a2e),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildTreeNodes(widget.sourceTree.tree.children, 0),
        ),
      ),
    );
  }

  List<Widget> _buildTreeNodes(List<SourceTreeNode> nodes, int depth) {
    final widgets = <Widget>[];

    for (final node in nodes) {
      widgets.add(_buildTreeNode(node, depth));

      if (node.isDirectory && _expandedPaths.contains(node.path)) {
        widgets.addAll(_buildTreeNodes(node.children, depth + 1));
      }
    }

    return widgets;
  }

  Widget _buildTreeNode(SourceTreeNode node, int depth) {
    final isExpanded = _expandedPaths.contains(node.path);
    final indent = 20.0 * depth;

    return InkWell(
      onTap: node.isDirectory ? () => _toggleExpanded(node.path) : null,
      hoverColor: Colors.white.withValues(alpha: 0.05),
      child: Container(
        padding: EdgeInsets.only(
          left: indent + 8,
          right: 8,
          top: 4,
          bottom: 4,
        ),
        child: Row(
          children: [
            // Expand/collapse indicator for directories
            if (node.isDirectory)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.white54,
                  size: 16,
                ),
              )
            else
              const SizedBox(width: 20),

            // File/folder icon
            Text(
              node.displayIcon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),

            // Name
            Expanded(
              child: Text(
                node.name,
                style: TextStyle(
                  color: node.isDirectory ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight:
                      node.isDirectory ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Line count for files
            if (node.isFile && node.lines != null)
              Text(
                '${node.lines} lines',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),

            // Directory child count
            if (node.isDirectory)
              Text(
                '${node.children.length} items',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Color for file extensions
Color _getExtensionColor(String? extension) {
  switch (extension) {
    case '.dart':
      return const Color(0xFF00B4AB);
    case '.py':
      return const Color(0xFF3776AB);
    case '.js':
    case '.ts':
      return const Color(0xFFF7DF1E);
    case '.html':
      return const Color(0xFFE34F26);
    case '.css':
    case '.scss':
      return const Color(0xFF1572B6);
    case '.json':
    case '.yaml':
    case '.yml':
      return const Color(0xFFA0A0B0);
    case '.md':
      return const Color(0xFF083FA1);
    case '.sh':
      return const Color(0xFF4EAA25);
    default:
      return Colors.white70;
  }
}
